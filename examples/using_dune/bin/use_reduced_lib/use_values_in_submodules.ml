(* extenal uses with explicit module *)
let () =
  ignore Reduced_lib.Values_in_submodules.Exported.used;
  ignore Reduced_lib.Values_in_submodules.Exported.externally_used

let is_used = ref false
let mark_used () =
  is_used := true
