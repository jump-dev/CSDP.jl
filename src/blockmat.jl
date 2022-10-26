# Copyright (c) 2016: CSDP.jl contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

# Data types declared in `include/blockmat.h`
# Small type names are the C types
# Capitalized are the corresponding Julia types

# Utils

function fptr(x::Vector{T}) where {T}
    # CSDP starts indexing at 1 so we need to do "- sizeof(T)"
    return pointer(x) - sizeof(T)
end

function ptr(x::X) where {X}
    return Base.reinterpret(Base.Ptr{X}, Base.pointer_from_objref(x))
end
export fptr, ptr

function mywrap(X::blockmatrix)
    return BlockMatrix(X)
end

function _unsafe_wrap(A, x, n, own::Bool)
    return Base.unsafe_wrap(A, x, n, own = own)
end

function mywrap(x::Ptr{T}, len) where {T}
    # I give false to unsafe_wrap to specify that Julia do not own the array so it should not free it
    # because the pointer it has has an offset
    y = _unsafe_wrap(Array, x + sizeof(T), len, false)
    # fptr takes care of this offset
    #finalizer(s -> Libc.free(fptr(s)), y)
    return y
end

# The problem is
# max ⟨C, X⟩
#   ⟨A_i, X⟩ = b_i  ∀ i
#         X  ⪰ 0

# CSDP does not have any C functions manipulate the values of the structures
# so we need to create the structures in Julia.
# Since the arrays are stored in Julia, we need to make sure they are not garbage collected
# so we put both the C structure (named csdp) and the allocated arrays in a wrapper with the same name as the C structure but capitalized

# In CSDP, the matrix C is represented as a blockmatrix
# which is a block diagonal matrix where each block is a symmetric dense (or diagonal) matrix of Cdouble
# * blockdatarec contains a vector containing the values (Cdouble) (1-indexed)
# * blockrec contains the blockdatarec, the category (dense or diagonal), and the block size
# * blockmatrix contains the number of blocks and a vector containing the blocks (blockrec) (1-indexed)

# blockrec
mutable struct BlockRec <: AbstractMatrix{Cdouble}
    _blockdatarec::Vector{Cdouble}
    csdp::blockrec
end
function BlockRec(a::Vector{Cdouble}, n::Int)
    if n > 0
        # /!\ the matrix is 0-indexed -> pointer
        BlockRec(a, blockrec(blockdatarec(pointer(a)), MATRIX, csdpshort(n)))
    else
        # /!\ the diagonal matrix is 1-indexed -> fptr
        BlockRec(a, blockrec(blockdatarec(fptr(a)), DIAG, csdpshort(-n)))
    end
end
BlockRec(a::Vector, n::Int) = BlockRec(Vector{Cdouble}(a), n)
function BlockRec(A::Matrix)
    return BlockRec(reshape(A, length(A)), LinearAlgebra.checksquare(A))
end
function BlockRec(A::LinearAlgebra.Diagonal)
    a = Vector{Cdouble}(LinearAlgebra.diag(A))
    return BlockRec(a, -length(a))
end

function Base.size(A::blockrec)
    n = A.blocksize
    return (n, n)
end
Base.size(A::BlockRec) = size(A.csdp)
function Base.getindex(A::BlockRec, i, j)
    n = A.csdp.blocksize
    if A.csdp.blockcategory == MATRIX
        A._blockdatarec[i+(j-1)*n]
    else
        @assert A.csdp.blockcategory == DIAG
        if i == j
            A._blockdatarec[i]
        else
            0
        end
    end
end

# blockmatrix
mutable struct BlockMatrix <: AbstractBlockMatrix{Cdouble}
    jblocks::Vector{BlockRec}
    blocks::Vector{blockrec}
    csdp::blockmatrix
end

function BlockMatrix(jblocks::AbstractVector{BlockRec})
    blocks = map(block -> block.csdp, jblocks)
    csdp = blockmatrix(length(blocks), fptr(blocks))
    return BlockMatrix(jblocks, blocks, csdp)
end
BlockMatrix(As::AbstractVector) = BlockMatrix(map(BlockRec, As))
BlockMatrix(As::AbstractMatrix...) = BlockMatrix(collect(As))

