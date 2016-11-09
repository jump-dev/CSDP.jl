# Data types declared in `include/blockmat.h`
# Small type names are the C types
# Capitalized are the corresponding Julia types
import Base.convert, Base.size, Base.getindex, Base.setindex!

# Utils

function fptr{T}(x::Vector{T})
    # CSDP starts indexing at 1 so we need to do "- sizeof(T)"
    pointer(x) - sizeof(T)
end

function ptr{X}(x::X)
    Base.reinterpret(Base.Ptr{X}, Base.pointer_from_objref(x))
end
export fptr, ptr

function mywrap(X::blockmatrix)
    # finalizer(X, free_blockmatrix)
    BlockMatrix(X)
end

function mywrap{T}(x::Ptr{T}, len)
    # I give false to unsafe_wrap to specify that Julia do not own the array so it should not free it
    # because the pointer it has has an offset
    y = unsafe_wrap(Array, x + sizeof(T), len, false)
    # fptr takes care of this offset
    finalizer(y, s -> Libc.free(fptr(s)))
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
type BlockRec <: AbstractMatrix{Cdouble}
    _blockdatarec::Vector{Cdouble}
    csdp::blockrec
end
function BlockRec(a::Vector{Cdouble}, cat::blockcat, l::Int)
    # /!\ the matrix is not 1-indexed
    BlockRec(a, blockrec(blockdatarec(pointer(a)), cat, BlasInt(isqrt(l))))
end
function BlockRec(A::Matrix)
    BlockRec(Vector{Cdouble}(reshape(A, length(A))), MATRIX, length(A))
end
function BlockRec(A::Diagonal)
    a = Vector{Cdouble}(diag(A))
    BlockRec(a, blockrec(blockdatarec(fptr(a)), DIAG, BlasInt(isqrt(length(A)))))
end
function blockreczeros(n)
    BlockRec(zeros(Cdouble, n^2), MATRIX, n^2)
end

function size(A::BlockRec)
    n = A.csdp.blocksize
    (n, n)
end
function getindex(A::BlockRec, i, j)
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
function setindex!(A::BlockRec, v, i, j)
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
type BlockMatrix <: AbstractMatrix{Cdouble}
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
    blocks = unsafe_wrap(Array, csdp.blocks + sizeof(blockrec), csdp.nblocks, false)
    jblocks = map(blocks) do csdp
        let n = csdp.blocksize, c = csdp.blockcategory, d = csdp.data._blockdatarec
            if c == MATRIX
                _blockdatarec = unsafe_wrap(Array, d, n^2, false)
            elseif c == DIAG
                _blockdatarec = unsafe_wrap(Array, d + sizeof(Cdouble), n, false)
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


function size(A::BlockMatrix)
    n = sum([block.csdp.blocksize for block in A.jblocks])
    (n, n)
end

# In CSDP, the matrices A_i are represented as a constraintmatrix
# which is a block diagonal matrix where each block is a symmetric sparse matrix of Cdouble
# * sparseblock contains a sparse description of the entries of a block
# * constraintmatrix contains a linked list of the blocks

type SparseBlock <: AbstractMatrix{Cdouble}
    i::Vector{BlasInt}
    j::Vector{BlasInt}
    v::Vector{Cdouble}
    n::BlasInt
    csdp::Nullable{sparseblock}
    function SparseBlock(i::Vector{BlasInt}, j::Vector{BlasInt}, v::Vector{Cdouble}, n::Integer, csdp)
        new(i, j, v, n, csdp)
    end
end

function SparseBlock(i::Vector{BlasInt}, j::Vector{BlasInt}, v::Vector{Cdouble}, n::Integer)
    SparseBlock(i, j, v, n, nothing)
end

convert(::Type{SparseBlock}, A::SparseBlock) = A
function convert(::Type{SparseBlock}, A::SparseMatrixCSC{Cdouble})
    n = Base.LinAlg.checksquare(A)
    nn = nnz(A)
    I = BlasInt[]
    J = BlasInt[]
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
convert(::Type{SparseBlock}, A::AbstractMatrix{Cdouble}) = SparseBlock(SparseMatrixCSC{Cdouble, BlasInt}(A))
convert(::Type{SparseBlock}, A::AbstractMatrix) = SparseBlock(map(Cdouble, A))
function sparseblockzeros(n)
    SparseBlock(BlasInt[], BlasInt[], Cdouble[], n)
end

function size(A::SparseBlock)
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
function getindex(A::SparseBlock, i, j)
    k = findindices(A, i, j)
    if k == 0
        0
    else
        A.v[k]
    end
end
function setindex!(A::SparseBlock, v, i, j)
    k = findindices(A, i, j)
    if k == 0
        push!(A.i, i)
        push!(A.j, j)
        push!(A.v, v)
        if !isnull(A.csdp)
            @assert get(A.csdp).numentries + 1 == length(A.i)
            get(A.csdp).numentries = length(A.i)
            # If push! has reallocated it, we need to change the pointer
            get(A.csdp).entries = fptr(A.v)
            get(A.csdp).iindices = fptr(A.i)
            get(A.csdp).jindices = fptr(A.j)
        end
    else
        A.v[k] = v
    end
end


type ConstraintMatrix <: AbstractMatrix{Cdouble}
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
        @assert length(jblock.i) == length(jblock.j) == length(jblock.v)
        block = sparseblock(next,             # next
                            C_NULL,           # nextbyblock
                            fptr(jblock.v),   # entries
                            fptr(jblock.i),   # iindices
                            fptr(jblock.j),   # jindices
                            length(jblock.i), # numentries
                            blocknum,         # blocknum
                            jblock.n,         # blocksize
                            constr,           # constraintnum
                            1                 # issparse
                            )
        jblock.csdp = block
        next = pointer_from_objref(block)
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
    blocks = unsafe_wrap(Array, csdp.blocks, k, true) # FIXME this is a linked list, not an array...
    jblocks = map(blocks) do csdp
        ne = csdp.numentries
        i = mywrap(csdp.iindices, ne)
        j = mywrap(csdp.jindices, ne)
        v = mywrap(csdp.entries, ne)
        SparseBlock(i, j, v, csdp.blocksize, csdp)
    end
    ConstraintMatrix(jblocks, csdp)
end

function size(A::ConstraintMatrix)
    n = sum([block.n for block in A.jblocks])
    (n, n)
end


function getindex(A::Union{BlockMatrix, ConstraintMatrix}, i::Integer, j::Integer)
    (i < 0 || j < 0) && error("invalid indices")
    for block in A.jblocks
        n = size(block, 1)
        if i <= n && j <= n
            return block[i,j]
        elseif i <= n || j <= n
            return 0
        else
            i -= n
            j -= n
        end
    end
    error("invalid indices")
end

# Not really part of AbstractMatrix
function getindex(A::Union{BlockMatrix, ConstraintMatrix}, i::Integer)
    A.jblocks[i]
end

function free_blockmatrix(m::blockmatrix)
    ccall((:free_mat, CSDP.csdp), Void, (blockmatrix,), m)
end
export free_blockmatrix

export BlockMatrix, ConstraintMatrix

"""Solver status"""
type Csdp
    n::BlasInt
    k::BlasInt
    X::BlockMatrix
    y::Vector{Cdouble}
    constant_offset::Cdouble
    constraints::Vector{SparseBlock}
    pobj::Cdouble
    dobj::Cdouble
end
