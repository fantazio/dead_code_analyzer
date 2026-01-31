let used = 42
let used_by_API = 42
let internally_used = 42
let externally_used = 42

let () =
  ignore used;
  ignore internally_used

let lib_internal_used = 42
let lib_internal_unused = 42
let lib_internal_internally_used = 42
let lib_internal_externally_used = 42

let () =
  ignore lib_internal_used;
  ignore lib_internal_internally_used
