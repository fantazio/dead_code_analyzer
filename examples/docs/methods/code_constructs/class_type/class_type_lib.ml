(* class_type_lib.ml *)
class type int_stack_t =
  object
    method push : int -> unit
    method pop : unit
    method peek : int option
    method reset : unit
  end

let int_stack_o =
  object
    val mutable l : int list = []
    method push x = l <- x::l
    method pop =
      match l with
      | [] -> ()
      | _::tl -> l <- tl
    method peek =
      match l with
      | [] -> None
      | hd::_ -> Some hd
    method reset = l <- []
  end

class int_stack_c =
  object
    val mutable l : int list = []
    method push x = l <- x::l
    method pop =
      match l with
      | [] -> ()
      | _::tl -> l <- tl
    method peek =
      match l with
      | [] -> None
      | hd::_ -> Some hd
    method reset = l <- []
  end
