(* extenal uses with explicit module *)
let () =
  ignore Reduced_lib.Values_in_submodules_no_intf.Exported.used;
  ignore Reduced_lib.Values_in_submodules_no_intf.Exported.externally_used

let is_used = ref false
let mark_used () =
  is_used := true
