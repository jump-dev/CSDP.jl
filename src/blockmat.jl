# Data types declared in `include/blockmat.h`
# Small type names are the C types
# Capitalized are the corresponding Julia types

brec(b::Vector{Cdouble}, cat::UInt32, l::Int) =
    blockrec(blockdatarec(Ref(b)), cat, Cint(l))
brec(b::Matrix{Float64}) =
    brec(b[:], MATRIX, length(b))
brec(b::Diagonal{Float64}) = 
    brec(b[:], DIAG, length(b))

typealias BMat{T} Union{Matrix{T},Diagonal{T}}

type Blockmatrix
    blocks::Vector{blockrec}
    Blockmatrix{T<:Number}(bs::BMat{T}...) =
        new([brec(map(Float64, b)) for b in bs])
end
