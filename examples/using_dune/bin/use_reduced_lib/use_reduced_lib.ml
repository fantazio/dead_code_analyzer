let () =
  Use_values.mark_used ();
  Use_values_no_intf.mark_used ();
  Use_values_in_submodules.mark_used ();
  Use_values_in_submodules_no_intf.mark_used ()

let is_used = ref false
let mark_used () =
  is_used := true
