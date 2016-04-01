# Data types declared in `include/blockmat.h`
# Small type names are the C types
# Capitalized are the corresponding Julia types

type blockdatarec
    mat::Ref{Cdouble}
end

type blockrec
  data::blockdatarec
  blockcategory::Cint;
  blocksize::Cint
end

immutable blockmatrix
  nblocks::Cint
  blocks::Ref{blockrec}
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


type Blockmatrix
    blocks::Vector{MatrixBlock}
end
