(* extenal uses with explicit module *)
let () =
  ignore Reduced_lib.Values.used;
  ignore Reduced_lib.Values.externally_used

let is_used = ref false
let mark_used () =
  is_used := true
