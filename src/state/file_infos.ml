type t = {
  builddir : string;
  cm_file : string;
  cmi_sign : Types.signature option;
  cmt_struct : Typedtree.structure option;
  location_dependencies : Location_dependencies.t;
  modname : string;
  sourcepath : string option;
}

let empty = {
  builddir = "!!UNKNOWN_BUILDDIR!!";
  cm_file = "";
  cmi_sign = None;
  cmt_struct = None;
  location_dependencies = Location_dependencies.empty;
  modname = "!!UNKNOWN_MODNAME!!";
  sourcepath = None;
}

(** [init_from_all_cm_infos ~cm_file ~cmi_infos cmt_infos] creates a [t] with:
    - information from [cmt_infos] : [builddir], [modname], [sourcepath];
    - [cm_file];
    - [cmi_sign = Some cm_infos.cmi_sign] if [cmi_infos = Some _]; *)
  let init_from_all_cm_infos ~cm_file ~cmi_infos cmt_infos =
  let builddir = cmt_infos.Cmt_format.cmt_builddir in
  let sourcepath =
    Option.map Utils.Filepath.remove_pp cmt_infos.cmt_sourcefile
    |> Option.map (Filename.concat builddir)
  in
  let modname = cmt_infos.cmt_modname in
  let cmi_sign = Option.map (fun Cmi_format.{cmi_sign; _} -> cmi_sign) cmi_infos in
  {empty with builddir;
              cm_file;
              cmi_sign;
              modname;
              sourcepath}

(** [init_from_cm_file cm_file] returns an [Ok t] with [t] filled with general
    info expected for both cmt and cmti files, using the [cm_file] (see
    [init_from_all_cm_infos]).
    In case the file does not exist or it cannot be read (see
    [Cmt_format.read_cmt]) then it returns an [Err msg] with msg a string
    describing the issue. *)
let init_from_cm_file cm_file =
  if not (Sys.file_exists cm_file) then Result.error (cm_file ^ ": file not found")
  else
    match Cmt.read cm_file with
    | Error _ as err -> err
    | Ok (cmi_infos, cmt_infos) ->
        let file_infos =
          init_from_all_cm_infos ~cm_file ~cmi_infos cmt_infos
        in
        Result.ok (file_infos, cmt_infos)

let ( let* ) x f = Result.bind x f
let ( let+ ) x f = Result.map f x

let init_from_cmti_file cmti_file =
  let+ file_infos, _ = init_from_cm_file cmti_file in
  file_infos

let init_from_cmt_file cmt_file =
  let* file_infos, cmt_infos = init_from_cm_file cmt_file in
  let* cmt_struct =
    match cmt_infos.cmt_annots with
    | Implementation structure -> Result.ok structure
    | _ -> Result.error (cmt_file ^ ": does not contain an implementation")
  in
  let cmt_struct = Some cmt_struct in
  let+ location_dependencies = Location_dependencies.init cmt_infos in
  let file_infos =
    {file_infos with cmt_struct; location_dependencies}
  in
  file_infos, cmt_infos

let init cm_file =
  match Filename.extension cm_file with
  | ".cmt" ->
      let+ file_infos, _ = init_from_cmt_file cm_file in
      file_infos
  | ".cmti" -> (
      (* Using cmt_infos is not critical. The intent is to mirror the behavior
         on cmt files, where both cmt and cmti are read. *)
      let filled_with_cmt_infos =
        let cmt_file = Filename.remove_extension cm_file ^ ".cmt" in
        let* file_infos, cmt_infos = init_from_cmt_file cmt_file in
        let+ location_dependencies = Location_dependencies.init cmt_infos in
        {file_infos with location_dependencies}
      in
      match filled_with_cmt_infos with
      | Ok {cmt_struct; location_dependencies; _} ->
          let+ res, _ = init_from_cm_file cm_file in
          {res with cmt_struct; location_dependencies}
      | Error _ -> init_from_cmti_file cm_file
  )
  | _ -> Result.error (cm_file ^ ": not a .cmti or .cmt file")

let change_file file_infos cm_file =
  let no_ext = Filename.remove_extension cm_file in
  assert(no_ext = Filename.remove_extension file_infos.cm_file);
  match Filename.extension cm_file, file_infos with
  | ".cmt", {cmt_struct = (Some _ as cs); cmi_sign; _} ->
      let* res, cmt_infos = init_from_cm_file cm_file in
      let+ location_dependencies =
        match file_infos.location_dependencies with
        | [] -> Location_dependencies.init cmt_infos
        | loc_dep -> (* They have already been computed *)
            Result.ok loc_dep
      in
      {res with cmt_struct = cs; cmi_sign; location_dependencies}
  | ".cmti", {cmt_struct; location_dependencies; _} ->
      let+ res, _ = init_from_cm_file cm_file in
      {res with cmt_struct; location_dependencies}
  | _ ->
      (* invalid extension or the corresponding info is None *)
      init cm_file

let has_sourcepath file_infos = Option.is_some file_infos.sourcepath

let get_builddir t = t.builddir

let get_sourcepath t =
  match t.sourcepath with
  | Some sourcepath -> sourcepath
  | None ->
      Printf.sprintf "!!UNKNOWN_SOURCEPATH_IN<%s>_FOR_<%s>!!"
        t.builddir
        t.cm_file

let get_sourceunit t =
  match t.sourcepath with
  | Some sourcepath -> Utils.Filepath.unit sourcepath
  | None -> "!!UNKNOWN_SOURCEUNIT_FOR<" ^ t.cm_file ^ ">!!"

let get_modname t = t.modname
