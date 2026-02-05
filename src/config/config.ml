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

module StringSet = Set.Make(String)

type t =
  { verbose : bool
  ; internal : bool
  ; underscore : bool
  ; paths_to_analyze : StringSet.t
  ; excluded_paths : StringSet.t
  ; references_paths : StringSet.t
  ; sections : Sections.t
  }

let default_config =
  { verbose = false
  ; internal = false
  ; underscore = false
  ; paths_to_analyze = StringSet.empty
  ; excluded_paths = StringSet.empty
  ; references_paths = StringSet.empty
  ; sections = Sections.default
  }

let has_main_section_activated config =
  let sections = config.sections in
  has_activated [sections.exported_values; sections.methods; sections.types]

let has_opt_args_section_activated config =
  let sections = config.sections in
  has_activated [sections.opta; sections.optn]

let update_exported_values arg config =
  let sections = Sections.update_exported_values arg config.sections in
  {config with sections}

let update_methods arg config =
  let sections = Sections.update_methods arg config.sections in
  {config with sections}

let update_types arg config =
  let sections = Sections.update_types arg config.sections in
  {config with sections}

let update_opta arg config =
  let sections = Sections.update_opta arg config.sections in
  {config with sections}

let update_optn arg config =
  let sections = Sections.update_optn arg config.sections in
  {config with sections}

let update_style arg config =
  let sections = Sections.update_style arg config.sections in
  {config with sections}

let set_verbose config = {config with verbose = true}

(* Print name starting with '_' *)
let set_underscore config = {config with underscore = true}

let set_internal config = {config with internal = true}


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

let exclude path config =
  let path = normalize_path path in
  let excluded_paths = StringSet.add path config.excluded_paths in
  {config with excluded_paths}

let is_excluded path config =
  let path = normalize_path path in
  StringSet.mem path config.excluded_paths

let add_reference_path path config =
  let references_paths = StringSet.add path config.references_paths in
  {config with references_paths}

let add_path_to_analyze path config =
  let paths_to_analyze = StringSet.add path config.paths_to_analyze in
  {config with paths_to_analyze}

(* Command line parsing *)
let parse_cli () =
  let config = ref default_config in
  let update_config f x = config := f x !config in

  let update_config_unit f () = config := f !config in

  let update_all arg config =
    config
    |> update_style ((if arg = "all" then "+" else "-") ^ "all")
    |> update_exported_values arg
    |> update_methods arg
    |> update_types arg
    |> update_opta arg
    |> update_optn arg
  in

  Arg.(parse
    [ "--exclude",
        String (update_config exclude),
        "<path>  Exclude given path from research.";

      "--references",
        String (update_config add_reference_path),
        "<path>  Consider given path to collect references.";

      "--underscore",
        Unit (update_config_unit set_underscore),
        " Show names starting with an underscore";

      "--verbose",
        Unit (update_config_unit set_verbose),
        " Verbose mode (ie., show scanned files)";
      "-v", Unit (update_config_unit set_verbose), " See --verbose";

      "--internal",
        Unit (update_config_unit set_internal),
        " Keep internal uses as exported values uses when the interface is given. \
          This is the default behaviour when only the implementation is found";

      "--nothing",
        Unit (update_config_unit (update_all "nothing")),
        " Disable all warnings";
      "-a", Unit (update_config_unit (update_all "nothing")), " See --nothing";

      "--all",
        Unit (update_config_unit (update_all "all")),
        " Enable all warnings";
      "-A", Unit (update_config_unit (update_all "all")), " See --all";

      "-E",
        String (update_config update_exported_values),
        "<display>  Enable/Disable unused exported values warnings.\n    \
        <display> can be:\n\
          \tall\n\
          \tnothing\n\
          \t\"threshold:<integer>\": report elements used up to the given integer\n\
          \t\"calls:<integer>\": like threshold + show call sites";

      "-M",
        String (update_config update_methods),
        "<display>  Enable/Disable unused methods warnings.\n    \
        See option -E for the syntax of <display>";

      "-Oa",
        String (update_config update_opta),
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

      "-On",
        String (update_config update_optn),
        "<display>  Enable/Disable optional arguments never used warnings.\n    \
        See option -Oa for the syntax of <display>";

      "-S",
        String (update_config update_style),
        " Enable/Disable coding style warnings.\n    \
        Delimiters '+' and '-' determine if the following option is to enable or disable.\n    \
        Options (can be used together):\n\
          \tbind: useless binding\n\
          \topt: optional arg in arg\n\
          \tseq: use sequence\n\
          \tunit: unit pattern\n\
          \tall: bind & opt & seq & unit";

      "-T",
        String (update_config update_types),
        "<display>  Enable/Disable unused constructors/records fields warnings.\n    \
        See option -E for the syntax of <display>";

    ]
    (Printf.eprintf "Scanning files...\n%!";
     update_config add_path_to_analyze)
    ("Usage: " ^ Sys.argv.(0) ^ " <options> <path>\nOptions are:"));

  !config
