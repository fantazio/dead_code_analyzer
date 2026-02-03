(***************************************************************************)
(*                                                                         *)
(*   Copyright (c) 2014-2025 LexiFi SAS. All rights reserved.              *)
(*                                                                         *)
(*   This source code is licensed under the MIT License                    *)
(*   found in the LICENSE file at the root of this source tree             *)
(*                                                                         *)
(***************************************************************************)

type 'threshold section =
  | Off
  | On
  | Threshold of 'threshold threshold_section

and 'threshold threshold_section =
  { threshold: 'threshold
  ; call_sites: bool
  }

let is_activated = function
  | Off -> false
  | _ -> true

let has_activated l = List.exists is_activated l

let call_sites_activated = function
  | Threshold {call_sites; _} -> call_sites
  | _ -> false

type opt_threshold =
  | Percent of float
  | Both of (int * float)

type opt_section = opt_threshold section

let opta = ref Off
let optn = ref Off

let update_opt opt = function
  | "all" -> opt := On
  | "nothing" -> opt := Off
  | arg ->
      let raise_bad_arg msg =
        (* TODO: improve error reporting *)
        raise (Arg.Bad ("-Ox: " ^ msg))
      in
      let call_sites, arg =
        if String.starts_with ~prefix:"calls" arg then
          let arg = String.sub arg 6 (String.length arg - 6) in
          (true, arg)
        else (false, arg)
      in
      let check_percentage p =
        if p > 1. || p < 0. then
          raise_bad_arg "percentage must be >= 0.0 and <= 1.0"
      in
      let check_nb_exceptions n =
        if n < 0 then raise_bad_arg "number of exceptions must be >= 0"
      in
      let threshold =
        let len = String.length arg in
        if String.starts_with ~prefix:"both:" arg then
          let limits = String.sub arg 5 (len - 5) in
          match Scanf.sscanf limits "%u , %F" (fun i f -> (i, f)) with
          | exception Scanf.Scan_failure _
          | exception Failure _
          | exception End_of_file ->
              (* TODO: improve error handling/reporting *)
              raise_bad_arg ("wrong arguments: " ^ limits)
          | (nb_exceptions, percentage) as limits ->
              check_percentage percentage;
              check_nb_exceptions nb_exceptions;
              Both limits
        else if String.starts_with ~prefix:"percent:" arg then
          let percentage = String.sub arg 8 (len - 8) |> String.trim in
          match float_of_string percentage with
          | exception Failure _ ->
              (* TODO: improve error handling/reporting *)
              raise_bad_arg ("wrong argument: " ^ percentage)
          | percentage ->
              check_percentage percentage;
              Percent percentage
        else raise_bad_arg ("unknown option " ^ arg)
      in
      opt := Threshold {threshold; call_sites}


type style = {opt_arg: bool; unit_pat: bool; seq: bool; binding: bool}
let style = ref
  {
    opt_arg = false;
    unit_pat = false;
    seq = false;
    binding = false;
  }

let update_style s =
  let rec aux = function
    | (b, "opt")::l -> style := {!style with opt_arg = b};
        aux l
    | (b, "unit")::l -> style := {!style with unit_pat = b};
        aux l
    | (b, "seq")::l -> style := {!style with seq = b};
        aux l
    | (b, "bind")::l -> style := {!style with binding = b};
        aux l
    | (b, "all")::l -> style := {unit_pat = b; opt_arg = b; seq = b; binding = b};
        aux l
    | (_, "")::l -> aux l
    | (_, s)::_ -> raise (Arg.Bad ("-S: unknown option: " ^ s))
    | [] -> ()
  in
  let list_of_opt str =
    try
      let rec split acc pos len =
        if str.[pos] <> '+' && str.[pos] <> '-' then
          split acc (pos - 1) (len + 1)
        else let acc = (str.[pos] = '+', String.trim (String.sub str (pos + 1) len)) :: acc in
          if pos > 0 then split acc (pos - 1) 0
          else acc
      in split [] (String.length str - 1) 0
    with _ -> raise (Arg.Bad ("options' arguments must start with a delimiter (`+' or `-')"))
  in
  aux (list_of_opt s)


type main_section = int section

let exported : main_section ref = ref On

let obj : main_section ref = ref On

let typ : main_section ref = ref On


let get_main_threshold = function
  | Threshold {threshold; _} -> threshold
  | _ -> 0

let update_main opt (flag : main_section ref) = function
    | "all" -> flag := On
    | "nothing" -> flag := Off
    | arg ->
        let raise_bad_arg msg =
          raise (Arg.Bad (opt ^ ": " ^ msg))
        in
        let threshold_section =
          let call_sites, threshold =
            let len = String.length arg in
            if String.starts_with ~prefix:"calls:" arg then
              (true, String.sub arg 6 (len - 6))
            else if String.starts_with ~prefix:"threshold:" arg then
              (false, String.sub arg 10 (len - 10))
            else raise_bad_arg ("unknown option: " ^ arg)
          in
          match String.trim threshold |> int_of_string with
          | exception Failure _ ->
              raise_bad_arg ("expected an integer; got; Got " ^ threshold)
          | n when n < 0 ->
              raise_bad_arg ("integer should be >= 0; Got " ^ string_of_int n)
          | threshold -> {threshold; call_sites}
        in
        flag := Threshold threshold_section


let verbose = ref false
let set_verbose () = verbose := true

(* Print name starting with '_' *)
let underscore = ref true
let set_underscore () = underscore := false

let internal = ref false
let set_internal () = internal := true


let normalize_path s =
  let rec split_path s =
    let open Filename in
    if s = current_dir_name || s = dirname s then [s]
    else (basename s) :: (split_path (dirname s))
  in
  let rec norm_path = function
    | [] -> []
    | x :: ((y :: _) as yss) when x = y && x = Filename.current_dir_name -> norm_path yss
    | x :: xss ->
      if x = Filename.current_dir_name then norm_path xss (* strip leading ./ *)
      else
      let yss = List.filter (fun x -> x <> Filename.current_dir_name) xss in
      x :: yss
  in
  let rec concat_path = function
    | [] -> ""
    | x :: xs -> Filename.concat x (concat_path xs)
  in
  concat_path (norm_path (List.rev (split_path s)))

let exclude, is_excluded =
  let tbl = Hashtbl.create 10 in
  let exclude s = Hashtbl.replace tbl (normalize_path s) () in
  let is_excluded s = Hashtbl.mem tbl (normalize_path s) in
  exclude, is_excluded


let directories : string list ref = ref []
