# Data types declared in `include/blockmat.h`
# Small type names are the C types
# Capitalized are the corresponding Julia types
import Base.convert, Base.size

# Utils

function fptr{T}(x::Vector{T})
    # CSDP starts indexing at 1 so we need to do "- sizeof(T)"
    pointer(x) - sizeof(T)
end

function ptr{X}(x::X)
    Base.reinterpret(Base.Ptr{X}, Base.pointer_from_objref(x))
end
export fptr, ptr

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
    # Why pointer and not fptr ????
    BlockRec(a, blockrec(blockdatarec(pointer(a)), cat, Cint(isqrt(l))))
end
function BlockRec(A::Matrix)
    BlockRec(Vector{Cdouble}(reshape(A, length(A))), MATRIX, length(A))
end
function BlockRec(A::Diagonal)
    a = Vector{Cdouble}(diag(A))
    BlockRec(a, blockrec(blockdatarec(fptr(a)), DIAG, Cint(isqrt(length(A)))))
end

function size(A::BlockRec)
    n = A.csdp.blocksize
    (n, n)
end

# blockmatrix
type BlockMatrix <: AbstractMatrix{Cdouble}
    jblocks::Vector{BlockRec}
    blocks::Vector{blockrec}
    csdp::blockmatrix
end

function BlockMatrix(As::AbstractVector)
    jblocks = map(BlockRec, As)
    blocks = map(block->block.csdp, jblocks)
    csdp = blockmatrix(length(blocks), fptr(blocks))
    BlockMatrix(jblocks, blocks, csdp)
end
function BlockMatrix(As::AbstractMatrix...)
    BlockMatrix(collect(As))
end

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

function size(A::BlockMatrix)
    n = sum([block.csdp.blocksize for block in A.jblocks])
    (n, n)
end

# In CSDP, the matrices A_i are represented as a constraintmatrix
# which is a block diagonal matrix where each block is a symmetric sparse matrix of Cdouble
# * sparseblock contains a sparse description of the entries of a block
# * constraintmatrix contains a linked list of the blocks

immutable SparseBlock <: AbstractMatrix{Cdouble}
    i::Vector{Cint}
    j::Vector{Cint}
    v::Vector{Cdouble}
    n::Cint
end

function Base.convert(::Type{SparseBlock}, A::AbstractMatrix)
    n = Base.LinAlg.checksquare(A)
    A = map(Cdouble, A)
    C = SparseMatrixCSC{Cdouble, Cint}(A)
    nn = nnz(C)
    I = Cint[]
    J = Cint[]
    V = Cdouble[]
    vals = nonzeros(C)
    rows = rowvals(C)
    for col = 1:n
        for j in nzrange(C, col)
            row = rows[j]
            if row <= col
                push!(I, row)
                push!(J, col)
                push!(V, vals[j])
            end
        end
    end
    SparseBlock(I,J,V, n)
end

function size(A::SparseBlock)
    (A.n, A.n)
end

type ConstraintMatrix <: AbstractMatrix{Cdouble}
    jblocks::Vector{SparseBlock}
    blocks::Vector{sparseblock}
    csdp::constraintmatrix
    function ConstraintMatrix(i, bs::AbstractMatrix...)
        jblocks = SparseBlock[b for b in bs]
        blocks = create_cmat(jblocks, i)
        csdp = constraintmatrix(Ptr{sparseblock}(pointer_from_objref(blocks[1])))
        new(jblocks, blocks, csdp)
    end
end

function size(A::ConstraintMatrix)
    n = sum([block.n for block in A.jblocks])
    (n, n)
end

# Convert a Vector{SparseBlock} to a Vector{sparseblock}
function create_cmat(sblocks::Vector{SparseBlock}, cn=-1)
    blocks = sparseblock[]
    next = C_NULL

    for (i,B) in collect(enumerate(sblocks))[end:-1:1]
        @assert length(B.i) == length(B.j) == length(B.v)
        unshift!(blocks, sparseblock(next,           # next
                                     C_NULL,         # nextbyblock
                                     fptr(B.v), # entries
                                     fptr(B.i), # iindices
                                     fptr(B.j), # jindices
                                     length(B.i),              # numentries
                                     i,              # blocknum
                                     B.n,            # blocksize
                                     cn,             # constraintnum
                                     1               # issparse
                                     ))
        next = pointer_from_objref(blocks[1])
    end
    return blocks
end


function free_blockmatrix(m::blockmatrix)
    ccall((:free_mat, CSDP.csdp), Void, (blockmatrix,), m)
end
export free_blockmatrix

export BlockMatrix, ConstraintMatrix, convert

"""Solver status"""
type Csdp
    n::Cint
    k::Cint
    X::BlockMatrix
    y::Vector{Cdouble}
    constant_offset::Cdouble
    constraints::Vector{SparseBlock}
    pobj::Cdouble
    dobj::Cdouble
end
