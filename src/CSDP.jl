module CSDP

import Base.LinAlg.BlasInt
export BlasInt

# Try to load the binary dependency
if isfile(joinpath(dirname(@__FILE__),"..","deps","deps.jl"))
    include("../deps/deps.jl")
else
    error("CSDP not properly installed. Please run Pkg.build(\"CSDP\")")
end

export Blockmatrix

include("blockmat.h.jl")
include("blockmat.jl")
include("declarations.h.jl")
include("declarations.jl")
include("debug-mat.jl")

end # module
