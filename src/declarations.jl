# Copyright (c) 2016: CSDP.jl contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

export initsoln, easy_sdp

struct LoadingProblem
    ptr::Ptr{Cvoid}
end

function allocate_loading_prob(
    pC::Ref{blockmatrix},
    block_dims::Vector{CSDP_INT},
    num_constraints::Integer,
    num_entries::Matrix{CSDP_INT},
    printlevel::Integer,
)
    ptr = allocate_loading_prob(
        pC,
        fptr(block_dims),
        num_constraints,
        pointer(num_entries),
        printlevel,
    )
    return LoadingProblem(ptr)
end

free_loading_prob(problem::LoadingProblem) = free_loading_prob(problem.ptr)

function free_loaded_prob(
    problem::LoadingProblem,
    X::blockmatrix,
    y::Vector{Cdouble},
    Z::blockmatrix,
)
    return free_loaded_prob(problem.ptr, X, fptr(y), Z)
end

function setconstant(problem::LoadingProblem, mat::Integer, ent::Cdouble)
    return setconstant(problem.ptr, mat, ent)
end

function addentry(
    problem::LoadingProblem,
    mat::Integer,
    blk::Integer,
    indexi::Integer,
    indexj::Integer,
    ent::Cdouble,
    allow_duplicates::Bool,
)
    ret = addentry(problem.ptr, mat, blk, indexi, indexj, ent, allow_duplicates)
    return !iszero(ret)
end

function loaded_initsoln(
    problem::LoadingProblem,
    num_constraints::Integer,
    X::Ref{blockmatrix},
    Z::Ref{blockmatrix},
)
    y = loaded_initsoln(problem.ptr, X, Z)
    return mywrap(y, num_constraints)
end

function initsoln(
    C::BlockMatrix,
    b::Vector{Cdouble},
    As::Vector{constraintmatrix},
)
    m = length(As)
    X, y, Z =
        initsoln(CSDP_INT(size(C, 1)), CSDP_INT(m), C.csdp, fptr(b), fptr(As))
    return mywrap(X), mywrap(y, m), mywrap(Z)
end

function loaded_sdp(
    problem::LoadingProblem,
    co::Cdouble,
    X::Ref{blockmatrix},
    y::Vector{Cdouble},
    Z::Ref{blockmatrix},
    params::Dict{Symbol},
)
    return loaded_sdp(problem, co, X, y, Z, options(params)...)
end

function loaded_sdp(
    problem::LoadingProblem,
    co::Cdouble,
    X::Ref{blockmatrix},
    y::Vector{Cdouble},
    Z::Ref{blockmatrix},
    printlevel,
    params,
)
    # I pass pointers py to X, y and Z but only *pX, *py and *pZ are
    # used in the code so no need to worry, they won't change :)
    ycsdp = Ref{Ptr{Cdouble}}(fptr(y))

    status, pobj, dobj = loaded_sdp(
        problem.ptr,      # problem::Ptr{Cvoid}
        co,               # constant_offset::Cdouble
        X,                # pX::Ptr{blockmatrix}
        ycsdp,            # py::Ptr{Cdouble}
        Z,                # pZ::Ptr{blockmatrix}
        CSDP_INT(printlevel), # printlevel::CSDP_INT
        params,
    )           # parameters::paramstruc
    # I can even assert that they won't change
    @assert ycsdp[] == fptr(y)
    return status, pobj, dobj
end

function easy_sdp(
    C::BlockMatrix,
    b::Vector{Cdouble},
    As::Vector{constraintmatrix},
    co::Cdouble,
    X::BlockMatrix,
    y::Vector{Cdouble},
    Z::BlockMatrix,
)
    # I pass pointers pX, py and pZ to X, y and Z but only *pX, *py and *pZ are
    # used in the code so no need to worry, they won't change :)
    Xcsdp = X.csdp
    ycsdp = Ref{Ptr{Cdouble}}(fptr(y))
    Zcsdp = Z.csdp

    status, pobj, dobj = easy_sdp(
        CSDP_INT(size(C, 1)), # n::CSDP_INT
        CSDP_INT(length(As)), # k::CSDP_INT
        C.csdp,           # C::blockmatrix
        fptr(b),          # a::Ptr{Cdouble}
        fptr(As),         # constraints::Ptr{constraintmatrix}
        co,               # constant_offset::Cdouble
        ptr(Xcsdp),       # pX::Ptr{blockmatrix}
        ycsdp,            # py::Ptr{Cdouble}
        ptr(Zcsdp),
    )       # pZ::Ptr{blockmatrix}
    # I can even assert that they won't change
    @assert Xcsdp == X.csdp
    @assert ycsdp[] == fptr(y)
    @assert Zcsdp == Z.csdp
    return status, pobj, dobj
end

function write_prob(
    fname::String,
    C::BlockMatrix,
    b::Vector{Cdouble},
    As::Vector{constraintmatrix},
)
    return write_prob(
        fname,
        CSDP_INT(size(C, 1)),
        CSDP_INT(length(As)),
        C.csdp,
        fptr(b),
        fptr(As),
    )
end

function write_sol(
    fname::String,
    X::BlockMatrix,
    y::Vector{Cdouble},
    Z::BlockMatrix,
)
    return write_sol(
        fname,
        CSDP_INT(size(X, 1)),
        CSDP_INT(length(y)),
        X.csdp,
        fptr(y),
        Z.csdp,
    )
end
