module Filepath = struct

  type t = string

  let remove_pp filepath =
    let ext = Filename.extension filepath in
    let no_ext = Filename.remove_extension filepath in
    match Filename.extension no_ext with
    | ".pp" -> Filename.remove_extension no_ext ^ ext
    | _ -> filepath

  [%%if ocaml_version >= (5, 3, 0)]
  let unit filepath =
    Unit_info.lax_modname_from_source filepath
  [%%else]
  let unit filepath =
    (* reproduce https://github.com/ocaml/ocaml/blob/5.3/parsing/unit_info.ml#L60 *)
    let remove_all_ext basename =
      match String.index basename '.' with
        | dot_pos -> String.sub basename 0 dot_pos
        | exception Not_found -> basename
    in
    filepath |> Filename.basename |> remove_all_ext |> String.capitalize_ascii
  [%%endif]

  type kind =
    | Cmti
    | Cmt_without_mli
    | Cmt_with_mli
    | Dir
    | Ignore

  (* Checks the nature of the file *)
  let kind ~exclude filepath =
    if exclude filepath then Ignore
    else if not (Sys.file_exists filepath) then (
      prerr_endline ("Warning: '" ^ filepath ^ "' not found");
      Ignore
    )
    else if Sys.is_directory filepath then Dir
    else if Filename.check_suffix filepath ".cmti" then Cmti
    else if Filename.check_suffix filepath ".cmt" then
      let cmti = Filename.remove_extension filepath ^ ".cmti" in
      if Sys.file_exists cmti then Cmt_with_mli
      else Cmt_without_mli
    else Ignore
end

let rec signature_of_modtype ?(select_param = false) modtype =
  let open Types in
  match modtype with
  | Mty_signature sg -> sg
  | Mty_functor (_, t) when not select_param -> signature_of_modtype t
  | Mty_functor (Named (_, t), _) -> signature_of_modtype t
  | _ -> []

let rec typedtree_signature_of_modtype ?(select_param = false) modtype =
  let open Typedtree in
  match modtype.mty_desc with
  | Tmty_signature sg -> Some sg
  | Tmty_functor (_, t) when not select_param -> typedtree_signature_of_modtype t
  | Tmty_functor (Named (_, _, t), _) -> typedtree_signature_of_modtype t
  | _ -> None

module StringSet = Set.Make(String)

module Envaux = struct
  (* Lazy set up of loadpaths for load_env.
     This is used to ensure the setup is applied only once and only if
     necessary
  *)
  let setup = ref (Lazy.from_val ())
  let force_setup () = Lazy.force !setup

  [%%if ocaml_version >= (5, 2, 0)]
  type paths = Load_path.paths
  [%%else]
  type paths = string list
  [%%endif]

  [%%if ocaml_version >= (5, 2, 0)]
  let init_load_path paths =
    let auto_include = Load_path.no_auto_include in
    let visible = paths.Load_path.visible in
    let hidden = paths.Load_path.hidden in
    Load_path.init ~auto_include ~visible ~hidden
  [%%elif ocaml_version >= (5, 0, 0)]
  let init_load_path paths =
    let auto_include = Load_path.no_auto_include in
    Load_path.init ~auto_include paths
  [%%else]
  let init_load_path paths =
    Load_path.init paths
  [%%endif]

  let set_loadpaths paths =
    let reset () =
      init_load_path paths;
      Envaux.reset_cache ()
    in
    setup := Lazy.from_fun reset

  let load_env env =
    force_setup ();
    Envaux.env_of_only_summary env
end

module Compat = struct

  open Typedtree

  (* Conversions *)

  [%%if ocaml_version >= (5, 4, 0)]
  let unlabel_tuple fields = List.map snd fields
  [%%else]
  let unlabel_tuple fields = fields
  [%%endif]

  [%%if ocaml_version >= (5, 4, 0)]
  let options_of_args args =
    (* Texp_apply's args changed in OCaml 5.4, from expression option
       to arg_or_omitted. This does the reverse conversion *)
    List.map
      (fun (lab, arg) ->
        match arg with
        | Arg expr -> lab, Some expr
        | Omitted _ -> lab, None
      )
      args
  [%%else]
  let options_of_args args = args
  [%%endif]

  (* Getters *)

  let get_lab_desc lab = lab

  type _ invalid_arg =
    | Unexpected_pattern : string * 'k pattern_desc -> 'k pattern_desc invalid_arg
    | Unexpected_expression :
        string * expression_desc -> expression_desc invalid_arg

  [%%if ocaml_version < (5, 2, 0)]
  let dummy_uid = Shape.Uid.internal_not_actually_unique
    (* A uid field appears in multiple constructors in OCaml 5.2.
       This dummy value serves as replacement. We do not rely on its value
       but need it to exist for typing. *)
  [%%endif]

  type ('k, 'a) pat_getter = 'k pattern_desc -> ('a, 'k pattern_desc invalid_arg) result

  type alias_data = value general_pattern * Ident.t * Location.t * Shape.Uid.t

  let get_alias_data_err pat_desc =
    let msg = "get_alias_data expects a Tpat_alias" in
    let err = Unexpected_pattern (msg, pat_desc) in
    Result.Error err

  [%%if ocaml_version >= (5, 4, 0)]
  let get_alias_data : type k . (k, alias_data) pat_getter = function
    | Tpat_alias (pat, id, {loc; _}, uid, _) ->
      Result.Ok (pat, id, loc, uid)
    | pat_desc -> get_alias_data_err pat_desc
  [%%elif ocaml_version >= (5, 2, 0)]
  let get_alias_data : type k . (k, alias_data) pat_getter = function
    | Tpat_alias (pat, id, {loc; _}, uid) ->
      Result.Ok (pat, id, loc, uid)
    | pat_desc -> get_alias_data_err pat_desc
  [%%else]
  let get_alias_data : type k . (k, alias_data) pat_getter = function
    | Tpat_alias (pat, id, {loc; _}) ->
        let uid = dummy_uid in
      Result.Ok (pat, id, loc, uid)
    | pat_desc -> get_alias_data_err pat_desc
  [%%endif]

  let get_alias_data_exn pat_desc =
    get_alias_data pat_desc |> Result.get_ok

  type var_data = Ident.t * string Location.loc * Shape.Uid.t

  let get_var_data_err pat_desc =
    let msg = "get_var_data expects a Tpat_var or Tpat_alias(Tpat_any)" in
    let err = Unexpected_pattern (msg, pat_desc) in
    Result.Error err

  [%%if ocaml_version >= (5, 4, 0)]
  let get_var_data : type k . (k, var_data) pat_getter = function
    | Tpat_var (id, loc, uid)
    | Tpat_alias ({pat_desc=Tpat_any; _}, id, loc, uid, _) ->
        Result.ok (id, loc, uid)
    | pat_desc -> get_var_data_err pat_desc
  [%%elif ocaml_version >= (5, 2, 0)]
  let get_var_data : type k . (k, var_data) pat_getter = function
    | Tpat_var (id, loc, uid)
    | Tpat_alias ({pat_desc=Tpat_any; _}, id, loc, uid) ->
        Result.ok (id, loc, uid)
    | pat_desc -> get_var_data_err pat_desc
  [%%else]
  let get_var_data : type k . (k, var_data) pat_getter = function
    | Tpat_var (id, loc)
    | Tpat_alias ({pat_desc=Tpat_any; _}, id, loc) ->
        let uid = dummy_uid in
        Result.ok (id, loc, uid)
    | pat_desc -> get_var_data_err pat_desc
  [%%endif]

  let get_var_data_exn pat_desc =
    get_var_data pat_desc |> Result.get_ok

  type 'a exp_getter =
    expression_desc -> ('a, expression_desc invalid_arg) result

  type match_data =
    expression * computation case list * value case list * partial

  let get_match_data_err exp_desc =
    let msg = "get_match_data expects a Texp_match" in
    let err = Unexpected_expression (msg, exp_desc) in
    Result.Error err

  [%%if ocaml_version >= (5, 3, 0)]
  let get_match_data = function
    | Texp_match (exp, reg_cases, eff_cases, partial) ->
        Result.Ok (exp, reg_cases, eff_cases, partial)
    | exp_desc -> get_match_data_err exp_desc
  [%%else]
  let get_match_data = function
    | Texp_match (exp, reg_cases, partial) ->
        let eff_cases = [] in (* effect cases appear in OCaml 5.3 *)
        Result.Ok (exp, reg_cases, eff_cases, partial)
    | exp_desc -> get_match_data_err exp_desc
  [%%endif]

  let get_match_data_exn exp_desc =
    get_match_data exp_desc |> Result.get_ok

  type try_data =
    expression * value case list * value case list

  let get_try_data_err exp_desc =
    let msg = "get_try_data expects a Texp_try" in
    let err = Unexpected_expression (msg, exp_desc) in
    Result.Error err

  [%%if ocaml_version >= (5, 3, 0)]
  let get_try_data = function
    | Texp_try (exp, reg_cases, eff_cases) ->
        Result.Ok (exp, reg_cases, eff_cases)
    | exp_desc -> get_try_data_err exp_desc
  [%%else]
  let get_try_data = function
    | Texp_try (exp, reg_cases) ->
        let eff_cases = [] in (* effect cases appear in OCaml 5.3 *)
        Result.Ok (exp, reg_cases, eff_cases)
    | exp_desc -> get_try_data_err exp_desc
  [%%endif]

  let get_try_data_exn exp_desc =
    get_try_data exp_desc |> Result.get_ok

  type function_bodies = expression list

  let get_function_bodies_err exp_desc =
    let msg = "get_function_bodies expects a Texp_function" in
    let err = Unexpected_expression (msg, exp_desc) in
    Result.Error err

  [%%if ocaml_version >= (5, 2, 0)]
  let get_function_bodies = function
    | Texp_function (_, Tfunction_body expr) ->
        Result.ok [expr]
    | Texp_function (_, Tfunction_cases { cases ; _ }) ->
        let bodies = List.map (fun {c_rhs; _} -> c_rhs) cases in
        Result.ok bodies
    | exp_desc -> get_function_bodies_err exp_desc
  [%%else]
  let get_function_bodies = function
    | Texp_function {cases ; _} ->
        let bodies = List.map (fun {c_rhs; _} -> c_rhs) cases in
        Result.ok bodies
    | exp_desc -> get_function_bodies_err exp_desc
  [%%endif]

  type function_cases = value case list

  let get_function_cases_err exp_desc =
    let msg = "get_function_cases expects a Texp_function" in
    let err = Unexpected_expression (msg, exp_desc) in
    Result.Error err

  [%%if ocaml_version >= (5, 2, 0)]
  let get_function_cases = function
    | Texp_function (_, Tfunction_cases { cases ; _ }) ->
        Result.ok cases
    | exp_desc -> get_function_cases_err exp_desc
  [%%else]
  let get_function_cases = function
    | Texp_function {cases ; _} ->
        Result.ok cases
    | exp_desc -> get_function_cases_err exp_desc
  [%%endif]

end
