(***************************************************************************)
(*                                                                         *)
(*   Copyright (c) 2014-2025 LexiFi SAS. All rights reserved.              *)
(*                                                                         *)
(*   This source code is licensed under the MIT License                    *)
(*   found in the LICENSE file at the root of this source tree             *)
(*                                                                         *)
(***************************************************************************)

open Types
open Typedtree

open DeadCommon

let at_eof = ref []
let at_eocb = ref []

let met = Hashtbl.create 512

let eof () =
  List.iter (fun f -> f ()) !at_eof;
  at_eof := [];
  Hashtbl.reset met

let increment_count label count_tbl =
  let count = Hashtbl.find_opt count_tbl label |> Option.value ~default:0 in
  let count = count + 1 in
  Hashtbl.replace count_tbl label count;
  count

let register_use label expr loc last_loc count_tbl =
  let has_val =
    match expr.exp_desc with
    | Texp_construct (_, { cstr_name = "None"; _ }, _) -> false
    | _ -> true
  in
  let count = increment_count label count_tbl in
  let call_site =
    if expr.exp_loc.Location.loc_ghost then last_loc
    else expr.exp_loc.Location.loc_start
  in
  if check_underscore label then
    let loc = VdNode.find loc label count in
    if not (Hashtbl.mem met (last_loc, loc, label)) then (
      Hashtbl.add met (last_loc, loc, label) ();
      opt_args := (loc, label, has_val, call_site) :: !opt_args
    )

let rec register_uses loc args =
  List.iter (fun (_, e) -> Option.iter register_higher_order_uses e) args;
  if is_ghost loc then () (* Ghostbuster *)
  else
    let count_tbl = Hashtbl.create 256 in
    let add =
      (* last_loc fixed to avoid side effects if added to at_eof/at_eocb *)
      let last_loc = !last_loc in
      fun label expr -> register_use label expr loc last_loc count_tbl
    in
    let add = function
      | (Asttypes.Optional label, Some expr) ->
          if VdNode.is_end loc then
            let fn = loc.Lexing.pos_fname in
            if fn.[String.length fn - 1] = 'i' then
              (* What does it mean to have a loc in a signature ?
               * When does it happen ? *)
              at_eocb := (fun () -> add label expr) :: !at_eocb
            else if !depth > 0 then
              at_eof := (fun () -> add label expr) :: !at_eof
            else add label expr
          else add label expr
      | _ -> ()
    in
    List.iter add args

(* Verify the nature of the argument to detect and treat function applications and uses *)
and register_higher_order_uses e =
  (* Optional arguments expected by arrow-typed parameter are considered used
   * because they are necessary to match the expected signature *)
  let gen_used_opt_args typ =
    let rec loop args typ =
      match get_deep_desc typ with
      (* TODO: on arrow-type, should go down the parameters too in case they are
       * arrow-typed and expecting optional arguments too *)
      | Tarrow ((Asttypes.Optional _ as arg), _, t, _) ->
          loop
            (( arg,
               (* hack to count a use for the current arg *)
               Some { e with exp_desc = Texp_constant (Asttypes.Const_int 0) }
             )
            :: args
            )
            t
      | Tarrow (_, _, t, _) -> loop args t
      | _ -> args
    in
    loop [] typ
  in

  match e.exp_desc with
  | Texp_ident (_, _, { val_loc = { Location.loc_start = loc; _ }; _ }) ->
      register_uses loc (gen_used_opt_args e.exp_type)
  | Texp_apply (exp, _) -> (
      match exp.exp_desc with
      | Texp_ident
          (_, _, { val_loc = { Location.loc_start = loc; loc_ghost; _ }; _ })
      | Texp_field
          (_, _, { lbl_loc = { Location.loc_start = loc; loc_ghost; _ }; _ }) ->
          register_uses loc (gen_used_opt_args e.exp_type);
          (* Why do we want to set last_loc here ? *)
          if not loc_ghost then last_loc := loc
      | _ -> ()
    )
  | Texp_let (_, [ binding ], expr) -> (
      (* Partial application as argument may cut in two parts:
       * let _ = partial in implicit opt_args elimination *)
      let ( let$ ) x f = Option.iter f x in
      let$ ident_loc =
        match binding.vb_expr.exp_desc with
        | Texp_apply ({ exp_desc = Texp_ident (_, _, val_desc); _ }, _)
        | Texp_ident (_, _, val_desc) ->
            Some val_desc.val_loc.loc_start
        | _ -> None
      in
      let$ (c_lhs, c_rhs) =
        match expr.exp_desc with
        | Texp_function (_, Tfunction_cases { cases = [ case ]; _ }) ->
            Some (case.c_lhs, case.c_rhs)
        | _ -> None
      in
      match (c_lhs.pat_desc, c_rhs.exp_desc) with
      | (Tpat_var _, Texp_apply (_, args)) ->
          if
            c_lhs.pat_loc.loc_ghost && c_rhs.exp_loc.loc_ghost
            && expr.exp_loc.loc_ghost
          then register_uses ident_loc args
      | _ -> ()
    )
  | _ -> ()

let bind loc expr =
  let rec loop loc expr =
    match expr.exp_desc with
    | Texp_function (params, body) -> (
        let check_param_style = function
          | Tparam_pat { pat_type; _ }
          | Tparam_optional_default ({ pat_type; _ }, _) ->
              DeadType.check_style pat_type expr.exp_loc.Location.loc_start
        in
        let register_optional_param = function
          | Asttypes.Optional s
            when !DeadFlag.optn.print || !DeadFlag.opta.print ->
              let (opts, next) = VdNode.get loc in
              VdNode.update loc (s :: opts, next)
          | _ -> ()
        in
        List.iter
          (fun { fp_kind; fp_arg_label; _ } ->
            check_param_style fp_kind;
            register_optional_param fp_arg_label
          )
          params;
        match body with
        | Tfunction_body exp -> loop loc exp
        | Tfunction_cases
            { cases = [ { c_lhs = { pat_type; _ }; c_rhs = exp; _ } ]; _ } ->
            DeadType.check_style pat_type expr.exp_loc.Location.loc_start;
            loop loc exp
        | _ -> ()
      )
    | exp_desc
      when (!DeadFlag.optn.print || !DeadFlag.opta.print)
           && DeadType.nb_args ~keep:`Opt expr.exp_type > 0 ->
        let ( let$ ) x f = Option.iter f x in
        let$ loc2 =
          match exp_desc with
          | Texp_ident (_, _, { val_loc = loc; _ }) -> Some loc.loc_start
          | Texp_apply ({ exp_desc; _ }, _) -> (
              match exp_desc with
              | Texp_ident (_, _, { val_loc = loc; _ })
              | Texp_field (_, _, { lbl_loc = loc; _ }) ->
                  Some loc.loc_start
              | _ -> None
            )
          | _ -> None
        in
        VdNode.merge_locs loc loc2
    | _ -> ()
  in
  loop loc expr

(********   WRAPPING  ********)

let wrap f x y = if DeadFlag.(!optn.print || !opta.print) then f x y else ()

let register_uses val_loc args = wrap register_uses val_loc args
