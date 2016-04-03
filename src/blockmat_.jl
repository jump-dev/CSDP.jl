# Julia wrapper for header: include/blockmat.h
# Automatically generated using Clang.jl wrap_c, version 0.0.0

const NOSHORTS = 1

# begin enum blockcat
typealias blockcat UInt32
const DIAG = (UInt32)(0)
const MATRIX = (UInt32)(1)
const PACKEDMATRIX = (UInt32)(2)
# end enum blockcat

type blockdatarec
    _blockdatarec::Ref{Cdouble}
end

type blockrec
    data::blockdatarec
    blockcategory::blockcat
    blocksize::Cint
end

type blockmatrix
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

type constraintmatrix
    blocks::Ref{sparseblock}
end
