(* class_type_lib.mli *)
class type int_stack_t =
  object
    method push : int -> unit
    method pop : unit
    method peek : int option
    method reset : unit
  end

val int_stack_o : int_stack_t

class int_stack_c : int_stack_t
