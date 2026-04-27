type t = (Lexing.position * Lexing.position) list

let empty = []

let init = function
  | Cmt_format.{cmt_annots = Implementation _; cmt_value_dependencies; _} ->
      let loc_of_vd vd = vd.Types.val_loc.loc_start in
      cmt_value_dependencies
      |> List.map (fun (vd1, vd2) -> loc_of_vd vd1, loc_of_vd vd2)
      |> Result.ok
  | _ -> Result.error "No implementation found in cmt_infos"
