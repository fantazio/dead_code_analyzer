# Table of contents

+ [Fields and constructors](#fields-and-constructors)
    + [Definitions](#definitions)
    + [Compiler warnings](#compiler-warnings)
        + [Warning 37: unused-constructor](#warning-37-unused-constructor)
        + [Warning 38: unused-extension](#warning-38-unused-extension)
        + [Warning 69: unused-field](#warning-69-unused-field)
    + [Usage](#usage)
+ [Examples](#examples)
+ [Limitations](#limitations)
    + [Polymorphic variant](#polymorphic-variant)
    + [Extensible variant](#extensible-variant)
    + [Inline record](#inline-record)
    + [Type equalities](#type-equalities)

# Fields and constructors

## Definitions

A **constructor** is a named value of a variant type.

A **field** is a named value inside a record type.

An **exported** constructor or field is one that is is declared in its
compilation unit's signature.

A **private** field or constructor is one in a private record or variant type.
A private type is declared using the `private` keyword.

A **use** is either :
- Applying a constructor.
  E.g.
  ```OCaml
  type side = Left | Right

  let make_left () = Left
  ```
  The constructor `Left` is applied in `make_left`.
- Reading a field.
  E.g.
  ```OCaml
  type point = {x : float; y : float}

  let get_x p = p.x
  ```
  The field `point.x` is read in `get_x`.

> [!IMPORTANT]
> A **use** is **not**:
> - De-structuring a constructor.
>   E.g.
>   ```OCaml
>   type side = Left | Right
>
>   let string_of_side = function
>     | Left -> "Left"
>     | Right -> "Right"
>   ```
>   Constructors `Left` and `Right` are matched on but never applied.
> - Writing to a field.
>   E.g.
>   ```OCaml
>   type point = {x : float; y : float}
>
>   let make_point x y = {x; y}
>   ```
>   The fields `point.x` and `point.y` are written but never read.

## Compiler warnings

The analyzer reports unused exported fields and constructors, while the compiler
reports unused unexported fields and constructors. They complement each other.
The compiler also warns on unused private constructors (but not private fields
since they can still be read). The analyzer's reports overlap with the compiler's
on unused exported private constructors.

> [!TIP]
> To obtain a list of available compiler warnings, use
> `ocamlopt -warn-help`

The compiler warnings related to unused fields and constructors are the 37, 38,
and 69.
The first one is for unexported constructors, the second for unexported fields.

### Warning 37: unused-constructor

This warning is disabled by default.
It can be enabled by passing the `-w +37` to the compiler.

Description:
```
37 [unused-constructor] Unused constructor. (since 4.00)
```

Example
```OCaml
(* warning37.mli *)
```
```OCaml
(* warning37.ml *)
type 'a opt = None | Some of 'a

let is_some = function
  | Some _ -> true
  | _ -> false
```
```
$ ocamlopt -w +37 warning37.mli warning37.ml
File "warning37.ml", line 2, characters 14-18:
2 | type 'a opt = None | Some of 'a
                  ^^^^
Warning 37 [unused-constructor]: unused constructor None.

File "warning37.ml", line 2, characters 19-31:
2 | type 'a opt = None | Some of 'a
                       ^^^^^^^^^^^^
Warning 37 [unused-constructor]: constructor Some is never used to build values.
(However, this constructor appears in patterns.)
```

### Warning 38: unused-extension

This warning is disabled by default.
It can be enabled by passing the `-w +38` to the compiler.

Description:
```
38 [unused-extension] Unused extension constructor. (since 4.00)
```

Example
```OCaml
(* warning38.mli *)
```
```OCaml
(* warning38.ml *)
type t = ..
type t +=
  | Int of int
  | Float of float

let is_int = function
  | Int _ -> true
  | _ -> false
```
```
$ ocamlopt -w +38 warning38.mli warning38.ml
File "warning38.ml", line 4, characters 2-14:
4 |   | Int of int
      ^^^^^^^^^^^^
Warning 38 [unused-extension]: extension constructor Int is never used to build values.
(However, this constructor appears in patterns.)

File "warning38.ml", line 5, characters 2-18:
5 |   | Float of float
      ^^^^^^^^^^^^^^^^
Warning 38 [unused-extension]: unused extension constructor Float
```

### Warning 69: unused-field

This warning is disabled by default.
It can be enabled by passing the `-w +69` to the compiler.

Description:
```
69 [unused-field] Unused record field. (since 4.13)
```

Example:
```OCaml
(* warning69.mli *)
```
```OCaml
(* warning69.ml *)
type point = {x : float; y : float}

let move_x p x = {p with x}
```
```
$ ocamlopt -w +69 warning69.mli warning69.ml
File "warning69.ml", line 2, characters 14-24:
2 | type point = {x : float; y : float}
                  ^^^^^^^^^^
Warning 69 [unused-field]: record field x is never read.
(However, this field is used to build or mutate values.)

File "warning69.ml", line 2, characters 25-34:
2 | type point = {x : float; y : float}
                             ^^^^^^^^^
Warning 69 [unused-field]: unused record field y.
```

## Usage

Unused exported fields and records are reported by default.
Their reports can be deactivated using the `--nothing` or `-T nothing`
command line arguments.
They can be reactivated by using the `--all` or `-T all` command line arguments.
For more details about the command line arguments see [the more general Usage
documentation](../USAGE.md).

The report section looks like:
```
.> UNUSED CONSTRUCTORS/RECORD FIELDS:
====================================
filepath:line: type.value

Nothing else to report in this section
--------------------------------------------------------------------------------
```
The report line format is `filepath:line: type.value` with `filepath` the absolute
path to the file (`.mli` if available, `.ml` otherwise) where `value` is
declared, `line` the line index in `filepath` at which `value` is declared,
`type` the path of the record or variant type within its compilation unit
(e.g. `M.t`) to which `value` belongs, and `value` the unused field or constructor.
There can be any number of such lines.

The expected resolution for an unused exported field or constructor is to remove
it from its type's definition.

> [!IMPORTANT]
> Removing unused fields or constructors may lead to compilation errors, because
> one had to write all the fields when building a record, and potentially match
> on the constructors.

# Examples

- The [code constructs](./code_constructs) directory contains a collection of
  examples dedicated to specific code constructs :
    - [Polymorphic type](./code_constructs/POLYMORPHIC_TYPE.md)
    - [Polymorphic variant](./code_constructs/POLYMORPHIC_VARIANT.md)
    - [GADT](./code_constructs/GADT.md)
    - [Extensible variant](./code_constructs/EXTENSIBLE_VARIANT.md)
    - [Inline record](./code_constructs/INLINE_RECORD.md)

# Limitations

## Polymorphic variant

The analyzer does not keep track of polymorphic variants, as explained in the
[Polymorphic variant](./code_constructs/POLYMORPHIC_VARIANT.md) example.

If you have a strong need/desire for this feature, please feel free to
[open an issue](https://github.com/LexiFi/dead_code_analyzer/issues/new)

## Extensible variant

The analyzer does not keep track of extensible variants, as explained in the
[Extensible variant](./code_constructs/EXTENSIBLE_VARIANT.md) example.

If you have a strong need/desire for this feature, please feel free to
[open an issue](https://github.com/LexiFi/dead_code_analyzer/issues/new)

## Inline record

The analyzer does not keep track of fields in inline records, as explained in
the [Inline record](./code_constructs/INLINE_RECORD.md) example

If you have a strong need/desire for this feature, please feel free to
[open an issue](https://github.com/LexiFi/dead_code_analyzer/issues/new)

## Type equalities

Related issues :
- [issue #79](https://github.com/LexiFi/dead_code_analyzer/issues/79);
- [issue #80](https://github.com/LexiFi/dead_code_analyzer/issues/80);
- [issue #81](https://github.com/LexiFi/dead_code_analyzer/issues/81);
- [issue #82](https://github.com/LexiFi/dead_code_analyzer/issues/82).

When defining a variant or record type, one can constrain it to be equal
to another in 2 different ways:
- via an explicit type equation (`type t1 = t2 = ...`);
- implicitly, when the type is defined without an explicit equation in the
  interface, whereas it is either explicited or implied by construction
  (e.g. through includes or module aliases) in the implementation.

Either way, the analyzer does not account for such equalities and analyzes
each type's components indepently. Thus, a use of a constructor or field in
`t1` is not considered as a use for that same component in `t2` (with
`t1 = t2`), and vice versa.
This leads to **false positives**.

### Example

The reference files for this example are in the
[equal\_types](../../examples/docs/fields_and_constructors/limitations/equal_types)
directory.

The reference takes place in `/tmp/docs/fields_and_constructors/limitations`,
which is a copy of the [limitations](../../../examples/docs/fields_and_constructors/limitations)
directory. Reported locations may differ depending on the location of the
source files.

The compilation command is :
```
make -C equal_types build
```

The analysis command is :
```
make -C equal_types analyze
```

The compile + analyze command is :
```
make -C equal_types
```

Code:
```OCaml
(* definitions.ml *)
type sum =
  | Used_by_explicit_equation
  | Used_by_hidden_equation
  | Used_by_include
  | Used_by_module_alias
  | Used_directly
  | Unused

type product = {
  used_by_explicit_equation : int;
  used_by_hidden_equation : int;
  used_by_include : int;
  used_by_module_alias : int;
  used_directly : int;
  unused : int;
}
```
These 2 types are re-exposed by 4 modules : `Via_explicit_equations`,
`Via_hidden_equations`, `Via_include`, and `Via_module_alias`. We will not
display all of their content here because they mostly consist in the
repetition of `Definitions`. Feel free to explore them.

`Via_explicit_equations` is defined within a single .ml and it uses the following constructs:
```OCaml
type sum = Definitions.sum = (* constructors *)
type product = Definitions.product = (* fields *)
```

`Via_hidden_equations` is implemented the same as `Via_explicit_equations`
in its .ml, and its .mli is the same as `Definitions`.

`Via_include` is implemented as below and its interface is the same as
`Definitions` :
```OCaml
(* via_include.ml *)
include Definitions
```

`Via_module_alias` is implented as below and its module `Alias` is defined
explicitly in the interface :
```OCaml
(* via_module_alias.ml *)
module Alias = Definitions
```

The different constructors and fields are used by `Equal_types`:
```OCaml
(* equal_types.ml *)
let _ =
  let open Definitions in
  fun {used_directly; _} -> Used_directly

let _ =
  let open Via_explicit_equations in
  fun {used_by_explicit_equation; _} -> Used_by_explicit_equation

let _ =
  let open Via_hidden_equations in
  fun {used_by_hidden_equation; _} -> Used_by_hidden_equation

let _ =
  let open Via_include in
  fun {used_by_include; _} -> Used_by_include

let _ =
  let open Via_module_alias.Alias in
  fun {used_by_module_alias; _} -> Used_by_module_alias
```

Compile and analyze:
```
$ make -C equal_types/
make: Entering directory '/tmp/docs/fields_and_constructors/limitations/equal_types'
ocamlopt -bin-annot definitions.ml via_explicit_equations.ml via_hidden_equations.mli via_hidden_equations.ml via_include.mli via_include.ml via_mod
ule_alias.mli via_module_alias.ml equal_types.ml
dead_code_analyzer --nothing -T all .
Scanning files...
 [DONE]

.> UNUSED CONSTRUCTORS/RECORD FIELDS:
====================================
/tmp/docs/fields_and_constructors/limitations/equal_types/definitions.ml:3: sum.Used_by_explicit_equation
/tmp/docs/fields_and_constructors/limitations/equal_types/definitions.ml:4: sum.Used_by_hidden_equation
/tmp/docs/fields_and_constructors/limitations/equal_types/definitions.ml:5: sum.Used_by_include
/tmp/docs/fields_and_constructors/limitations/equal_types/definitions.ml:6: sum.Used_by_module_alias
/tmp/docs/fields_and_constructors/limitations/equal_types/definitions.ml:8: sum.Unused
/tmp/docs/fields_and_constructors/limitations/equal_types/definitions.ml:11: product.used_by_explicit_equation
/tmp/docs/fields_and_constructors/limitations/equal_types/definitions.ml:12: product.used_by_hidden_equation
/tmp/docs/fields_and_constructors/limitations/equal_types/definitions.ml:13: product.used_by_include
/tmp/docs/fields_and_constructors/limitations/equal_types/definitions.ml:14: product.used_by_module_alias
/tmp/docs/fields_and_constructors/limitations/equal_types/definitions.ml:16: product.unused
/tmp/docs/fields_and_constructors/limitations/equal_types/via_hidden_equations.mli:3: sum.Used_by_explicit_equation
/tmp/docs/fields_and_constructors/limitations/equal_types/via_hidden_equations.mli:5: sum.Used_by_include
/tmp/docs/fields_and_constructors/limitations/equal_types/via_hidden_equations.mli:6: sum.Used_by_module_alias
/tmp/docs/fields_and_constructors/limitations/equal_types/via_hidden_equations.mli:7: sum.Used_directly
/tmp/docs/fields_and_constructors/limitations/equal_types/via_hidden_equations.mli:8: sum.Unused
/tmp/docs/fields_and_constructors/limitations/equal_types/via_hidden_equations.mli:11: product.used_by_explicit_equation
/tmp/docs/fields_and_constructors/limitations/equal_types/via_hidden_equations.mli:13: product.used_by_include
/tmp/docs/fields_and_constructors/limitations/equal_types/via_hidden_equations.mli:14: product.used_by_module_alias
/tmp/docs/fields_and_constructors/limitations/equal_types/via_hidden_equations.mli:15: product.used_directly
/tmp/docs/fields_and_constructors/limitations/equal_types/via_hidden_equations.mli:16: product.unused
/tmp/docs/fields_and_constructors/limitations/equal_types/via_include.mli:3: sum.Used_by_explicit_equation
/tmp/docs/fields_and_constructors/limitations/equal_types/via_include.mli:4: sum.Used_by_hidden_equation
/tmp/docs/fields_and_constructors/limitations/equal_types/via_include.mli:6: sum.Used_by_module_alias
/tmp/docs/fields_and_constructors/limitations/equal_types/via_include.mli:7: sum.Used_directly
/tmp/docs/fields_and_constructors/limitations/equal_types/via_include.mli:8: sum.Unused
/tmp/docs/fields_and_constructors/limitations/equal_types/via_include.mli:11: product.used_by_explicit_equation
/tmp/docs/fields_and_constructors/limitations/equal_types/via_include.mli:12: product.used_by_hidden_equation
/tmp/docs/fields_and_constructors/limitations/equal_types/via_include.mli:14: product.used_by_module_alias
/tmp/docs/fields_and_constructors/limitations/equal_types/via_include.mli:15: product.used_directly
/tmp/docs/fields_and_constructors/limitations/equal_types/via_include.mli:16: product.unused
/tmp/docs/fields_and_constructors/limitations/equal_types/via_module_alias.mli:4: Alias.sum.Used_by_explicit_equation
/tmp/docs/fields_and_constructors/limitations/equal_types/via_module_alias.mli:5: Alias.sum.Used_by_hidden_equation
/tmp/docs/fields_and_constructors/limitations/equal_types/via_module_alias.mli:6: Alias.sum.Used_by_include
/tmp/docs/fields_and_constructors/limitations/equal_types/via_module_alias.mli:8: Alias.sum.Used_directly
/tmp/docs/fields_and_constructors/limitations/equal_types/via_module_alias.mli:9: Alias.sum.Unused
/tmp/docs/fields_and_constructors/limitations/equal_types/via_module_alias.mli:12: Alias.product.used_by_explicit_equation
/tmp/docs/fields_and_constructors/limitations/equal_types/via_module_alias.mli:13: Alias.product.used_by_hidden_equation
/tmp/docs/fields_and_constructors/limitations/equal_types/via_module_alias.mli:14: Alias.product.used_by_include
/tmp/docs/fields_and_constructors/limitations/equal_types/via_module_alias.mli:16: Alias.product.used_directly
/tmp/docs/fields_and_constructors/limitations/equal_types/via_module_alias.mli:17: Alias.product.unused

Nothing else to report in this section
--------------------------------------------------------------------------------


make: Leaving directory '/tmp/docs/fields_and_constructors/limitations/equal_types'

```

As we can see, there are a lot of reports. Most of them are false positives:
for each type, components only used by other equal types are report unused.
I.e. only components used directly via a type is considered used for that
type.

Although the results are valid according to OCaml's typing (if there is no
type equation, the defined type is incompatible with any other type), they
are not actionable because one cannot remove a component without removing
it from all the other equal types.
In order to make the results actionable, one must be able to remove the
component from all the equal types. Thus, the expected results would only
consist of `sum.Unused`, and `product.unused`, either for each type or only
for `Definitions`' types.

> [!NOTE]
> The type components in `Via_explicit_equations` are not reported. This
> follows OCaml's typing, and is the expected behavior.
> > The optional type equation `= typexpr` makes the defined type equivalent
> > to the type expression `typexpr`: one can be substituted for the other
> > during typing.
>
> There are no false negatives.
