module Unexported = struct
  let used = 42
  let unused = 42
end

module Exported = struct
  module Private = struct
    let used = 42
    let unused = 42
  end

  let used = 42
  let used_by_API = 42
  let internally_used = 42
  let externally_used = 42

  let lib_internal_used = 42
  let lib_internal_unused = 42
  let lib_internal_internally_used = 42
  let lib_internal_externally_used = 42

end

let () = ignore Unexported.used

let () = ignore Exported.Private.used

let () =
  ignore Exported.used;
  ignore Exported.internally_used

let () =
  ignore Exported.lib_internal_used;
  ignore Exported.lib_internal_internally_used
