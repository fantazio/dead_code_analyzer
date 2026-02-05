(** Configuration of the analyzer *)

(** {2 Sections configuration} *)

module Sections = Sections

val is_activated : _ Sections.section -> bool
(** [is_activated sec] returns `true` if the section must be reported *)

val call_sites_activated : _ Sections.section -> bool
(** [call_sites_activated sec] returns `true` if call sites must be reported in
    thresholded subsections *)

val get_main_threshold : Sections.main_section -> int
(** [get_main_threshold main_sec] returns the threshold if
    [main_sec = Threshold _], [0] otherwise. *)

(** {2 General configuration} *)

module StringSet : Set.S with type elt = String.t

type t =
  { verbose : bool (** Display additional information during the analaysis *)
  ; internal : bool (** Keep track of internal uses for exported values *)
  ; underscore : bool (** Keep track of elements with names starting with [_] *)
  ; paths_to_analyze : StringSet.t
      (** Paths found in the command line and considered for analysis *)
  ; excluded_paths : StringSet.t
      (** Paths to exclude from the analysis *)
  ; references_paths : StringSet.t (** Paths to explore for references only *)
  ; sections : Sections.t (** Config for the different report sections *)
  }

val default_config : t
(** Configuration for the analysis.
    By default [verbose], [internal], and [underscore] are [false]
    By default [sections] is [Sections.default] *)

val has_main_section_activated : t -> bool
(** [has_main_section_activated config] indicates if any of the main sections
    is activated in [config] *)

val has_opt_args_section_activated : t -> bool
(** [has_opt_args_section_activated config] indicates if any of the optional
    arguments section is activated in [config] *)

val update_style : string -> t -> t
(** [update_style arg config] returns a [config] with [style] updated according
    to the [arg] specification. *)

val is_excluded : string -> t -> bool
(** [is_excluded path config] indicates if [path] is excluded from the analysis
    in [config].
    Excluding a path is done with the --exclude command line argument. *)

val parse_cli : unit -> t
(** [parse_cli ()] returns a fresh configuration filled up according to the
    command line arguments *)
