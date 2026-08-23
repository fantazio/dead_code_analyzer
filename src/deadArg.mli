(***************************************************************************)
(*                                                                         *)
(*   Copyright (c) 2014-2025 LexiFi SAS. All rights reserved.              *)
(*                                                                         *)
(*   This source code is licensed under the MIT License                    *)
(*   found in the LICENSE file at the root of this source tree             *)
(*                                                                         *)
(***************************************************************************)

open Typedtree

val at_eof : (unit -> unit) list ref
(** Functions deferred to run at the end of the current file's analysis.
    They reaqire the analysis of future locations in the current file.
    It is known that these locations will have been processed at the end
    of the binding.
    Needed because the Tast_mapper runs through sequences from the end
    because tuples are built from right to left. *)

val eof : unit -> unit
(** To use at the end of a [.cmt]'s analysis:
    apply [at_eof] functions + reset internal state *)

val eocb : unit -> unit
(** To use at the end of the codebase analysis:
    apply remaining deferred functions which required the analysis of future
    locations, their respective files.
    [eocb] = end of code base. *)

val options_of_args :
  #if OCAML_VERSION >= (5, 3, 0) && OCAML_VERSION < (5, 4, 0)
  (Asttypes.arg_label * expression option) list
  #elif OCAML_VERSION >= (5, 4, 0) && OCAML_VERSION < (5, 5, 0)
  (Asttypes.arg_label * (expression, unit) arg_or_omitted) list
  #endif
  -> (Asttypes.arg_label * expression option) list
(** Convert Texp_apply's args representation to its OCaml 5.3 representation.
    In particular, the type of a single arg changed in OCaml 5.4, from
    expression option to arg_or_omitted. This does the reverse conversion.
*)

val register_uses :
  Lexing.position -> (Asttypes.arg_label * expression option) list -> unit
(** An optional argument is used if it is required match a signature, or if it
    is part of an application (w/ or w/o value) *)

val bind : Lexing.position -> Typedtree.expression -> unit
(** Bind the opt parameters of expr to the given position *)
