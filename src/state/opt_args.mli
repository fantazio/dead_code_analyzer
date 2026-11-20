(** Stateful manipulations related to optional arguments

  Description of the opt_arg identification:
    - For a declaration, only the explicit optional arguments
      are expected to be stored.
      E.g. in {[
        let f ?a ?b () = ...
        let g ?c = f
        ]} the optional arguments of [f] are both explicitly declared,
        and only the [?c] optional argument of [g] is, atlhgouh it expects
        [?a] and [?b] as well.
    - An alias is not a function alias but an alias from implicitly declared
      optional arguments to the corresponding explicitily ones.
      E.g. in the above example, there would be an alias from [g] to [f]
      meaning that a use of [g]'s [?a] is actually a use of [f]'s.
      Actual function aliases are handled separately.
    - For uses, an optional argument is identified via its name and occurence
      (see {!add_use}).
      An optional argument's occurence may be greater than the used function's
      max occurence for the same argument. In this situation, the use will be
      propagated to the corresponding alias.
      E.g. [g ?a ()] will propagate the uses of [?a] and [?b] to [f].
*)

type t

val create : unit -> t
(** Default value to start with *)

val add_exported_declaration :
  builddir:string ->
  fun_loc:Lexing.position ->
  opt_arg_name:string ->
  t
  -> t
(** [add_exported_declaration ~builddir ~fun_loc ~oa_name opt_args]
    returns a [t] containing the same info as [opt_args], plus an extra
    declaration at [fun_loc] in [builddir] for optional argument [oa_name].
    NOTE: [fun_loc] is the location of the function owning [oa_name]. The
          same [oa_name] may be added multiple times. Only explicit
          declarations are expected.
*)

val remove_exported_declaration :
  ?builddir:string ->
  fun_loc:Lexing.position ->
  oa_name:string ->
  ?all:bool ->
  t
  -> t
(** [remove_exported_declaration ?builddir ~fun_loc ~oa_name ?all opt_args]
    returns a [t] containing the same info as [opt_args] minus the
    declaration of [oa_name] at [fun_loc] in [builddir].
    If [builddir = None], then the [oa_name] at [fun_loc] in all the
    builddirs are removed.
    If [all=true] (the default), then all the declarations of [oa_name]
    at [fun_loc] are removed. Otherwise, only the last one is.
*)

val remove_exported_declarations :
  ?builddir:string ->
  fun_loc:Lexing.position ->
  t
  -> t
(** [remove_exported_declarations ?builddir ~fun_loc opt_args]
    is the same as calling {!remove_exported_declaration} above for each
    [oa_name] of the function.
*)

val is_exported_declaration : fun_loc:Lexing.position -> t -> bool
(** [is_exported_declaration ~fun_loc opt_args] returns [true] if [fun_loc] was
    added to [opt_args] via {!add_exported_declaration} above and not removed.
    Otherwise, it returns [false].
*)


type opt_arg_id : (string * int)
(** [(name, occurence)] with [name] the name of the opt arg, and occurence
    the number of times the same [name] has already been used before in
    the context.
    E.g. in [f ?a ?a ()] the first opt arg is [("?a", 0)] and the second
         is [("?a"; 1)}
*)

val add_use :
  fun_loc:Lexing.position ->
  oa_id:opt_arg_id ->
  use_loc:Lexing.position ->
  use_kind:[< `With_val | `Discard ] ->
  t
  -> t
(** [add_use ~fun_loc ~oa_id ~use_loc ~use_kind opt_args]
    returns a [t] containing the same info as [opt_args], plus an extra
    use at [use_loc] of [oa_id] declared by [fun_loc].
    The [use_kind] indicates whether the optional argument is provided a value
    or discarded, resulting in it being considered used or unused in the
    context of the use of its function [fun_loc].
*)

val remove_uses : fun_loc:Lexing.position -> ?oa_id:opt_arg_id -> t -> t
(** [remove_use ~fun_loc ?oa_name opt_args]
    returns a [t] containing the same the same info as [opt_args], minus all
    the uses of [fun_loc].
    If a [oa_id] is provided, then only uses associated to this name
    are removed.
*)

val get_uses :
  fun_loc:Lexing.position ->
  oa_id:opt_arg_id ->
  use_kind:[< `All | `With_val | `Discard ] ->
  t
  -> Lexing.position list
(** [get_uses ~fun_loc ~oa_id ~use_kind opt_args] returns all the [use_loc]
    that were associated with [oa_id] of [fun_loc] for [use_kind] via
    {!add_use} above.
    If [use_kind] is [`All] then all the uses are returned, regardless of their kind.
*)

val get_used_with_val :
  t
  -> (int, (Lexing.position * opt_arg_id * string) list) Hashtbl.t
(** [get_used_with_val opt_args] returns a table containing the [fun_loc]
    of [oa_id] in [builddir] added via {!add_exported_declaration}
    above and not removed
    The key is the amount of associated uses with val, and the value the list of
    [fun_loc * oa_name * builddir] used key number of times.
*)

val get_used_discard :
  t
  -> (int, (Lexing.position * opt_arg_id * string) list) Hashtbl.t
(** [get_used_discard opt_args] returns a table containing the [fun_loc]
    of [oa_id] in [builddir] added via {!add_exported_declaration}
    above and not removed
    The key is the amount of associated discarding uses, and the value the list of
    [fun_loc * oa_name * builddir] used key number of times.
*)

val add_alias : orig_loc:Lexing.position -> alias_loc:Lexing.position -> t -> t
(** [add_alias ~orig_loc ~alias_loc opt_args] returns a [t] containing the
    same info as [opt_args], plus an extra alias to [orig_loc] for opt args
    implicitly declared at [alias_loc].
*)

val resolve_aliases : t -> t
(** [resolve_aliases opt_args] returns a [t] containing the same info as [opt_args]
    with all the uses of aliases translated as uses of the original declaration,
    and without [alias_loc] among the declarations.
    This function is meant to be called once before calling either
    {!get_used_with_val} or {!get_used_discard=.
*)
