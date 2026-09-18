The reference files for this example are in the
[class\_type](../../../examples/docs/methods/code_constructs/class_type) directory.

The reference takes place in `/tmp/docs/methods/code_constructs`, which
is a copy of the [code\_constructs](../../../examples/docs/methods/code_constructs)
directory. Reported locations may differ depending on the location of the source
files.

The compilation command is :
```
make -C class_type build
```

The analysis command is :
```
make -C class_type analyze
```

The compile + analyze command is :
```
make -C class_type
```

> [!IMPORTANT]
> **LIMITATION**
>
> Methods declared in class types definition (different from class signatures)
> are currently ignored by the analyzer.

## First run

Code:
```OCaml
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
```
```OCaml
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
```
```OCaml
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
```

By looking at the code, we could make the same observation as in the
[Class](./CLASS.md) and [Immediate Object](./IMMEDIATE_OBJECT.md) examples.

However, because of the current limitation on class types, nothing is expected
to reported.

Code and analyze:
```
$ make -C class_type
make: Entering directory '/tmp/docs/methods/code_construct/class_type'
ocamlopt -bin-annot class_type_lib.mli class_type_lib.ml class_type_bin.ml
dead_code_analyzer --nothing -M all .
Scanning files...
 [DONE]

.> UNUSED METHODS:
=================

Nothing else to report in this section
--------------------------------------------------------------------------------


make: Leaving directory '/tmp/docs/methods/code_construct/class_type'
```

Nothing is reported. Our work here is done.
