# Copyright (c) 2016: CSDP.jl contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

# This file wraps methods that are compiled into our patched version of
# CSDP_jll.

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
