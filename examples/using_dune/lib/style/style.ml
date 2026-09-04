let all =
  let unit_binding = () in
  let expect_opt_arg_in_arg (f : ?opt:'a -> unit -> unit) = f () in
  let () (* sequence *) = ignore expect_opt_arg_in_arg in
  let useless_binding = 42 in
  useless_binding

(* more useless bindings *)

let _ =
  let constrained_useless_binding : int = 42 in
  (* This is translated as
     let ((_ : int) as constrained_useless_binding) = ...
     from OCaml 5.1 to 5.4 *)
  constrained_useless_binding

let _ =
  let (constrained_useless_binding : int) = 42 in
  (* This is translated as
     let ((_ : int) as constrained_useless_binding) = ...
     OCaml <= 5.4 *)
  constrained_useless_binding

(* more opt arg in arg *)

let _ =
  let multiline_opt_arg_in_arg a b (* unused params *)
      (f : ?opt:'a -> unit -> unit) =
    f ()
  in
  let opt_arg_in_opt_arg_sig ?(f: (?opt:'a -> unit -> unit) option) () =
    match f with
    | Some f -> f ()
    | None -> ()
  in
  let opt_arg_in_opt_arg_val ?(f=fun ?opt () -> ()) () = f () in
  let multiline_implicit_opt_arg_in_arg a b
      f =
    multiline_opt_arg_in_arg a b f
  in
  let implicit_opt_arg_in_opt_arg ?f () =
    match f with
    | Some f -> multiline_opt_arg_in_arg () () f
    | None -> ()
  in
  let multiline_implicit_opt_arg_in_arg a b ?(opt = None)
      f =
    multiline_opt_arg_in_arg a b f
  in
  ()

(* more unit bindings *)

let _ =
  let constrained_unit_binding : unit = () in
  (* This is translated as
     let ((_ : int) as constrained_unit_binding) = ...
     from OCaml 5.1 to 5.4 *)
  let (constrained_unit_binding : unit) = () in
  (* This is translated as
     let ((_ : int) as constrained_unit_binding) = ...
     OCaml <= 5.4 *)
  let f (param : unit) = () in
  let _underscore_unit_binding = () in
  let (_underscore_constrained_unit_binding : unit) = () in
  let f (_underscore_param : unit) = () in
  ()
