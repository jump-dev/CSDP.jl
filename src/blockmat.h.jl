# Copyright (c) 2016: CSDP.jl contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

# Julia wrapper for header: include/blockmat.h
# Automatically generated using Clang.jl wrap_c, version 0.0.0

# TODO detect size and use bitstype because if the DLL changes and gets
#      compiled with NOSHORTS we are screwed with the following code...
@static if Sys.iswindows()
    const csdpshort = Cushort
else
    const csdpshort = CSDP_INT
end

# begin enum blockcat
const blockcat = Cuint
const DIAG = (blockcat)(0)
const MATRIX = (blockcat)(1)
const PACKEDMATRIX = (blockcat)(2)
# end enum blockcat

struct blockdatarec
    _blockdatarec::Ptr{Cdouble}
end

struct blockrec <: AbstractMatrix{Cdouble}
    data::blockdatarec
    blockcategory::blockcat
    blocksize::csdpshort
end

mutable struct blockmatrix <: AbstractBlockMatrix{Cdouble}
    nblocks::CSDP_INT
    blocks::Ptr{blockrec}
end
blockmatrix() = blockmatrix(CSDP_INT(0), C_NULL)

mutable struct sparseblock
    next::Ptr{sparseblock}
    nextbyblock::Ptr{sparseblock}
    entries::Ptr{Cdouble}
    iindices::Ptr{csdpshort}
    jindices::Ptr{csdpshort}
    numentries::CSDP_INT
    blocknum::csdpshort
    blocksize::csdpshort
    constraintnum::csdpshort
    issparse::csdpshort
end
function sparseblock(next, jblock, blocknum, constr)
    # See easysdp.c
    blocksize = jblock.n
    numentries = length(jblock.i)
    return issparse = numentries <= blocksize / 4 || numentries <= 15 # FIXME also if category (which is in C...) is DIAG
end

# If I add mutable here I get : ReadOnlyMemoryError() in initsoln (I know it is counter-intuitive)
struct constraintmatrix
    blocks::Ptr{sparseblock}
end

# Skipping MacroDefinition: ijtok ( iiii , jjjj , lda ) ( ( jjjj - 1 ) * lda + iiii - 1 )
# Skipping MacroDefinition: ijtokp ( iii , jjj , lda ) ( ( iii + jjj * ( jjj - 1 ) / 2 ) - 1 )
# Skipping MacroDefinition: ktoi ( k , lda ) ( ( k % lda ) + 1 )
# Skipping MacroDefinition: ktoj ( k , lda ) ( ( k / lda ) + 1 )

mutable struct paramstruc
    axtol::Cdouble
    atytol::Cdouble
    objtol::Cdouble
    pinftol::Cdouble
    dinftol::Cdouble
    maxiter::CSDP_INT
    minstepfrac::Cdouble
    maxstepfrac::Cdouble
    minstepp::Cdouble
    minstepd::Cdouble
    usexzgap::CSDP_INT
    tweakgap::CSDP_INT
    affine::CSDP_INT
    perturbobj::Cdouble
    fastmode::CSDP_INT
end

function paramstruc(options::Dict)
    return paramstruc(
        get(options, :axtol, 1.0e-8),
        get(options, :atytol, 1.0e-8),
        get(options, :objtol, 1.0e-8),
        get(options, :pinftol, 1.0e8),
        get(options, :dinftol, 1.0e8),
        get(options, :maxiter, 100),
        get(options, :minstepfrac, 0.90),
        get(options, :maxstepfrac, 0.97),
        get(options, :minstepp, 1.0e-8),
        get(options, :minstepd, 1.0e-8),
        get(options, :usexzgap, 1),
        get(options, :tweakgap, 0),
        get(options, :affine, 0),
        get(options, :perturbobj, 1),
        get(options, :fastmode, 0),
    )
end
