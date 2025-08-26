(***************************************************************************)
(*                                                                         *)
(*   Copyright (c) 2014-2025 LexiFi SAS. All rights reserved.              *)
(*                                                                         *)
(*   This source code is licensed under the MIT License                    *)
(*   found in the LICENSE file at the root of this source tree             *)
(*                                                                         *)
(***************************************************************************)

open Typedtree

(* Functions deferred to run at the end of the current file's analysis.
 * They reaqire the analysis of future locations in the current file.
 * It is known that these locations will have been processed at the end
 * of the binding.
 * Needed because the Tast_mapper runs through sequences from the end
 * because tuples are built from right to left. *)
val at_eof : (unit -> unit) list ref

(* Functions deferred to run at the end of the analysis, before reporting.
 * They require the analysis of future locations out of the current file.
 * at_eocb = at end of code base. *)
val at_eocb : (unit -> unit) list ref

(* For use at the end of an interface:
 * apply `at_eof` functions + reset state *)
val eof : unit -> unit

(* Register all optional arguments uses.
 * if they are used to match a signature or the location
 * is not a ghost and they are part of the application (w/ or w/o value) *)
val register_uses :
  Lexing.position -> (Asttypes.arg_label * expression option) list -> unit

(* Link the opt parameters of expr to the given position *)
val bind : Lexing.position -> Typedtree.expression -> unit
