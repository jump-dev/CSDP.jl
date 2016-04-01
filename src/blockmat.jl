# Data types declared in `include/blockmat.h`
# Small type names are the C types
# Capitalized are the corresponding Julia types

# enum blockcat
const DIAG          = 0
const MATRIX        = 1
const PACKEDMATRIX  = 2

type blockdatarec
    mat::Ref{Cdouble}
end

type blockrec
  data::blockdatarec
  blockcategory::Cint;
  blocksize::Cint
end

type Blockrec
  data::Vector{Cdouble}
  blockcategory::Cint;
  blocksize::Cint
end


create_block(block::Matrix{Float64}) =
    Blockrec(blockdatarec(block[:]), MATRIX, length(block))
create_block(block::Diagonal{Float64}) = 
    Blockrec(blockdatarec(block[:]), DIAG, length(block))


immutable blockmatrix
  nblocks::Cint
  blocks::Ref{blockrec}
end

type Blockmatrix
    blocks::Vector{blockrec}
    Blockmatrix(bs::Matrix{Float64}...) =
        Blockmatrix([create_block(b) for b in bs])
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
