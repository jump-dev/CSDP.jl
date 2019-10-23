module CSDP

using LinearAlgebra # For Diagonal
using SparseArrays # For SparseMatrixCSC

# Try to load the binary dependency
if isfile(joinpath(dirname(@__FILE__),"..","deps","deps.jl"))
    include("../deps/deps.jl")
else
    error("CSDP not properly installed. Please run Pkg.build(\"CSDP\")")
end

export Blockmatrix

include("blockdiag.jl")
include("blockmat.h.jl")
include("blockmat.jl")
include("declarations.h.jl")
include("declarations.jl")
include("debug-mat.jl")
include("options.jl")
include("MOI_wrapper.jl")
include("MPB_wrapper.jl")

end # module
