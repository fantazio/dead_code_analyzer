module Values = Values
module Values_no_intf = Values_no_intf
module Values_in_submodules = Values_in_submodules
module Values_in_submodules_no_intf = Values_in_submodules_no_intf

let () =
  ignore Values.lib_internal_used;
  ignore Values.lib_internal_externally_used;
  ignore Values_no_intf.lib_internal_used;
  ignore Values_no_intf.lib_internal_externally_used;
  ignore Values_in_submodules.Exported.lib_internal_used;
  ignore Values_in_submodules.Exported.lib_internal_externally_used;
  ignore Values_in_submodules_no_intf.Exported.lib_internal_used;
  ignore Values_in_submodules_no_intf.Exported.lib_internal_externally_used
