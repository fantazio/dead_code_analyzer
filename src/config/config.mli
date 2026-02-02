(** Configuration of the analyzer *)

(** {2 Sections configuration} *)

(** {3 Main sections} *)

type basic =
  { print: bool (** Report section *)
  ; threshold: int
    (** Report subsections for elements used up to [!threshold] *)
  ; call_sites: bool (** Print call sites in the [!threshold]-related subsections *)
  }

val exported : basic ref
(** Configuration for the unused exported values *)

val obj : basic ref
(** Configuration for the methods *)

val typ : basic ref
(** Configuration for the constructors/record fields *)

val update_basic : string -> basic ref -> string -> unit
(** [update_basic sec_arg section arg] updates the configuration of [section] according
    to the [arg] specification. [sec_arg] is the command line argument
    associated with the [section] *)

(** {3 Optional argument sections} *)

type threshold =
  { percentage: float
      (** Subsections for opt args always/never used except at most
          [percentage] of the time will be reported *)
  ; exceptions: int
      (** Only optional arguments always/never used except at most
          [exceptions] times will be reported in the subsections *)
  ; optional: [`Percent | `Both] (** Threshold mode *)
  }

type opt =
  { print: bool (** Report section *)
  ; threshold: threshold
    (** Report subsections for opt args always/never used up to [!threshold] *)
  ; call_sites: bool (** Print call sites in the [!threshold]-related subsections *)
  }

val opta : opt ref
(** Configuration for the optional arguments always used *)

val optn : opt ref
(** Configuration for the optional arguments never used *)

val update_opt : opt ref -> string -> unit
(** [update_opt section arg] updates the configuration of [section] according
    to the [arg] specification *)

(** {3 Stylistic issues section} *)

type style =
  { opt_arg: bool (** Report [val f : _ -> (... -> (... -> ?_:_ -> ...) -> ...] *)
  ; unit_pat: bool (** Report unit pattern *)
  ; seq: bool (** Report [let () = ... in ... (=> use sequence)] *)
  ; binding: bool (** Report [let x = ... in x (=> useless binding)] *)
  }

val style : style ref
(** Configuration for the stylistic issues *)

val update_style : string -> unit
(** [update_style arg] updates [!style] according to the [arg] specification *)

(** {2 General configuration} *)

val verbose : bool ref
(** Display additional information during the analaysis. [false] by default. *)

val set_verbose : unit -> unit
(** Set [verbose] to [true] *)

val underscore : bool ref
(** Keep track of elements with names starting with [_]. [false] by default. *)

val set_underscore : unit -> unit
(** Set [underscore] to [true] *)

val internal : bool ref
(** Keep track of internal uses for exported values. [false] by default. *)

val set_internal : unit -> unit
(** Set [internal] to [true] *)

val exclude : string -> unit
(** [exclude path] excludse [path] from the analysis *)

val is_excluded : string -> bool
(** [is_excluded path] indicates if [path] is excluded from the analysis.
    Excluding a path is done with [exclude path]. *)

val directories : string list ref
(** Paths to explore for references only *)
