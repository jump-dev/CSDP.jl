# Copyright (c) 2016: CSDP.jl contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

module CSDP

import CSDP_jll

function __init__()
    global libcsdp = CSDP_jll.libcsdp
    return
end

# This is the size of int used by the LAPACK library used by CSDP.
# If libcsdp is patched to use a 64-bit integer LAPACK, this should be replaced
# by `Clong`.
const CSDP_INT = Cint

"""
    offset(x::Vector)

CSDP uses 1-based indexing for its arrays. But since C has 0-based indexing, all
1-based vectors passed to CSDP need to be padded with a "0'th" element that will
never be accessed.
"""
offset(x::Vector{T}) where {T} = pointer(x) - sizeof(T)

include("c_api.jl")
include("MOI_wrapper.jl")
include("simple_api.jl")

end # module
