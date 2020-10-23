module CSDP

using LinearAlgebra # For Diagonal
using SparseArrays # For SparseMatrixCSC

if VERSION < v"1.3"
    if isfile(joinpath(dirname(@__FILE__),"..","deps","deps.jl"))
        include("../deps/deps.jl")
    else
        error("CSDP not properly installed. Please run Pkg.build(\"CSDP\")")
    end
else
    import CSDP_jll: libcsdp
end

# This is the size of int used by the LAPACK library used by CSDP.
# If libcsdp is patched to use a 64-bit integer LAPACK, this should be replaced by `Clong`.
const CSDP_INT = Cint

export Blockmatrix

include("blockdiag.jl")
include("blockmat.h.jl")
include("blockmat.jl")
include("declarations.h.jl")
include("declarations.jl")
include("debug-mat.jl")
include("options.jl")
include("MOI_wrapper.jl")

end # module
