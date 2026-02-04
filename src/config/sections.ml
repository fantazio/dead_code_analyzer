type t =
  { exported_values : main_section
  ; methods : main_section
  ; types : main_section
  ; opta : opt_args_section
  ; optn : opt_args_section
  ; style : style_section
  }

and main_section = int section

and opt_args_section = opt_args_threshold section
and opt_args_threshold =
  | Percent of float
  | Both of (int * float)

and 'threshold section =
  | Off
  | On
  | Threshold of 'threshold thresholded_section

and 'threshold thresholded_section =
  { threshold: 'threshold
  ; call_sites: bool
  }

and style_section =
  { opt_arg: bool
  ; unit_pat: bool
  ; seq: bool
  ; binding: bool
  }


let default =
  { exported_values = On
  ; methods = On
  ; types = On
  ; opta = Off
  ; optn = Off
  ; style =
    { opt_arg = false
    ; unit_pat = false
    ; seq = false
    ; binding = false
    }
  }

let is_activated = function
  | Off -> false
  | On | Threshold _ -> true

let has_activated l =
  List.exists is_activated l

let call_sites_activated = function
  | Threshold {call_sites; _} -> call_sites
  | On | Off -> false

let get_main_threshold = function
  | Threshold {threshold; _} -> threshold
  | On | Off -> 0

let parse_main_section cli_opt = function
  | "all" -> On
  | "nothing" -> Off
  | arg ->
      let raise_bad_arg msg =
        raise (Arg.Bad (cli_opt ^ ": " ^ msg))
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

let update_exported_values arg sections =
  let exported_values = parse_main_section "-E" arg in
  {sections with exported_values}

let update_methods arg sections =
  let methods = parse_main_section "-M" arg in
  {sections with methods}

let update_types arg sections =
  let types = parse_main_section "-T" arg in
  {sections with types}


let parse_opt_section = function
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

let update_opta arg sections =
  let opta = parse_opt_section arg in
  {sections with opta}

let update_optn arg sections =
  let optn = parse_opt_section arg in
  {sections with optn}


let update_style arg style =
  let rec aux style = function
    | (b, "opt")::l ->
        let style = {style with opt_arg = b} in
        aux style l
    | (b, "unit")::l ->
        let style = {style with unit_pat = b} in
        aux style l
    | (b, "seq")::l ->
        let style = {style with seq = b} in
        aux style l
    | (b, "bind")::l ->
        let style = {style with binding = b} in
        aux style l
    | (b, "all")::l ->
        let style = {unit_pat = b; opt_arg = b; seq = b; binding = b} in
        aux style l
    | (_, "")::l -> aux style l
    | (_, s)::_ -> raise (Arg.Bad ("-S: unknown option: " ^ s))
    | [] -> style
  in
  let list_of_opt arg =
    try
      let rec split acc pos len =
        if arg.[pos] <> '+' && arg.[pos] <> '-' then
          split acc (pos - 1) (len + 1)
        else let acc = (arg.[pos] = '+', String.trim (String.sub arg (pos + 1) len)) :: acc in
          if pos > 0 then split acc (pos - 1) 0
          else acc
      in split [] (String.length arg - 1) 0
    with _ -> raise (Arg.Bad ("options' arguments must start with a delimiter (`+' or `-')"))
  in
  aux style (list_of_opt arg)

let update_style arg sections =
  let style = update_style arg sections.style in
  {sections with style}
