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

type SparseBlock
    i::Vector{Cint}
    j::Vector{Cint}
    v::Vector{Cdouble}
end

type SparseBlockMatrix
    blocks::Vector{SparseBlock}
    SparseBlockMatrix(bs::AbstractMatrix...) =
        new(SparseBlock[b for b in bs])
end


function Base.convert(::Type{SparseBlock}, A::AbstractMatrix)
    A = map(Cdouble, A)
    C = SparseMatrixCSC{Cdouble, Cint}(A)
    nn = nnz(C)
    I = Array(Cint, nn+1)
    J = Array(Cint, nn+1)
    V = nonzeros(C)
    rows = rowvals(C)
    m, n = size(C)
    k = 1 # number of written elements
    I[1] = 0
    J[1] = 0
    for col = 1:n
        for j in nzrange(C, col)
            k += 1
            row = rows[j]
            I[k] = row
            J[k] = col
        end
    end
    SparseBlock(I,J,V)
end


function Base.convert(::Type{constraintmatrix}, c::SparseBlockMatrix)
    numblocks = length(c.blocks)
end


# function Base.convert(::{sparse

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
