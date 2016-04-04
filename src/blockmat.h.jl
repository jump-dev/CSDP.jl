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
    _blockdatarec::Ptr{Cdouble}
end

type blockrec
    data::blockdatarec
    blockcategory::blockcat
    blocksize::Cint
end

type blockmatrix
    nblocks::Cint
    blocks::Ptr{blockrec}
end

type sparseblock
    next::Ptr{sparseblock}
    nextbyblock::Ptr{sparseblock}
    entries::Ptr{Cdouble}
    iindices::Ptr{Cint}
    jindices::Ptr{Cint}
    numentries::Cint
    blocknum::Cint
    blocksize::Cint
    constraintnum::Cint
    issparse::Cint
end

type constraintmatrix
    blocks::Ptr{sparseblock}
end

# Skipping MacroDefinition: ijtok ( iiii , jjjj , lda ) ( ( jjjj - 1 ) * lda + iiii - 1 )
# Skipping MacroDefinition: ijtokp ( iii , jjj , lda ) ( ( iii + jjj * ( jjj - 1 ) / 2 ) - 1 )
# Skipping MacroDefinition: ktoi ( k , lda ) ( ( k % lda ) + 1 )
# Skipping MacroDefinition: ktoj ( k , lda ) ( ( k / lda ) + 1 )

type paramstruc
    axtol::Cdouble
    atytol::Cdouble
    objtol::Cdouble
    pinftol::Cdouble
    dinftol::Cdouble
    maxiter::Cint
    minstepfrac::Cdouble
    maxstepfrac::Cdouble
    minstepp::Cdouble
    minstepd::Cdouble
    usexzgap::Cint
    tweakgap::Cint
    affine::Cint
    perturbobj::Cdouble
    fastmode::Cint
end
