# Data types declared in `include/blockmat.h`
# Small type names are the C types
# Capitalized are the corresponding Julia types

# enum blockcat
const DIAG          = 0
const MATRIX        = 1
const PACKEDMATRIX  = 2

type blockrec
    mat::Ref{Cdouble}
    blockcategory::Cint;
    blocksize::Cint
end

type Blockrec
    data::Vector{Cdouble}
    blockcategory::Cint;
    blocksize::Cint
end


create_block(block::Matrix{Float64}) =
    Blockrec(block[:], MATRIX, length(block))
create_block(block::Diagonal{Float64}) = 
    Blockrec(block[:], DIAG, length(block))


immutable blockmatrix
  nblocks::Cint
  blocks::Ref{blockrec}
end

type Blockmatrix
    blocks::Vector{Blockrec}
    Blockmatrix(bs::Union{Matrix{Float64},Diagonal{Float64}}...) =
        new([create_block(b) for b in bs])
end

type sparseblock
    next::Ref{sparseblock}
    nextbyblock::Ref{sparseblock}
    entries::Ref{Cdouble}
    iindices::Ref{Cint}
    jindices::Ref{Cint}
    numentries::Cint
    blocknum::Cint
    blocksize::Cint
    constraintnum::Cint
    issparse::Cint
end

immutable constraintmatrix
  blocks::Ref{sparseblock}
end
