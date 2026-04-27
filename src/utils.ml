module Filepath = struct

  type t = string

  let remove_pp filepath =
    let ext = Filename.extension filepath in
    let no_ext = Filename.remove_extension filepath in
    match Filename.extension no_ext with
    | ".pp" -> Filename.remove_extension no_ext ^ ext
    | _ -> filepath

  let unit filepath =
    (* reproduce https://github.com/ocaml/ocaml/blob/5.3/parsing/unit_info.ml#L60 *)
    let remove_all_ext basename =
      match String.index basename '.' with
        | dot_pos -> String.sub basename 0 dot_pos
        | exception Not_found -> basename
    in
    filepath |> Filename.basename |> remove_all_ext |> String.capitalize_ascii

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

module StringSet = Set.Make(String)
