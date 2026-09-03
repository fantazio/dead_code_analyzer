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
