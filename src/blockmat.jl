# Data types declared in `include/blockmat.h`
# Small type names are the C types
# Capitalized are the corresponding Julia types

brec(b::Vector{Cdouble}, cat::UInt32, l::Int) =
    blockrec(blockdatarec(Ref(b)), cat, Cint(l))
brec(b::Matrix{Float64}) =
    brec(b[:], MATRIX, length(b))
brec(b::Diagonal{Float64}) = 
    brec(b[:], DIAG, length(b))

typealias BMat Union{Matrix{Float64},Diagonal{Float64}}

type Blockmatrix
    blocks::Vector{blockrec}
    Blockmatrix(bs::BMat...) =
        new([brec(b) for b in bs])
end
