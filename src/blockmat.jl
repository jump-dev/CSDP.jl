# Data types declared in `include/blockmat.h`
# Small type names are the C types
# Capitalized are the corresponding Julia types

# Utils

function fptr(x::Vector{T}) where T
    # CSDP starts indexing at 1 so we need to do "- sizeof(T)"
    pointer(x) - sizeof(T)
end

function ptr(x::X) where X
    Base.reinterpret(Base.Ptr{X}, Base.pointer_from_objref(x))
end
export fptr, ptr

function mywrap(X::blockmatrix)
    BlockMatrix(X)
end

function _unsafe_wrap(A, x, n, own::Bool)
    Base.unsafe_wrap(A, x, n, own=own)
end

function mywrap(x::Ptr{T}, len) where T
    # I give false to unsafe_wrap to specify that Julia do not own the array so it should not free it
    # because the pointer it has has an offset
    y = _unsafe_wrap(Array, x + sizeof(T), len, false)
    # fptr takes care of this offset
    #finalizer(s -> Libc.free(fptr(s)), y)
    y
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
function BlockRec(A::Diagonal)
    a = Vector{Cdouble}(diag(A))
    BlockRec(a, -length(a))
end
function blockreczeros(n)
    if n > 0
        BlockRec(zeros(Cdouble, n^2), n)
    else
        BlockRec(zeros(Cdouble, -n), n)
    end
end

function Base.size(A::blockrec)
    n = A.blocksize
    (n, n)
end
Base.size(A::BlockRec) = size(A.csdp)
function Base.getindex(A::BlockRec, i, j)
    n = A.csdp.blocksize
    if A.csdp.blockcategory == MATRIX
        A._blockdatarec[i+(j-1)*n]
    elseif  A.csdp.blockcategory == DIAG
        if i == j
            A._blockdatarec[i]
        else
            0
        end
    else
        error("Invalid category")
    end
end
function Base.setindex!(A::BlockRec, v, i, j)
    n = A.csdp.blocksize
    if A.csdp.blockcategory == MATRIX
        A._blockdatarec[i+(j-1)*n] = v
        A._blockdatarec[j+(i-1)*n] = v
    elseif  A.csdp.blockcategory == DIAG
        if i == j
            A._blockdatarec[i] = v
        else
            error("Cannot set off-diagonal entry of diagonal matrix")
        end
    else
        error("Invalid category")
    end
end


# blockmatrix
mutable struct BlockMatrix <: AbstractBlockMatrix{Cdouble}
    jblocks::Vector{BlockRec}
    blocks::Vector{blockrec}
    csdp::blockmatrix
end

function BlockMatrix(jblocks::AbstractVector{BlockRec})
    blocks = map(block->block.csdp, jblocks)
    csdp = blockmatrix(length(blocks), fptr(blocks))
    BlockMatrix(jblocks, blocks, csdp)
end
BlockMatrix(As::AbstractVector) = BlockMatrix(map(BlockRec, As))
BlockMatrix(As::AbstractMatrix...) = BlockMatrix(collect(As))
blockmatzeros(blkdims) = BlockMatrix(map(blockreczeros, blkdims))

function BlockMatrix(csdp::blockmatrix)
    # I give false so that Julia does not try to free it
    blocks = _unsafe_wrap(Array, csdp.blocks + sizeof(blockrec), csdp.nblocks, false)
    jblocks = map(blocks) do csdp
        let n = csdp.blocksize, c = csdp.blockcategory, d = csdp.data._blockdatarec
            if c == MATRIX
                _blockdatarec = _unsafe_wrap(Array, d, n^2, false)
            elseif c == DIAG
                _blockdatarec = _unsafe_wrap(Array, d + sizeof(Cdouble), n, false)
            else
                error("Unknown block category $(c)")
            end
            BlockRec(_blockdatarec, csdp)
        end
    end
    BlockMatrix(jblocks, blocks, csdp)
end

## Old function for that...
#   function Blockmatrix(X::CSDP.blockmatrix)
#       bs = pointer_to_array(X.blocks + sizeof(CSDP.blockrec), X.nblocks)
#       Bs = map(bs) do b
#           let s = b.blocksize, c = b.blockcategory, d = b.data._blockdatarec
#               if b.blockcategory == CSDP.MATRIX
#                   pointer_to_array(d, (s, s))
#               elseif b.blockcategory == CSDP.DIAG
#                   diagm(pointer_to_array(d + sizeof(Cdouble), s))
#               else
#                   error("Unknown block category $(b.blockcategory)")
#               end
#           end
#       end
#       Blockmatrix(Bs, bs)
#   end

# In CSDP, the matrices A_i are represented as a constraintmatrix
# which is a block diagonal matrix where each block is a symmetric sparse matrix of Cdouble
# * sparseblock contains a sparse description of the entries of a block
# * constraintmatrix contains a linked list of the blocks

