type t = private
  { exported_values : main_section (** Exported values section config *)
  ; methods : main_section (** Methods section config *)
  ; types : main_section (** Constructors/fields section config *)
  ; opta : opt_args_section (** Opt args always used section config *)
  ; optn : opt_args_section (** Opt args always used section config *)
  ; style : style_section (** Stylistic issues section config *)
  }

and main_section = int section

and opt_args_section = opt_args_threshold section
and opt_args_threshold =
  | Percent of float
      (** Subsections for opt args always/never used at least [float] percent of
      the time will be reported *)
  | Both of (int * float)
      (** Subsections for opt args always/never used with at most [int]
          exceptions and at least [float] percent of the time will be reported *)

and 'threshold section =
  | Off (** Disabled *)
  | On (** Enabled *)
  | Threshold of 'threshold thresholded_section
      (** Report elements up to [!'threshold] *)

and 'threshold thresholded_section =
  { threshold: 'threshold
      (** Report subsections for elements used up to [!threshold] *)
  ; call_sites: bool
      (** Print call sites in the [!threshold]-related subsections *)
  }

and style_section =
  { opt_arg: bool (** Report [val f : _ -> (... -> (... -> ?_:_ -> ...) -> ...] *)
  ; unit_pat: bool (** Report unit pattern *)
  ; seq: bool (** Report [let () = ... in ... (=> use sequence)] *)
  ; binding: bool (** Report [let x = ... in x (=> useless binding)] *)
  }

val default : t
(** Default sections configuration.
    [exported],  [obj], and [typ] are [On].
    [opta], [optn] are [Off].
    All of the fileds in [style] are false. *)

val is_activated : _ section -> bool
(** [is_activated sec] returns `true` if the section must be reported *)

val has_activated : _ section list -> bool
(** [has_activated secs] returns `true` if one of the sections must be reported *)

val call_sites_activated : _ section -> bool
(** [call_sites_activated sec] returns `true` if call sites must be reported in
    thresholded subsections *)


val get_main_threshold : int section -> int
(** [get_main_threshold main_sec] returns the threshold if
    [main_sec = Threshold _], [0] otherwise. *)


val update_exported_values : string -> t -> t
(** [update_exported_values arg sections] configures the [exported_values]
    section according to [arg] and returns an updated version of [sections].
    [arg]'s specification is the one for the command line option "-E" *)

val update_methods : string -> t -> t
(** [update_exported_values arg sections] configures the [exported_values]
    section according to [arg] and returns an updated version of [sections]
    [arg]'s specification is the one for the command line option "-M" *)

val update_types : string -> t -> t
(** [update_exported_values arg sections] configures the [exported_values]
    section according to [arg] and returns an updated version of [sections]
    [arg]'s specification is the one for the command line option "-T" *)

val update_opta : string -> t -> t
(** [update_exported_values arg sections] configures the [exported_values]
    section according to [arg] and returns an updated version of [sections]
    [arg]'s specification is the one for the command line option "-Oa" *)

val update_optn : string -> t -> t
(** [update_exported_values arg sections] configures the [exported_values]
    section according to [arg] and returns an updated version of [sections]
    [arg]'s specification is the one for the command line option "-On" *)

val update_style : string -> t -> t
(** [update_exported_values arg sections] configures the [exported_values]
    section according to [arg] and returns an updated version of [sections]
    [arg]'s specification is the one for the command line option "-S" *)
