(* class_type_bin.ml *)
class type unused_class_type = object method unused_method : unit end

let push_n_times n stack =
  for i = 1 to n do
    stack#push i;
  done

(* test immediate object *)
let () =
  let open Class_type_lib in
  let n = 42 in
  push_n_times n int_stack_o;
  while int_stack_o#peek <> None do
    int_stack_o#pop;
  done

(* test class *)
let () =
  let open Class_type_lib in
  let n = 42 in
  let int_stack = new int_stack_c in
  push_n_times n int_stack;
  while int_stack#peek <> None do
    int_stack#pop;
  done
