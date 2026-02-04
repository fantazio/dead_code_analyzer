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


type main_section = int section

type opt_threshold =
  | Percent of float
  | Both of (int * float)

type opt_section = opt_threshold section

type style = {opt_arg: bool; unit_pat: bool; seq: bool; binding: bool}

type t =
  { verbose : bool
  ; internal : bool
  ; underscore : bool
  ; directories : string list
  ; exported : main_section
  ; obj : main_section
  ; typ : main_section
  ; opta : opt_section
  ; optn : opt_section
  ; style : style
  }

let config = ref
  { verbose = false
  ; internal = false
  ; underscore = false
  ; directories = []
  ; exported = On
  ; obj = On
  ; typ = On
  ; opta = Off
  ; optn = Off
  ; style =
      { opt_arg = false
      ; unit_pat = false
      ; seq = false
      ; binding = false
      }
  }

let get_main_threshold = function
  | Threshold {threshold; _} -> threshold
  | _ -> 0

let parse_main opt = function
    | "all" -> On
    | "nothing" -> Off
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
        Threshold threshold_section

let update_exported cli_opt arg =
  let exported = parse_main cli_opt arg in
  config := {!config with exported}

let update_obj cli_opt arg =
  let obj = parse_main cli_opt arg in
  config := {!config with obj}

let update_typ cli_opt arg =
  let typ = parse_main cli_opt arg in
  config := {!config with typ}


let parse_opt = function
  | "all" -> On
  | "nothing" -> Off
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
      Threshold {threshold; call_sites}

let update_opta arg =
  let opta = parse_opt arg in
  config := {!config with opta}

let update_optn arg =
  let optn = parse_opt arg in
  config := {!config with optn}


let update_style s =
  let rec aux = function
    | (b, "opt")::l ->
        let style = {!config.style with opt_arg = b} in
        config := {!config with style};
        aux l
    | (b, "unit")::l ->
        let style = {!config.style with unit_pat = b} in
        config := {!config with style};
        aux l
    | (b, "seq")::l ->
        let style = {!config.style with seq = b} in
        config := {!config with style};
        aux l
    | (b, "bind")::l ->
        let style = {!config.style with binding = b} in
        config := {!config with style};
        aux l
    | (b, "all")::l ->
        let style = {unit_pat = b; opt_arg = b; seq = b; binding = b} in
        config := {!config with style};
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

let set_verbose () = config := {!config with verbose = true}

(* Print name starting with '_' *)
let set_underscore () = config := {!config with underscore = true}

let set_internal () = config := {!config with internal = true}


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


(* Option parsing and processing *)
let parse_cli process_path =
  let update_all print () =
    update_style ((if print = "all" then "+" else "-") ^ "all");
    update_exported "-E" print;
    update_obj "-M" print;
    update_typ "-T" print;
    update_opta print;
    update_optn print
  in

  (* any extra argument can be accepted by any option using some
   * although it doesn't necessary affects the results (e.g. -O 3+4) *)
  Arg.(parse
    [ "--exclude", String exclude, "<path>  Exclude given path from research.";

      "--references",
        String
          (fun dir ->
            let directories = dir :: !config.directories in
            config := {!config with directories}
          ),
        "<path>  Consider given path to collect references.";

      "--underscore", Unit set_underscore, " Show names starting with an underscore";

      "--verbose", Unit set_verbose, " Verbose mode (ie., show scanned files)";
      "-v", Unit set_verbose, " See --verbose";

      "--internal", Unit set_internal,
        " Keep internal uses as exported values uses when the interface is given. \
          This is the default behaviour when only the implementation is found";

      "--nothing", Unit (update_all "nothing"), " Disable all warnings";
      "-a", Unit (update_all "nothing"), " See --nothing";
      "--all", Unit (update_all "all"), " Enable all warnings";
      "-A", Unit (update_all "all"), " See --all";

      "-E", String (update_exported "-E"),
        "<display>  Enable/Disable unused exported values warnings.\n    \
        <display> can be:\n\
          \tall\n\
          \tnothing\n\
          \t\"threshold:<integer>\": report elements used up to the given integer\n\
          \t\"calls:<integer>\": like threshold + show call sites";

      "-M", String (update_obj "-M"),
        "<display>  Enable/Disable unused methods warnings.\n    \
        See option -E for the syntax of <display>";

      "-Oa", String (update_opta),
        "<display>  Enable/Disable optional arguments always used warnings.\n    \
        <display> can be:\n\
          \tall\n\
          \tnothing\n\
          \t<threshold>\n\
          \t\"calls:<threshold>\" like <threshold> + show call sites\n    \
        <threshold> can be:\n\
          \t\"both:<integer>,<float>\": both the number max of exceptions \
          (given through the integer) and the percent of valid cases (given as a float) \
          must be respected for the element to be reported\n\
          \t\"percent:<float>\": percent of valid cases to be reported";

      "-On", String (update_optn),
        "<display>  Enable/Disable optional arguments never used warnings.\n    \
        See option -Oa for the syntax of <display>";

      "-S", String (update_style),
        " Enable/Disable coding style warnings.\n    \
        Delimiters '+' and '-' determine if the following option is to enable or disable.\n    \
        Options (can be used together):\n\
          \tbind: useless binding\n\
          \topt: optional arg in arg\n\
          \tseq: use sequence\n\
          \tunit: unit pattern\n\
          \tall: bind & opt & seq & unit";

      "-T", String (update_typ "-T"),
        "<display>  Enable/Disable unused constructors/records fields warnings.\n    \
        See option -E for the syntax of <display>";

    ]
    (Printf.eprintf "Scanning files...\n%!";
     process_path)
    ("Usage: " ^ Sys.argv.(0) ^ " <options> <path>\nOptions are:"))
