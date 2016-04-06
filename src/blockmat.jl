# Data types declared in `include/blockmat.h`
# Small type names are the C types
# Capitalized are the corresponding Julia types
using Base.convert

brec(b::Vector{Cdouble}, cat::blockcat, l::Int) =
    blockrec(blockdatarec(pointer(b)), cat, Cint(l))
brec(b::Matrix{Float64}) =
    brec(reshape(b, length(b)), MATRIX, length(b))
brec(b::Diagonal{Float64}) = 
    brec([0; diag(b)], DIAG, length(b))

type Blockmatrix
    blocks::Vector{blockrec}
    Blockmatrix(bs::AbstractMatrix...) =
        new([brec(map(Float64, b)) for b in [Matrix[]; collect(bs)]])
    Blockmatrix() = new([])
end

Base.convert(::Type{blockmatrix}, b::Blockmatrix) =
    blockmatrix(length(b.blocks)-1, pointer(b.blocks))

# TODO: Print-Function for Blockmatrix

# use pointer_from_obj to construct sparseblocks

typealias SparseBlock SparseMatrixCSC{Cdouble,Cint}

type SparseBlockMatrix
    blocks::Vector{SparseBlock}
    function SparseBlockMatrix(bs::AbstractMatrix...)
        bs = SparseBlock[map(Float64, b) for b in bs]
        unshift!(bs, sparse([]))
        new(bs)
    end
end

export SparseBlockMatrix, blockmatrix, convert

"""Solver status"""
type Csdp
    n::Cint
    k::Cint
    X::Blockmatrix
    y::Vector{Cdouble}
    constant_offset::Cdouble
    constraints::Vector{SparseBlock}
    pobj::Cdouble
    dobj::Cdouble
end
