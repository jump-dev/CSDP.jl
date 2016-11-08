# Julia wrapper for header: include/blockmat.h
# Automatically generated using Clang.jl wrap_c, version 0.0.0

const NOSHORTS = 1

# begin enum blockcat
typealias blockcat UInt32
const DIAG = (UInt32)(0)
const MATRIX = (UInt32)(1)
const PACKEDMATRIX = (UInt32)(2)
# end enum blockcat

immutable blockdatarec
    _blockdatarec::Ptr{Cdouble}
end

immutable blockrec
    data::blockdatarec
    blockcategory::blockcat
    blocksize::BlasInt
end

immutable blockmatrix
    nblocks::BlasInt
    blocks::Ptr{blockrec}
end

type sparseblock
    next::Ptr{sparseblock}
    nextbyblock::Ptr{sparseblock}
    entries::Ptr{Cdouble}
    iindices::Ptr{BlasInt}
    jindices::Ptr{BlasInt}
    numentries::BlasInt
    blocknum::BlasInt
    blocksize::BlasInt
    constraintnum::BlasInt
    issparse::BlasInt
end

immutable constraintmatrix
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
    maxiter::BlasInt
    minstepfrac::Cdouble
    maxstepfrac::Cdouble
    minstepp::Cdouble
    minstepd::Cdouble
    usexzgap::BlasInt
    tweakgap::BlasInt
    affine::BlasInt
    perturbobj::Cdouble
    fastmode::BlasInt
end
