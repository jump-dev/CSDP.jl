# Copyright (c) 2016: CSDP.jl contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

module CSDP

import LinearAlgebra
import SparseArrays

import CSDP_jll

function __init__()
    global libcsdp = CSDP_jll.libcsdp
    return
end

# This is the size of int used by the LAPACK library used by CSDP.
# If libcsdp is patched to use a 64-bit integer LAPACK, this should be replaced
# by `Clong`.
const CSDP_INT = Cint

export BlockMastrix

include("blockdiag.jl")
include("blockmat.h.jl")
include("blockmat.jl")
include("declarations.h.jl")
include("declarations.jl")
include("options.jl")
include("MOI_wrapper.jl")

end # module
