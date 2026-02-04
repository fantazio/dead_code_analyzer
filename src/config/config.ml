(***************************************************************************)
(*                                                                         *)
(*   Copyright (c) 2014-2025 LexiFi SAS. All rights reserved.              *)
(*                                                                         *)
(*   This source code is licensed under the MIT License                    *)
(*   found in the LICENSE file at the root of this source tree             *)
(*                                                                         *)
(***************************************************************************)

module Sections = Sections

let is_activated = Sections.is_activated

let has_activated = Sections.has_activated

let call_sites_activated = Sections.call_sites_activated

let get_main_threshold = Sections.get_main_threshold

type t =
  { verbose : bool
  ; internal : bool
  ; underscore : bool
  ; directories : string list
  ; sections : Sections.t
  }

let config = ref
  { verbose = false
  ; internal = false
  ; underscore = false
  ; directories = []
  ; sections = Sections.default
  }

let has_main_section_activated () =
  let sections = !config.sections in
  has_activated [sections.exported_values; sections.methods; sections.types]

let has_opt_args_section_activated () =
  let sections = !config.sections in
  has_activated [sections.opta; sections.optn]

let update_exported_values arg =
  let sections = Sections.update_exported_values arg !config.sections in
  config := {!config with sections}

let update_methods arg =
  let sections = Sections.update_methods arg !config.sections in
  config := {!config with sections}

let update_types arg =
  let sections = Sections.update_types arg !config.sections in
  config := {!config with sections}

let update_opta arg =
  let sections = Sections.update_opta arg !config.sections in
  config := {!config with sections}

let update_optn arg =
  let sections = Sections.update_optn arg !config.sections in
  config := {!config with sections}

let update_style arg =
  let sections = Sections.update_style arg !config.sections in
  config := {!config with sections}

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
    update_exported_values print;
    update_methods print;
    update_types print;
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

      "-E", String update_exported_values,
        "<display>  Enable/Disable unused exported values warnings.\n    \
        <display> can be:\n\
          \tall\n\
          \tnothing\n\
          \t\"threshold:<integer>\": report elements used up to the given integer\n\
          \t\"calls:<integer>\": like threshold + show call sites";

      "-M", String update_methods,
        "<display>  Enable/Disable unused methods warnings.\n    \
        See option -E for the syntax of <display>";

      "-Oa", String update_opta,
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

      "-On", String update_optn,
        "<display>  Enable/Disable optional arguments never used warnings.\n    \
        See option -Oa for the syntax of <display>";

      "-S", String update_style,
        " Enable/Disable coding style warnings.\n    \
        Delimiters '+' and '-' determine if the following option is to enable or disable.\n    \
        Options (can be used together):\n\
          \tbind: useless binding\n\
          \topt: optional arg in arg\n\
          \tseq: use sequence\n\
          \tunit: unit pattern\n\
          \tall: bind & opt & seq & unit";

      "-T", String update_types,
        "<display>  Enable/Disable unused constructors/records fields warnings.\n    \
        See option -E for the syntax of <display>";

    ]
    (Printf.eprintf "Scanning files...\n%!";
     process_path)
    ("Usage: " ^ Sys.argv.(0) ^ " <options> <path>\nOptions are:"))
