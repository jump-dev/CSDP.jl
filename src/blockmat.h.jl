# Julia wrapper for header: include/blockmat.h
# Automatically generated using Clang.jl wrap_c, version 0.0.0

# TODO detect size and use bitstype because if the DLL changes and gets
#      compiled with NOSHORTS we are screwed with the following code...
@static if is_windows()
    const csdpshort = Cushort
  else
    const csdpshort = Cint
end

# begin enum blockcat
const blockcat = Cuint
const DIAG = (blockcat)(0)
const MATRIX = (blockcat)(1)
const PACKEDMATRIX = (blockcat)(2)
# end enum blockcat

immutable blockdatarec
    _blockdatarec::Ptr{Cdouble}
end

immutable blockrec
    data::blockdatarec
    blockcategory::blockcat
    blocksize::csdpshort
end

type blockmatrix
    nblocks::Cint
    blocks::Ptr{blockrec}
end

type sparseblock
    next::Ptr{sparseblock}
    nextbyblock::Ptr{sparseblock}
    entries::Ptr{Cdouble}
    iindices::Ptr{csdpshort}
    jindices::Ptr{csdpshort}
    numentries::Cint
    blocknum::csdpshort
    blocksize::csdpshort
    constraintnum::csdpshort
    issparse::csdpshort
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
