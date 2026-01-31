module Values : sig
  val used : int
  val used_by_API : int
  val internally_used : int
  val externally_used : int
end

module Values_no_intf : sig
  val used : int
  val used_by_API : int
  val internally_used : int
  val externally_used : int
end

module Values_in_submodules : sig
  module Exported : sig
    val used : int
    val used_by_API : int
    val internally_used : int
    val externally_used : int
  end
end

module Values_in_submodules_no_intf : sig
  module Exported : sig
    val used : int
    val used_by_API : int
    val internally_used : int
    val externally_used : int
  end
end
