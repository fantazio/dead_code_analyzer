(** Configuration of the analyzer *)

(** {2 Sections configuration} *)

module Sections = Sections

val is_activated : _ Sections.section -> bool
(** [is_activated sec] returns `true` if the section must be reported *)

val has_main_section_activated : unit -> bool
(** [has_main_section_activated ()] indicates if any of the main sections must
    be reported *)

val has_opt_args_section_activated : unit -> bool
(** [has_opt_args_section_activated ()] indicates if any of the optional
    arguments section must be reported *)

val call_sites_activated : _ Sections.section -> bool
(** [call_sites_activated sec] returns `true` if call sites must be reported in
    thresholded subsections *)

val get_main_threshold : int Sections.section -> int
(** [get_main_threshold main_sec] returns the threshold if
    [main_sec = Threshold _], [0] otherwise. *)

val update_style : string -> unit
(** [update_style arg] updates [!style] according to the [arg] specification *)

(** {2 General configuration} *)

type t =
  { verbose : bool (** Display additional information during the analaysis *)
  ; internal : bool (** Keep track of internal uses for exported values *)
  ; underscore : bool (** Keep track of elements with names starting with [_] *)
  ; directories : string list (** Paths to explore for references only *)
  ; sections : Sections.t (** Config for the different report sections *)
  }

val config : t ref
(** Configuration for the analysis.
    By default [verbose], [internal], and [underscore] are [false]
    By default [sections] is [Sections.default] *)

val is_excluded : string -> bool
(** [is_excluded path] indicates if [path] is excluded from the analysis.
    Excluding a path is done with [exclude path]. *)

val parse_cli : (string -> unit)  -> unit
(** [parse_cli process_path] updates the [config] according to the command line
    arguments and processes each input path using [process_path] *)
