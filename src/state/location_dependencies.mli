type t = (Lexing.position * Lexing.position) list
    (** Dependencies similar to [cmt_infos.cmt_value_dependencies] in OCaml 5.2 *)

val empty : t (** No signature read *)

val init : Cmt_format.cmt_infos -> (t, string) result
(** [init cmt_infos] expects
    [cmt_infos.cmt_annots = Implementation _].
    It converts [cmt_infos.cmt_declaration_dependencies] into a single [t].
    It returns an [Ok t] with [t] on success.
    In case the [cmt_infos] does not contain an implementation, it returns an
    [Err msg] with msg a string describing the issue. *)
