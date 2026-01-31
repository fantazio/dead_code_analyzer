(* extenal uses with explicit module *)
let () =
  ignore Reduced_lib.Values_no_intf.used;
  ignore Reduced_lib.Values_no_intf.externally_used

let is_used = ref false
let mark_used () =
  is_used := true
