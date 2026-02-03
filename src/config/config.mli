(** Configuration of the analyzer *)

(** {2 Sections configuration} *)

type 'threshold section =
  | Off (** Disabled *)
  | On (** Enabled *)
  | Threshold of 'threshold threshold_section (** Enabled with threshold *)

and 'threshold threshold_section =
  { threshold: 'threshold
    (** Report subsections for elements used up to [!threshold] *)
  ; call_sites: bool (** Print call sites in the [!threshold]-related subsections *)
  }

val is_activated : _ section -> bool
(** [is_activated sec] returns `true` if the section must be reported *)

val has_activated : _ section list -> bool
(** [has_activated secs] returns `true` if one of the sections must be reported *)

val call_sites_activated : _ section -> bool
(** [call_sites_activated sec] returns `true` if call sites must be reported in
    thresholded subsections *)

(** {3 Main sections} *)

type main_section = int section

val update_main : string -> main_section ref -> string -> unit
(** [update_basic sec_arg section arg] updates the configuration of [section] according
    to the [arg] specification. [sec_arg] is the command line argument
    associated with the [section] *)

val get_main_threshold : int section -> int
(** [get_main_threshold main_sec] returns the threshold if
    [main_sec = Threshold _], [0] otherwise. *)

(** {3 Optional argument sections} *)

type opt_threshold =
  | Percent of float
      (** Subsections for opt args always/never used at least [float] percent of
      the time will be reported *)
  | Both of (int * float)
      (** Subsections for opt args always/never used with at most [int]
          exceptions and at least [float] percent of the time will be reported *)

type opt_section = opt_threshold section

val update_opt : opt_section ref -> string -> unit
(** [update_opt section arg] updates the configuration of [section] according
    to the [arg] specification *)

(** {3 Stylistic issues section} *)

type style =
  { opt_arg: bool (** Report [val f : _ -> (... -> (... -> ?_:_ -> ...) -> ...] *)
  ; unit_pat: bool (** Report unit pattern *)
  ; seq: bool (** Report [let () = ... in ... (=> use sequence)] *)
  ; binding: bool (** Report [let x = ... in x (=> useless binding)] *)
  }


val update_style : string -> unit
(** [update_style arg] updates [!style] according to the [arg] specification *)

(** {2 General configuration} *)

type t =
  { mutable verbose : bool (** Display additional information during the analaysis *)
  ; mutable internal : bool (** Keep track of internal uses for exported values *)
  ; mutable underscore : bool (** Keep track of elements with names starting with [_] *)
  ; mutable directories : string list (** Paths to explore for references only *)
  ; exported : main_section ref (** Configuration for the unused exported values *)
  ; obj : main_section ref (** Configuration for the methods *)
  ; typ : main_section ref (** Configuration for the constructors/record fields *)
  ; opta : opt_section ref (** Configuration for the optional arguments always used *)
  ; optn : opt_section ref (** Configuration for the optional arguments never used *)
  ; style : style ref (** Configuration for the stylistic issues *)
  }

val config : t
(** Configuration for the analysis.
    By default [verbose], [internal], and [underscore] are [false]
    By default [exported],  [obj], and [typ] are [On].
    By default [opta], [optn] are [Off].
    By default all of the fileds in [style] are false. *)

val set_verbose : unit -> unit
(** Set [verbose] to [true] *)

val set_underscore : unit -> unit
(** Set [underscore] to [true] *)

val set_internal : unit -> unit
(** Set [internal] to [true] *)

val exclude : string -> unit
(** [exclude path] excludse [path] from the analysis *)

val is_excluded : string -> bool
(** [is_excluded path] indicates if [path] is excluded from the analysis.
    Excluding a path is done with [exclude path]. *)

val parse_cli : (string -> unit)  -> unit
(** [parse_cli process_path] updates the [config] according to the command line
    arguments and processes each input path using [process_path] *)
