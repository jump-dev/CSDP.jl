# Copyright (c) 2016: CSDP.jl contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

import LinearAlgebra
import SparseArrays

abstract type AbstractBlockMatrix{T} <: AbstractMatrix{T} end

function nblocks end
function block end

function Base.size(bm::AbstractBlockMatrix)
    n = mapreduce(
        blk -> LinearAlgebra.checksquare(block(bm, blk)),
        +,
        1:nblocks(bm);
        init = 0,
    )
    return (n, n)
end
function Base.getindex(bm::AbstractBlockMatrix, i::Integer, j::Integer)
    (i < 0 || j < 0) && throw(BoundsError(i, j))
    for k in 1:nblocks(bm)
        blk = block(bm, k)
        n = size(blk, 1)
        if i <= n && j <= n
            return blk[i, j]
        elseif i <= n || j <= n
            return 0
        else
            i -= n
            j -= n
        end
    end
    throw(BoundsError(i + size(bm, 1), j + size(bm, 2)))
end

mutable struct sparseblock
    next::Ptr{sparseblock}
    nextbyblock::Ptr{sparseblock}
    entries::Ptr{Cdouble}
    iindices::Ptr{csdpshort}
    jindices::Ptr{csdpshort}
    numentries::CSDP_INT
    blocknum::csdpshort
    blocksize::csdpshort
    constraintnum::csdpshort
    issparse::csdpshort
end

struct constraintmatrix
    blocks::Ptr{sparseblock}
end

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
        # /!\ the diagonal matrix is 1-indexed -> offset
        BlockRec(a, blockrec(blockdatarec(offset(a)), DIAG, csdpshort(-n)))
    end
end

function BlockRec(A::Matrix)
    return BlockRec(reshape(A, length(A)), LinearAlgebra.checksquare(A))
end

Base.size(A::BlockRec) = size(A.csdp)

function Base.getindex(A::BlockRec, i, j)
    n = A.csdp.blocksize
    if A.csdp.blockcategory == MATRIX
        return A._blockdatarec[i+(j-1)*n]
    end
    @assert A.csdp.blockcategory == DIAG
    return i == j ? A._blockdatarec[i] : 0
end

mutable struct BlockMatrix <: AbstractBlockMatrix{Cdouble}
    jblocks::Vector{BlockRec}
    blocks::Vector{blockrec}
    csdp::blockmatrix
end

Base.cconvert(::Type{blockmatrix}, x::BlockMatrix) = x.csdp

function Base.cconvert(::Type{Ptr{blockmatrix}}, x::BlockMatrix)
    ptr = Base.pointer_from_objref(x.csdp)
    return Base.reinterpret(Base.Ptr{blockmatrix}, ptr)
end

function BlockMatrix(As::AbstractMatrix...)
    jblocks = [BlockRec(A) for A in As]
    blocks = map(block -> block.csdp, jblocks)
    csdp = blockmatrix(length(blocks), offset(blocks))
    return BlockMatrix(jblocks, blocks, csdp)
end

function BlockMatrix(csdp::blockmatrix)
    blocks = unsafe_wrap(
        Array,
        csdp.blocks + sizeof(blockrec),
        csdp.nblocks;
        own = false,
    )
    jblocks = map(blocks) do csdp
        n, c, d = csdp.blocksize, csdp.blockcategory, csdp.data._blockdatarec
        if c == MATRIX
            return BlockRec(unsafe_wrap(Array, d, n^2; own = false), csdp)
        end
        @assert c == DIAG
        data = unsafe_wrap(Array, d + sizeof(Cdouble), n; own = false)
        return BlockRec(data, csdp)
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
        offset(v), # entries
        offset(i), # iindices
        offset(j), # jindices
        length(i), # numentries
        0,         # blocknum
        n,         # blocksize
        0,         # constraintnum
        1,
    )
    return SparseBlock(i, j, v, n, block)
end