mutable struct SparseBlock <: AbstractMatrix{Cdouble}
    i::Vector{csdpshort}
    j::Vector{csdpshort}
    v::Vector{Cdouble}
    n::Cint
    csdp::sparseblock
    function SparseBlock(i::Vector{csdpshort}, j::Vector{csdpshort}, v::Vector{Cdouble}, n::Integer, csdp)
        new(i, j, v, n, csdp)
    end
end

function SparseBlock(i::Vector{csdpshort}, j::Vector{csdpshort}, v::Vector{Cdouble}, n::Integer)
    @assert length(i) == length(j) == length(v)
    block = sparseblock(C_NULL,    # next
                        C_NULL,    # nextbyblock
                        fptr(v),   # entries
                        fptr(i),   # iindices
                        fptr(j),   # jindices
                        length(i), # numentries
                        0,         # blocknum
                        n,         # blocksize
                        0,         # constraintnum
                        1)         # issparse
    SparseBlock(i, j, v, n, block)
end

SparseBlock(A::SparseBlock) = A
function SparseBlock(A::SparseMatrixCSC{Cdouble})
    n = LinearAlgebra.checksquare(A)
    nn = nnz(A)
    I = csdpshort[]
    J = csdpshort[]
    V = Cdouble[]
    vals = nonzeros(A)
    rows = rowvals(A)
    for col = 1:n
        for j in nzrange(A, col)
            row = rows[j]
            if row <= col
                push!(I, row)
                push!(J, col)
                push!(V, vals[j])
            end
        end
    end
    SparseBlock(I, J, V, n)
end
SparseBlock(A::AbstractMatrix{Cdouble}) = SparseBlock(SparseMatrixCSC{Cdouble, Cint}(A))
SparseBlock(A::AbstractMatrix) = SparseBlock(map(Cdouble, A))
Base.convert(::Type{SparseBlock}, A::AbstractMatrix) = SparseBlock(A)

function sparseblockzeros(n)
    SparseBlock(csdpshort[], csdpshort[], Cdouble[], abs(n))
end

function Base.size(A::SparseBlock)
    (A.n, A.n)
end
function findindices(A::SparseBlock, i, j)
    if i > A.n || j > A.n || i <= 0 || j <= 0
        error("Invalid indices")
    end
    for k in 1:length(A.i)
        if A.i[k] == i && A.j[k] == j
            return k
        end
    end
    return 0
end
function Base.getindex(A::SparseBlock, i, j)
    k = findindices(A, i, j)
    if k == 0
        0
    else
        A.v[k]
    end
end
function Base.setindex!(A::SparseBlock, v, i, j)
    k = findindices(A, i, j)
    if k == 0
        push!(A.i, i)
        push!(A.j, j)
        push!(A.v, v)
        @assert A.csdp.numentries + 1 == length(A.i)
        A.csdp.numentries = length(A.i)
        # If push! has reallocated it, we need to change the pointer
        A.csdp.entries = fptr(A.v)
        A.csdp.iindices = fptr(A.i)
        A.csdp.jindices = fptr(A.j)
    else
        A.v[k] = v
    end
end


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
    ConstraintMatrix(jblocks, csdp)
end
ConstraintMatrix(i, bs::AbstractMatrix...) = ConstraintMatrix(i, SparseBlock[b for b in bs])
constrmatzeros(i, blkdims) = ConstraintMatrix(i, map(sparseblockzeros, blkdims))

# I need sparseblock to be immutable for this function to work
# but this is kind of annoying since I want to modify its entries in setindex!(::SparseBlock, ...)
function ConstraintMatrix(csdp::constraintmatrix, k::Integer)
    # I take care to free the blocks array when necessary in mywrap since CSDP won't take care of that (see the code of read_prob)
    blocks = _unsafe_wrap(Array, csdp.blocks, k, true) # FIXME this is a linked list, not an array...
    jblocks = map(blocks) do csdp
        ne = csdp.numentries
        i = mywrap(csdp.iindices, ne)
        j = mywrap(csdp.jindices, ne)
        v = mywrap(csdp.entries, ne)
        SparseBlock(i, j, v, csdp.blocksize, csdp)
    end
    ConstraintMatrix(jblocks, csdp)
end

# Needed by MPB_wrapper
function Base.getindex(A::Union{blockmatrix, BlockMatrix, ConstraintMatrix}, i::Integer)
    block(A, i)
end

block(A::blockmatrix, i::Integer) = getblockrec(A, i)
function block(A::Union{BlockMatrix, ConstraintMatrix}, i::Integer)
    A.jblocks[i]
end
nblocks(A::blockmatrix) = A.nblocks
nblocks(A::Union{BlockMatrix, ConstraintMatrix}) = length(A.jblocks)

export BlockMatrix, ConstraintMatrix

"""Solver status"""
mutable struct Csdp
    n::Cint
    k::Cint
    X::BlockMatrix
    y::Vector{Cdouble}
    constant_offset::Cdouble
    constraints::Vector{SparseBlock}
    pobj::Cdouble
    dobj::Cdouble
end
