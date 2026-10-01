module Filepath : sig

  type t = string

  val remove_pp : t -> t
  (** [remove_pp filepath] removes the `.pp` extension (if it exists) from
      [filepath]. Eg. [remove_pp "dir/foo.pp.ml" = "dir/foo.ml"] *)

  val unit : t -> string
  (** [unit filepath] estimates the compilation unit of [filepath] *)

  type kind =
    | Cmti (** .cmti file *)
    | Cmt_without_mli (** .cmt file of .ml only module *)
    | Cmt_with_mli (** .cmt file of module with .mli *)
    | Dir (** Directory *)
    | Ignore (** Irrelevant for the analyzer *)

  val kind : exclude:(t -> bool) -> t -> kind
  (** [kind ~exclude filepath] returns the kind of [filepath].
      If [exclude filepath = true], [filepath] does not exists, or [filepath]
      does not fit in another kind, then its kind is [Ignore].
      Other kinds are self explanatory. *)
end

val signature_of_modtype :
  ?select_param:bool -> Types.module_type -> Types.signature
(** [signature_of_modtype ?select_param modtype] returns the selected signature
    of [modtype]. If [modtype] is a functor, then [select_param] is used to
    select either the signature of the parameter or the result of the functor.
    Note: [select_param] is [false] by default. If set to [true], it is reset to
          [false] after looking for the parameter of the first functor.
          There is currently no way to select the parameter of a parameter.  *)

val typedtree_signature_of_modtype :
  ?select_param:bool -> Typedtree.module_type -> Typedtree.signature option
(** [signature_of_modtype ?select_param modtype] returns the selected
    Typedtree.signature of [modtype] when possible.
    See {!signature_of_modtype} above for more information
*)

module StringSet : Set.S with type elt = String.t

module Envaux : sig
  type paths =
    #if OCAML_VERSION >= (5, 2, 0)
    Load_path.paths
    #else
    string list
    #endif

  val set_loadpaths : paths -> unit
  (** Reset the load_path to the [paths]. Also calls Envaux.reset_cache.
      To call when loading a new .cmt *)

  val load_env : Env.t -> Env.t
  (** Same as Envaux.env_of_only_summary but ensures the paths submitted
      in set_loadpaths are actually set. *)
end

module Compat : sig

  open Typedtree

  #if OCAML_VERSION >= (5, 4, 0)
  val unlabel_tuple : ('a * 'b) list -> 'b list
  #else
  val unlabel_tuple : 'a list -> 'a list
  #endif
  (** Tuple's field representation changed in OCaml 5.4, with the
      introduction of labelled tuples. This converts a tuple's fields back
      into the pre-5.4 representation. *)

  val options_of_args :
    ( Asttypes.arg_label
    * (expression option, Vaast.OCaml.Typedtree.apply_arg) Vaast.Core.ocaml_504
    ) list
    -> (Asttypes.arg_label * expression option) list
  (** Apply's arguments representation changed in OCaml 5.4, from
      expression option to arg_or_omitted. This does the reverse conversion *)

  val flatten_effect_cases :
    (Vaast.Core.not_available, value case list) Vaast.Core.ocaml_503
    -> value case list
  (** Effect cases in match and try were introduced in OCaml 5.3.
      This reutrns emulates their non-existence in OCaml < 5.3 via an empty
      list *)

end