function SparseBlock(A::SparseArrays.SparseMatrixCSC{Cdouble})
    n = LinearAlgebra.checksquare(A)
    I, J, V = csdpshort[], csdpshort[], Cdouble[]
    rows, vals = SparseArrays.rowvals(A), SparseArrays.nonzeros(A)
    for col in 1:n
        for j in SparseArrays.nzrange(A, col)
            if rows[j] <= col
                push!(I, rows[j])
                push!(J, col)
                push!(V, vals[j])
            end
        end
    end
    return SparseBlock(I, J, V, n)
end

mutable struct ConstraintMatrix <: AbstractBlockMatrix{Cdouble}
    jblocks::Vector{SparseBlock}
    csdp::constraintmatrix
end

function ConstraintMatrix(constr, bs::AbstractMatrix...)
    jblocks = map(collect(bs)) do b
        return SparseBlock(SparseArrays.SparseMatrixCSC{Cdouble,CSDP_INT}(b))
    end
    @assert !isempty(jblocks)
    next = C_NULL
    for blocknum in length(jblocks):-1:1
        jblock = jblocks[blocknum]
        jblock.csdp.next = next
        jblock.csdp.blocknum = blocknum
        jblock.csdp.constraintnum = constr
        next = pointer_from_objref(jblock.csdp)
    end
    csdp = constraintmatrix(Ptr{sparseblock}(next))
    return ConstraintMatrix(jblocks, csdp)
end

block(A::Union{BlockMatrix,ConstraintMatrix}, i::Integer) = A.jblocks[i]
nblocks(A::Union{BlockMatrix,ConstraintMatrix}) = length(A.jblocks)

function initsoln(n, k, C, a, constraints)
    X = Ref{blockmatrix}(blockmatrix(0, C_NULL))
    y = Ref{Ptr{Cdouble}}(C_NULL)
    Z = Ref{blockmatrix}(blockmatrix(0, C_NULL))
    ccall(
        (:initsoln, CSDP.libcsdp),
        Nothing,
        (
            CSDP_INT,
            CSDP_INT,
            blockmatrix,
            Ptr{Cdouble},
            Ptr{constraintmatrix},
            Ref{blockmatrix},
            Ref{Ptr{Cdouble}},
            Ref{blockmatrix},
        ),
        n,
        k,
        C,
        offset(a),
        offset(constraints),
        X,
        y,
        Z,
    )
    y_out = Base.unsafe_wrap(Array, y[] + sizeof(Cdouble), k; own = false)
    return BlockMatrix(X[]), y_out, BlockMatrix(Z[])
end

function easy_sdp(n, k, C, a, constraints, constant_offset, pX, py, pZ)
    pobj = Ref{Cdouble}(0.0)
    dobj = Ref{Cdouble}(0.0)
    status = ccall(
        (:easy_sdp, CSDP.libcsdp),
        CSDP_INT,
        (
            CSDP_INT,
            CSDP_INT,
            blockmatrix,
            Ptr{Cdouble},
            Ptr{constraintmatrix},
            Cdouble,
            Ptr{blockmatrix},
            Ref{Ptr{Cdouble}},
            Ptr{blockmatrix},
            Ref{Cdouble},
            Ref{Cdouble},
        ),
        n,
        k,
        C,
        offset(a),
        offset(constraints),
        constant_offset,
        pX,
        Ref{Ptr{Cdouble}}(offset(py)),
        pZ,
        pobj,
        dobj,
    )
    return status, pobj[], dobj[]
end

function write_sol(fname, n, k, X, y, Z)
    return ccall(
        (:write_sol, CSDP.libcsdp),
        CSDP_INT,
        (
            Ptr{UInt8},
            CSDP_INT,
            CSDP_INT,
            blockmatrix,
            Ptr{Cdouble},
            blockmatrix,
        ),
        fname,
        n,
        k,
        X,
        offset(y),
        Z,
    )
end

function write_prob(fname, n, k, C, a, constraints)
    return ccall(
        (:write_prob, CSDP.libcsdp),
        CSDP_INT,
        (
            Ptr{UInt8},
            CSDP_INT,
            CSDP_INT,
            blockmatrix,
            Ptr{Cdouble},
            Ptr{constraintmatrix},
        ),
        fname,
        n,
        k,
        C,
        offset(a),
        offset(constraints),
    )
end
