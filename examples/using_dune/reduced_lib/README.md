This library is used to test 2 things :
1. That values defined in the library's submodules and not exposed in the
   library's API are tracked correctly and reported at locations in
   the submodules
2. That values defined in the library's submodules and those exposed in the
   library's API are "decoupled" :
    - If a value is unused outside the library, then it is reported at a
      location in the library's interface (and not the submodule's).
    - The submodules' values are "used by the type" of the library. I.e. because
      the library expose them in its API, then they must exist in the
      submodules. Thus, they are used by the API's requirements and must not be
      reported as unused.

The intent is to avoid duplicated reports and provide actually actionable
results.
E.g. Instead of
```
some_lib.mli:12: Foo.x
foo.mli:3: x
```
only report
```
some_lib.mli:12: Foo.x
```
Once `Some_lib.Foo.x` is removed from `Some_lib`'s API, a new run of the
`dead_code_analyzer` would be able to report
```
foo.mli:3: x
```

In this library's submodules, the values prefixed by `lib_internal` are not
exposed by the API but still exported by the submodules. All the other exported
values are re-exposed in `Reduced_lib`'s API.
