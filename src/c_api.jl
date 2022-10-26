# Copyright (c) 2016: CSDP.jl contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

const blockcat = Cuint
const DIAG = blockcat(0)
const MATRIX = blockcat(1)
const PACKEDMATRIX = blockcat(2)

struct blockdatarec
    _blockdatarec::Ptr{Cdouble}
end

struct blockrec <: AbstractMatrix{Cdouble}
    data::blockdatarec
    blockcategory::blockcat
    blocksize::csdpshort
end

mutable struct blockmatrix <: AbstractMatrix{Cdouble}
    nblocks::CSDP_INT
    blocks::Ptr{blockrec}
end

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

function Base.getindex(A::blockrec, i::Integer, j::Integer)
    return ccall(
        (:getindex, CSDP.libcsdp),
        Cdouble,
        (blockrec, CSDP_INT, CSDP_INT),
        A,
        i,
        j,
    )
end

Base.size(A::blockrec) = A.blocksize, A.blocksize

function getblockrec(A::blockmatrix, i::Integer)
    return ccall(
        (:getblockrec, CSDP.libcsdp),
        blockrec,
        (blockmatrix, CSDP_INT),
        A,
        i,
    )
end

function loaded_initsoln(problem, X, Z)
    y = Ref{Ptr{Cdouble}}(C_NULL)
    ccall(
        (:loaded_initsoln, CSDP.libcsdp),
        Nothing,
        (Ptr{Cvoid}, Ref{blockmatrix}, Ref{Ptr{Cdouble}}, Ref{blockmatrix}),
        problem,
        X,
        y,
        Z,
    )
    return y[]
end

function allocate_loading_prob(
    pC,
    block_dims,
    num_constraints,
    num_entries,
    printlevel,
)
    return ccall(
        (:allocate_loading_prob, CSDP.libcsdp),
        Ptr{Cvoid},
        (Ref{blockmatrix}, Ptr{CSDP_INT}, CSDP_INT, Ptr{CSDP_INT}, CSDP_INT),
        pC,
        block_dims,
        num_constraints,
        num_entries,
        printlevel,
    )
end

function free_loading_prob(problem)
    return ccall(
        (:free_loading_prob, CSDP.libcsdp),
        Nothing,
        (Ptr{Cvoid},),
        problem,
    )
end

function free_loaded_prob(problem, X, y, Z)
    return ccall(
        (:free_loaded_prob, CSDP.libcsdp),
        Nothing,
        (Ptr{Cvoid}, blockmatrix, Ptr{Cdouble}, blockmatrix),
        problem,
        X,
        y,
        Z,
    )
end

function setconstant(problem, mat, ent)
    return ccall(
        (:setconstant, CSDP.libcsdp),
        Nothing,
        (Ptr{Cvoid}, CSDP_INT, Cdouble),
        problem,
        mat,
        ent,
    )
end

function addentry(problem, mat, blk, indexi, indexj, ent, allow_duplicates)
    return ccall(
        (:addentry, CSDP.libcsdp),
        CSDP_INT,
        (Ptr{Cvoid}, CSDP_INT, CSDP_INT, CSDP_INT, CSDP_INT, Cdouble, CSDP_INT),
        problem,
        mat,
        blk,
        indexi,
        indexj,
        ent,
        allow_duplicates,
    )
end

function loaded_sdp(
    problem,
    constant_offset,
    pX,
    py,
    pZ,
    printlevel,
    parameters,
)
    pobj = Ref{Cdouble}(0.0)
    dobj = Ref{Cdouble}(0.0)
    status = ccall(
        (:loaded_sdp, CSDP.libcsdp),
        CSDP_INT,
        (
            Ptr{Cvoid},
            Cdouble,
            Ref{blockmatrix},
            Ref{Ptr{Cdouble}},
            Ref{blockmatrix},
            Ref{Cdouble},
            Ref{Cdouble},
            CSDP_INT,
            paramstruc,
        ),
        problem,
        constant_offset,
        pX,
        py,
        pZ,
        pobj,
        dobj,
        printlevel,
        parameters,
    )
    return status, pobj[], dobj[]
end