function BlockMatrix(csdp::blockmatrix)
    # I give false so that Julia does not try to free it
    blocks =
        _unsafe_wrap(Array, csdp.blocks + sizeof(blockrec), csdp.nblocks, false)
    jblocks = map(blocks) do csdp
        let n = csdp.blocksize, c = csdp.blockcategory, d = csdp.data._blockdatarec
            if c == MATRIX
                _blockdatarec = _unsafe_wrap(Array, d, n^2, false)
            else
                @assert c == DIAG
                _blockdatarec =
                    _unsafe_wrap(Array, d + sizeof(Cdouble), n, false)
            end
            BlockRec(_blockdatarec, csdp)
        end
    end
    return BlockMatrix(jblocks, blocks, csdp)
end

# In CSDP, the matrices A_i are represented as a constraintmatrix
# which is a block diagonal matrix where each block is a symmetric sparse matrix of Cdouble
# * sparseblock contains a sparse description of the entries of a block
# * constraintmatrix contains a linked list of the blocks

mutable struct SparseBlock <: AbstractMatrix{Cdouble}
    i::Vector{csdpshort}
    j::Vector{csdpshort}
    v::Vector{Cdouble}
    n::CSDP_INT
    csdp::sparseblock
    function SparseBlock(
        i::Vector{csdpshort},
        j::Vector{csdpshort},
        v::Vector{Cdouble},
        n::Integer,
        csdp,
    )
        return new(i, j, v, n, csdp)
    end
end

function SparseBlock(
    i::Vector{csdpshort},
    j::Vector{csdpshort},
    v::Vector{Cdouble},
    n::Integer,
)
    @assert length(i) == length(j) == length(v)
    block = sparseblock(
        C_NULL,    # next
        C_NULL,    # nextbyblock
        fptr(v),   # entries
        fptr(i),   # iindices
        fptr(j),   # jindices
        length(i), # numentries
        0,         # blocknum
        n,         # blocksize
        0,         # constraintnum
        1,
    )         # issparse
    return SparseBlock(i, j, v, n, block)
end

function SparseBlock(A::SparseArrays.SparseMatrixCSC{Cdouble})
    n = LinearAlgebra.checksquare(A)
    nn = SparseArrays.nnz(A)
    I = csdpshort[]
    J = csdpshort[]
    V = Cdouble[]
    vals = SparseArrays.nonzeros(A)
    rows = SparseArrays.rowvals(A)
    for col in 1:n
        for j in SparseArrays.nzrange(A, col)
            row = rows[j]
            if row <= col
                push!(I, row)
                push!(J, col)
                push!(V, vals[j])
            end
        end
    end
    return SparseBlock(I, J, V, n)
end
function SparseBlock(A::AbstractMatrix{Cdouble})
    return SparseBlock(SparseArrays.SparseMatrixCSC{Cdouble,CSDP_INT}(A))
end
SparseBlock(A::AbstractMatrix) = SparseBlock(map(Cdouble, A))
Base.convert(::Type{SparseBlock}, A::AbstractMatrix) = SparseBlock(A)

mutable struct ConstraintMatrix <: AbstractBlockMatrix{Cdouble}
    jblocks::Vector{SparseBlock}
    csdp::constraintmatrix
end

function ConstraintMatrix(constr, jblocks::AbstractVector{SparseBlock})
    if isempty(jblocks)
        error("No variable")
    end
    next = C_NULL
    for blocknum in length(jblocks):-1:1
        jblock = jblocks[blocknum]
        jblock.csdp.next = next
        jblock.csdp.blocknum = blocknum
        jblock.csdp.constraintnum = constr
        next = pointer_from_objref(jblock.csdp)
        #next = Base.unsafe_convert(Ptr{sparseblock}, Ref(block))
    end
    csdp = constraintmatrix(Ptr{sparseblock}(next))
    return ConstraintMatrix(jblocks, csdp)
end
function ConstraintMatrix(i, bs::AbstractMatrix...)
    return ConstraintMatrix(i, SparseBlock[b for b in bs])
end

block(A::blockmatrix, i::Integer) = getblockrec(A, i)
function block(A::Union{BlockMatrix,ConstraintMatrix}, i::Integer)
    return A.jblocks[i]
end
nblocks(A::blockmatrix) = A.nblocks
nblocks(A::Union{BlockMatrix,ConstraintMatrix}) = length(A.jblocks)

export BlockMatrix, ConstraintMatrix

"""Solver status"""
mutable struct Csdp
    n::CSDP_INT
    k::CSDP_INT
    X::BlockMatrix
    y::Vector{Cdouble}
    constant_offset::Cdouble
    constraints::Vector{SparseBlock}
    pobj::Cdouble
    dobj::Cdouble
end
