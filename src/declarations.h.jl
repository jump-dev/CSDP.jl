# Julia wrapper for header: include/declarations.h
# Automatically generated using Clang.jl wrap_c, version 0.0.0 and then modified as some places

export read_prob

function triu(A::blockmatrix)
    return ccall((:triu, CSDP.libcsdp), Nothing, (blockmatrix,), A)
end

function store_packed(A::blockmatrix, B::blockmatrix)
    return ccall(
        (:store_packed, CSDP.libcsdp),
        Nothing,
        (blockmatrix, blockmatrix),
        A,
        B,
    )
end

function store_unpacked(A::blockmatrix, B::blockmatrix)
    return ccall(
        (:store_unpacked, CSDP.libcsdp),
        Nothing,
        (blockmatrix, blockmatrix),
        A,
        B,
    )
end

function alloc_mat_packed(A::blockmatrix, pB::Ref{blockmatrix})
    return ccall(
        (:alloc_mat_packed, CSDP.libcsdp),
        Nothing,
        (blockmatrix, Ref{blockmatrix}),
        A,
        pB,
    )
end

function free_mat_packed(A::blockmatrix)
    return ccall((:free_mat_packed, CSDP.libcsdp), Nothing, (blockmatrix,), A)
end

function structnnz(
    n::CSDP_INT,
    k::CSDP_INT,
    C::blockmatrix,
    constraints::Ptr{constraintmatrix},
)
    return ccall(
        (:structnnz, CSDP.libcsdp),
        CSDP_INT,
        (CSDP_INT, CSDP_INT, blockmatrix, Ptr{constraintmatrix}),
        n,
        k,
        C,
        constraints,
    )
end

function actnnz(n::CSDP_INT, lda::CSDP_INT, A::Ptr{Cdouble})
    return ccall(
        (:actnnz, CSDP.libcsdp),
        CSDP_INT,
        (CSDP_INT, CSDP_INT, Ptr{Cdouble}),
        n,
        lda,
        A,
    )
end

function bandwidth(n::CSDP_INT, lda::CSDP_INT, A::Ptr{Cdouble})
    return ccall(
        (:bandwidth, CSDP.libcsdp),
        CSDP_INT,
        (CSDP_INT, CSDP_INT, Ptr{Cdouble}),
        n,
        lda,
        A,
    )
end

function qreig(n::CSDP_INT, maindiag::Ptr{Cdouble}, offdiag::Ptr{Cdouble})
    return ccall(
        (:qreig, CSDP.libcsdp),
        Nothing,
        (CSDP_INT, Ptr{Cdouble}, Ptr{Cdouble}),
        n,
        maindiag,
        offdiag,
    )
end

function sort_entries(
    k::CSDP_INT,
    C::blockmatrix,
    constraints::Ptr{constraintmatrix},
)
    return ccall(
        (:sort_entries, CSDP.libcsdp),
        Nothing,
        (CSDP_INT, blockmatrix, Ptr{constraintmatrix}),
        k,
        C,
        constraints,
    )
end

function norm2(n::CSDP_INT, x::Ptr{Cdouble})
    return ccall(
        (:norm2, CSDP.libcsdp),
        Cdouble,
        (CSDP_INT, Ptr{Cdouble}),
        n,
        x,
    )
end

function norm1(n::CSDP_INT, x::Ptr{Cdouble})
    return ccall(
        (:norm1, CSDP.libcsdp),
        Cdouble,
        (CSDP_INT, Ptr{Cdouble}),
        n,
        x,
    )
end

function norminf(n::CSDP_INT, x::Ptr{Cdouble})
    return ccall(
        (:norminf, CSDP.libcsdp),
        Cdouble,
        (CSDP_INT, Ptr{Cdouble}),
        n,
        x,
    )
end

function Fnorm(A::blockmatrix)
    return ccall((:Fnorm, CSDP.libcsdp), Cdouble, (blockmatrix,), A)
end

function Knorm(A::blockmatrix)
    return ccall((:Knorm, CSDP.libcsdp), Cdouble, (blockmatrix,), A)
end

function mat1norm(A::blockmatrix)
    return ccall((:mat1norm, CSDP.libcsdp), Cdouble, (blockmatrix,), A)
end

function matinfnorm(A::blockmatrix)
    return ccall((:matinfnorm, CSDP.libcsdp), Cdouble, (blockmatrix,), A)
end

function calc_pobj(C::blockmatrix, X::blockmatrix, constant_offset::Cdouble)
    return ccall(
        (:calc_pobj, CSDP.libcsdp),
        Cdouble,
        (blockmatrix, blockmatrix, Cdouble),
        C,
        X,
        constant_offset,
    )
end

function calc_dobj(
    k::CSDP_INT,
    a::Ptr{Cdouble},
    y::Ptr{Cdouble},
    constant_offset::Cdouble,
)
    return ccall(
        (:calc_dobj, CSDP.libcsdp),
        Cdouble,
        (CSDP_INT, Ptr{Cdouble}, Ptr{Cdouble}, Cdouble),
        k,
        a,
        y,
        constant_offset,
    )
end

function trace_prod(A::blockmatrix, B::blockmatrix)
    return ccall(
        (:trace_prod, CSDP.libcsdp),
        Cdouble,
        (blockmatrix, blockmatrix),
        A,
        B,
    )
end

function linesearch(
    n::CSDP_INT,
    dX::blockmatrix,
    work1::blockmatrix,
    work2::blockmatrix,
    work3::blockmatrix,
    cholinv::blockmatrix,
    q::Ptr{Cdouble},
    z::Ptr{Cdouble},
    workvec::Ptr{Cdouble},
    stepfrac::Cdouble,
    start::Cdouble,
    printlevel::CSDP_INT,
)
    return ccall(
        (:linesearch, CSDP.libcsdp),
        Cdouble,
        (
            CSDP_INT,
            blockmatrix,
            blockmatrix,
            blockmatrix,
            blockmatrix,
            blockmatrix,
            Ptr{Cdouble},
            Ptr{Cdouble},
            Ptr{Cdouble},
            Cdouble,
            Cdouble,
            CSDP_INT,
        ),
        n,
        dX,
        work1,
        work2,
        work3,
        cholinv,
        q,
        z,
        workvec,
        stepfrac,
        start,
        printlevel,
    )
end

function pinfeas(
    k::CSDP_INT,
    constraints::Ptr{constraintmatrix},
    X::blockmatrix,
    a::Ptr{Cdouble},
    workvec::Ptr{Cdouble},
)
    return ccall(
        (:pinfeas, CSDP.libcsdp),
        Cdouble,
        (
            CSDP_INT,
            Ptr{constraintmatrix},
            blockmatrix,
            Ptr{Cdouble},
            Ptr{Cdouble},
        ),
        k,
        constraints,
        X,
        a,
        workvec,
    )
end

function dinfeas(
    k::CSDP_INT,
    C::blockmatrix,
    constraints::Ptr{constraintmatrix},
    y::Ptr{Cdouble},
    Z::blockmatrix,
    work1::blockmatrix,
)
    return ccall(
        (:dinfeas, CSDP.libcsdp),
        Cdouble,
        (
            CSDP_INT,
            blockmatrix,
            Ptr{constraintmatrix},
            Ptr{Cdouble},
            blockmatrix,
            blockmatrix,
        ),
        k,
        C,
        constraints,
        y,
        Z,
        work1,
    )
end

function dimacserr3(
    k::CSDP_INT,
    C::blockmatrix,
    constraints::Ptr{constraintmatrix},
    y::Ptr{Cdouble},
    Z::blockmatrix,
    work1::blockmatrix,
)
    return ccall(
        (:dimacserr3, CSDP.libcsdp),
        Cdouble,
        (
            CSDP_INT,
            blockmatrix,
            Ptr{constraintmatrix},
            Ptr{Cdouble},
            blockmatrix,
            blockmatrix,
        ),
        k,
        C,
        constraints,
        y,
        Z,
        work1,
    )
end

function op_a(
    k::CSDP_INT,
    constraints::Ptr{constraintmatrix},
    X::blockmatrix,
    result::Ptr{Cdouble},
)
    return ccall(
        (:op_a, CSDP.libcsdp),
        Nothing,
        (CSDP_INT, Ptr{constraintmatrix}, blockmatrix, Ptr{Cdouble}),
        k,
        constraints,
        X,
        result,
    )
end

function op_at(
    k::CSDP_INT,
    y::Ptr{Cdouble},
    constraints::Ptr{constraintmatrix},
    result::blockmatrix,
)
    return ccall(
        (:op_at, CSDP.libcsdp),
        Nothing,
        (CSDP_INT, Ptr{Cdouble}, Ptr{constraintmatrix}, blockmatrix),
        k,
        y,
        constraints,
        result,
    )
end

function makefill(
    k::CSDP_INT,
    C::blockmatrix,
    constraints::Ptr{constraintmatrix},
    pfill::Ref{constraintmatrix},
    work1::blockmatrix,
    printlevel::CSDP_INT,
)
    return ccall(
        (:makefill, CSDP.libcsdp),
        Nothing,
        (
            CSDP_INT,
            blockmatrix,
            Ptr{constraintmatrix},
            Ref{constraintmatrix},
            blockmatrix,
            CSDP_INT,
        ),
        k,
        C,
        constraints,
        pfill,
        work1,
        printlevel,
    )
end

function op_o(
    k::CSDP_INT,
    constraints::Ptr{constraintmatrix},
    byblocks::Ptr{Ptr{sparseblock}},
    Zi::blockmatrix,
    X::blockmatrix,
    O::Ptr{Cdouble},
    work1::blockmatrix,
    work2::blockmatrix,
)
    return ccall(
        (:op_o, CSDP.libcsdp),
        Nothing,
        (
            CSDP_INT,
            Ptr{constraintmatrix},
            Ptr{Ptr{sparseblock}},
            blockmatrix,
            blockmatrix,
            Ptr{Cdouble},
            blockmatrix,
            blockmatrix,
        ),
        k,
        constraints,
        byblocks,
        Zi,
        X,
        O,
        work1,
        work2,
    )
end

function addscaledmat(
    A::blockmatrix,
    scale::Cdouble,
    B::blockmatrix,
    C::blockmatrix,
)
    return ccall(
        (:addscaledmat, CSDP.libcsdp),
        Nothing,
        (blockmatrix, Cdouble, blockmatrix, blockmatrix),
        A,
        scale,
        B,
        C,
    )
end

function zero_mat(A::blockmatrix)
    return ccall((:zero_mat, CSDP.libcsdp), Nothing, (blockmatrix,), A)
end

function add_mat(A::blockmatrix, B::blockmatrix)
    return ccall(
        (:add_mat, CSDP.libcsdp),
        Nothing,
        (blockmatrix, blockmatrix),
        A,
        B,
    )
end

function sym_mat(A::blockmatrix)
    return ccall((:sym_mat, CSDP.libcsdp), Nothing, (blockmatrix,), A)
end

function make_i(A::blockmatrix)
    return ccall((:make_i, CSDP.libcsdp), Nothing, (blockmatrix,), A)
end

function copy_mat(A::blockmatrix, B::blockmatrix)
    return ccall(
        (:copy_mat, CSDP.libcsdp),
        Nothing,
        (blockmatrix, blockmatrix),
        A,
        B,
    )
end

function mat_mult(
    scale1::Cdouble,
    scale2::Cdouble,
    A::blockmatrix,
    B::blockmatrix,
    C::blockmatrix,
)
    return ccall(
        (:mat_mult, CSDP.libcsdp),
        Nothing,
        (Cdouble, Cdouble, blockmatrix, blockmatrix, blockmatrix),
        scale1,
        scale2,
        A,
        B,
        C,
    )
end

function mat_multspa(
    scale1::Cdouble,
    scale2::Cdouble,
    A::blockmatrix,
    B::blockmatrix,
    C::blockmatrix,
    fill::constraintmatrix,
)
    return ccall(
        (:mat_multspa, CSDP.libcsdp),
        Nothing,
        (
            Cdouble,
            Cdouble,
            blockmatrix,
            blockmatrix,
            blockmatrix,
            constraintmatrix,
        ),
        scale1,
        scale2,
        A,
        B,
        C,
        fill,
    )
end

function mat_multspb(
    scale1::Cdouble,
    scale2::Cdouble,
    A::blockmatrix,
    B::blockmatrix,
    C::blockmatrix,
    fill::constraintmatrix,
)
    return ccall(
        (:mat_multspb, CSDP.libcsdp),
        Nothing,
        (
            Cdouble,
            Cdouble,
            blockmatrix,
            blockmatrix,
            blockmatrix,
            constraintmatrix,
        ),
        scale1,
        scale2,
        A,
        B,
        C,
        fill,
    )
end

function mat_multspc(
    scale1::Cdouble,
    scale2::Cdouble,
    A::blockmatrix,
    B::blockmatrix,
    C::blockmatrix,
    fill::constraintmatrix,
)
    return ccall(
        (:mat_multspc, CSDP.libcsdp),
        Nothing,
        (
            Cdouble,
            Cdouble,
            blockmatrix,
            blockmatrix,
            blockmatrix,
            constraintmatrix,
        ),
        scale1,
        scale2,
        A,
        B,
        C,
        fill,
    )
end

function mat_mult_raw(
    n::CSDP_INT,
    scale1::Cdouble,
    scale2::Cdouble,
    ap::Ptr{Cdouble},
    bp::Ptr{Cdouble},
    cp::Ptr{Cdouble},
)
    return ccall(
        (:mat_mult_raw, CSDP.libcsdp),
        Nothing,
        (CSDP_INT, Cdouble, Cdouble, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
        n,
        scale1,
        scale2,
        ap,
        bp,
        cp,
    )
end

function mat_mult_rawatlas(
    n::CSDP_INT,
    scale1::Cdouble,
    scale2::Cdouble,
    ap::Ptr{Cdouble},
    bp::Ptr{Cdouble},
    cp::Ptr{Cdouble},
)
    return ccall(
        (:mat_mult_rawatlas, CSDP.libcsdp),
        Nothing,
        (CSDP_INT, Cdouble, Cdouble, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
        n,
        scale1,
        scale2,
        ap,
        bp,
        cp,
    )
end

function matvec(A::blockmatrix, x::Ptr{Cdouble}, y::Ptr{Cdouble})
    return ccall(
        (:matvec, CSDP.libcsdp),
        Nothing,
        (blockmatrix, Ptr{Cdouble}, Ptr{Cdouble}),
        A,
        x,
        y,
    )
end

function alloc_mat(A::blockmatrix, pB::Ref{blockmatrix})
    return ccall(
        (:alloc_mat, CSDP.libcsdp),
        Nothing,
        (blockmatrix, Ref{blockmatrix}),
        A,
        pB,
    )
end

function free_mat(A::blockmatrix)
    return ccall((:free_mat, CSDP.libcsdp), Nothing, (blockmatrix,), A)
end

function initparams(params::Ptr{paramstruc}, pprintlevel::Ptr{CSDP_INT})
    return ccall(
        (:initparams, CSDP.libcsdp),
        Nothing,
        (Ptr{paramstruc}, Ptr{CSDP_INT}),
        params,
        pprintlevel,
    )
end

function loaded_initsoln(
    problem::Ptr{Cvoid},
    X::Ref{blockmatrix},
    Z::Ref{blockmatrix},
)
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
function initsoln(
    n::CSDP_INT,
    k::CSDP_INT,
    C::blockmatrix,
    a::Ptr{Cdouble},
    constraints::Ptr{constraintmatrix},
)
    X = Ref{blockmatrix}(blockmatrix(0, C_NULL))
    y = Ref{Ptr{Cdouble}}(C_NULL)
    Z = Ref{blockmatrix}(blockmatrix(0, C_NULL))
    ccall(
        (:initsoln, CSDP.libcsdp),
        Nothing,
        (
            CSDP_INT,
            CSDP_INT,
            blockmatrix,
            Ptr{Cdouble},
            Ptr{constraintmatrix},
            Ref{blockmatrix},
            Ref{Ptr{Cdouble}},
            Ref{blockmatrix},
        ),
        n,
        k,
        C,
        a,
        constraints,
        X,
        y,
        Z,
    )
    return X[], y[], Z[]
end

function trans(A::blockmatrix)
    return ccall((:trans, CSDP.libcsdp), Nothing, (blockmatrix,), A)
end

function chol_inv(A::blockmatrix, B::blockmatrix)
    return ccall(
        (:chol_inv, CSDP.libcsdp),
        Nothing,
        (blockmatrix, blockmatrix),
        A,
        B,
    )
end

function chol(A::blockmatrix)
    return ccall((:chol, CSDP.libcsdp), CSDP_INT, (blockmatrix,), A)
end

function solvesys(
    m::CSDP_INT,
    ldam::CSDP_INT,
    A::Ptr{Cdouble},
    rhs::Ptr{Cdouble},
)
    return ccall(
        (:solvesys, CSDP.libcsdp),
        CSDP_INT,
        (CSDP_INT, CSDP_INT, Ptr{Cdouble}, Ptr{Cdouble}),
        m,
        ldam,
        A,
        rhs,
    )
end

function user_exit(
    n::CSDP_INT,
    k::CSDP_INT,
    C::blockmatrix,
    a::Ptr{Cdouble},
    dobj::Cdouble,
    pobj::Cdouble,
    constant_offset::Cdouble,
    constraints::Ptr{constraintmatrix},
    X::blockmatrix,
    y::Ptr{Cdouble},
    Z::blockmatrix,
    params::paramstruc,
)
    return ccall(
        (:user_exit, CSDP.libcsdp),
        CSDP_INT,
        (
            CSDP_INT,
            CSDP_INT,
            blockmatrix,
            Ptr{Cdouble},
            Cdouble,
            Cdouble,
            Cdouble,
            Ptr{constraintmatrix},
            blockmatrix,
            Ptr{Cdouble},
            blockmatrix,
            paramstruc,
        ),
        n,
        k,
        C,
        a,
        dobj,
        pobj,
        constant_offset,
        constraints,
        X,
        y,
        Z,
        params,
    )
end

function read_sol(
    fname::Ptr{UInt8},
    n::CSDP_INT,
    k::CSDP_INT,
    C::blockmatrix,
    pX::Ptr{blockmatrix},
    py::Ptr{Ptr{Cdouble}},
    pZ::Ptr{blockmatrix},
)
    return ccall(
        (:read_sol, CSDP.libcsdp),
        CSDP_INT,
        (
            Ptr{UInt8},
            CSDP_INT,
            CSDP_INT,
            blockmatrix,
            Ptr{blockmatrix},
            Ptr{Ptr{Cdouble}},
            Ptr{blockmatrix},
        ),
        fname,
        n,
        k,
        C,
        pX,
        py,
        pZ,
    )
end

function load_prob_from_file(
    fname::String,
    C::Ref{blockmatrix},
    printlevel::Integer = 1,
)
    problem = Ref{Ptr{Cvoid}}(C_NULL)
    ret = ccall(
        (:load_prob_from_file, CSDP.libcsdp),
        CSDP_INT,
        (Ptr{UInt8}, Ref{blockmatrix}, Ref{Ptr{Cvoid}}, CSDP_INT),
        fname,
        C,
        problem,
        printlevel,
    )
    if !iszero(ret)
        error("`CSDP.load_prob_from_file` failed.")
    end
    return LoadingProblem(problem[])
end
function read_prob(fname::String, printlevel::Integer = 1)
    n = Ref{CSDP_INT}(0)
    k = Ref{CSDP_INT}(0)
    C = Ref{blockmatrix}(blockmatrix(0, C_NULL))
    a = Ref{Ptr{Cdouble}}(C_NULL)
    constraints = Ref{Ptr{constraintmatrix}}(C_NULL)
    ccall(
        (:read_prob, CSDP.libcsdp),
        CSDP_INT,
        (
            Ptr{UInt8},
            Ref{CSDP_INT},
            Ref{CSDP_INT},
            Ref{blockmatrix},
            Ref{Ptr{Cdouble}},
            Ref{Ptr{constraintmatrix}},
            CSDP_INT,
        ),
        fname,
        n,
        k,
        C,
        a,
        constraints,
        printlevel,
    )
    C = mywrap(C[])
    a = mywrap(a[], k[])
    constraints = mywrap(constraints[], k[])
    # Nothing to free as the constraintmatrix is immutable
    # the array is allocated as an array of bitstype in CSDP
    # the array of blocks, .. inside should be free'd though
    #constraints = map(c->ConstraintMatrix(c, k[]), constraints)
    @assert n[] == size(C, 1)
    return C, a, constraints
end

function write_prob(
    fname::String,
    n::CSDP_INT,
    k::CSDP_INT,
    C::blockmatrix,
    a::Ptr{Cdouble},
    constraints::Ptr{constraintmatrix},
)
    return ccall(
        (:write_prob, CSDP.libcsdp),
        CSDP_INT,
        (
            Ptr{UInt8},
            CSDP_INT,
            CSDP_INT,
            blockmatrix,
            Ptr{Cdouble},
            Ptr{constraintmatrix},
        ),
        fname,
        n,
        k,
        C,
        a,
        constraints,
    )
end

function write_sol(
    fname::String,
    n::CSDP_INT,
    k::CSDP_INT,
    X::blockmatrix,
    y::Ptr{Cdouble},
    Z::blockmatrix,
)
    return ccall(
        (:write_sol, CSDP.libcsdp),
        CSDP_INT,
        (
            Ptr{UInt8},
            CSDP_INT,
            CSDP_INT,
            blockmatrix,
            Ptr{Cdouble},
            blockmatrix,
        ),
        fname,
        n,
        k,
        X,
        y,
        Z,
    )
end

function free_prob(
    n::CSDP_INT,
    k::CSDP_INT,
    C::blockmatrix,
    a::Ptr{Cdouble},
    constraints::Ptr{constraintmatrix},
    X::blockmatrix,
    y::Ptr{Cdouble},
    Z::blockmatrix,
)
    return ccall(
        (:free_prob, CSDP.libcsdp),
        Nothing,
        (
            CSDP_INT,
            CSDP_INT,
            blockmatrix,
            Ptr{Cdouble},
            Ptr{constraintmatrix},
            blockmatrix,
            Ptr{Cdouble},
            blockmatrix,
        ),
        n,
        k,
        C,
        a,
        constraints,
        X,
        y,
        Z,
    )
end

#function new_blockmatrix(nblocks::Integer)
#    return ccall((:new_blockmatrix,CSDP.libcsdp),Ptr{Cvoid},(CSDP_INT,),nblocks)
#end
#function free_blockmatrix(C::Ptr{Cvoid})
#    ccall((:free_blockmatrix,CSDP.libcsdp),Nothing,(Ptr{Cvoid},),C)
#end

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
function getblockrec(A::blockmatrix, i::Integer)
    return ccall(
        (:getblockrec, CSDP.libcsdp),
        blockrec,
        (blockmatrix, CSDP_INT),
        A,
        i,
    )
end

function allocate_loading_prob(
    pC::Ref{blockmatrix},
    block_dims::Ptr{CSDP_INT},
    num_constraints::Integer,
    num_entries::Ptr{CSDP_INT},
    printlevel::Integer,
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
function free_loading_prob(problem::Ptr{Cvoid})
    return ccall(
        (:free_loading_prob, CSDP.libcsdp),
        Nothing,
        (Ptr{Cvoid},),
        problem,
    )
end
function free_loaded_prob(
    problem::Ptr{Cvoid},
    X::blockmatrix,
    y::Ptr{Cdouble},
    Z::blockmatrix,
)
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

function setconstant(problem::Ptr{Cvoid}, mat::Integer, ent::Cdouble)
    return ccall(
        (:setconstant, CSDP.libcsdp),
        Nothing,
        (Ptr{Cvoid}, CSDP_INT, Cdouble),
        problem,
        mat,
        ent,
    )
end
function addentry(
    problem::Ptr{Cvoid},
    mat::Integer,
    blk::Integer,
    indexi::Integer,
    indexj::Integer,
    ent::Cdouble,
    allow_duplicates::Integer,
)
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

function sdp(
    n::CSDP_INT,
    k::CSDP_INT,
    C::blockmatrix,
    a::Ptr{Cdouble},
    constant_offset::Cdouble,
    constraints::Ptr{constraintmatrix},
    byblocks::Ptr{Ptr{sparseblock}},
    X::blockmatrix,
    y::Ptr{Cdouble},
    Z::blockmatrix,
    workvec1::Ptr{Cdouble},
    workvec2::Ptr{Cdouble},
    workvec3::Ptr{Cdouble},
    workvec4::Ptr{Cdouble},
    workvec5::Ptr{Cdouble},
    workvec6::Ptr{Cdouble},
    workvec7::Ptr{Cdouble},
    workvec8::Ptr{Cdouble},
    diagO::Ptr{Cdouble},
    besty::Ptr{Cdouble},
    O::Ptr{Cdouble},
    rhs::Ptr{Cdouble},
    dy::Ptr{Cdouble},
    dy1::Ptr{Cdouble},
    Fp::Ptr{Cdouble},
    printlevel::CSDP_INT,
    parameters::paramstruc,
)
    pobj = Ref{Cdouble}(0.0)
    dobj = Ref{Cdouble}(0.0)

    work1 = blockmatrix()
    alloc_mat(C, Ref{blockmatrix}(work1))
    work2 = blockmatrix()
    alloc_mat(C, Ref{blockmatrix}(work2))
    work3 = blockmatrix()
    alloc_mat(C, Ref{blockmatrix}(work3))
    bestx = blockmatrix()
    alloc_mat_packed(C, Ref{blockmatrix}(bestx))
    bestz = blockmatrix()
    alloc_mat_packed(C, Ref{blockmatrix}(bestz))
    cholxinv = blockmatrix()
    alloc_mat_packed(C, Ref{blockmatrix}(cholxinv))
    cholzinv = blockmatrix()
    alloc_mat_packed(C, Ref{blockmatrix}(cholzinv))
    Zi = blockmatrix()
    alloc_mat(C, Ref{blockmatrix}(Zi))
    dZ = blockmatrix()
    alloc_mat(C, Ref{blockmatrix}(dZ))
    dX = blockmatrix()
    alloc_mat(C, Ref{blockmatrix}(dX))

    fill = Ref{constraintmatrix}(constraintmatrix(C_NULL))
    makefill(k, C, constraints, fill, work1, printlevel)

    structnnz(n, k, C, constraints)

    sort_entries(k, C, constraints)

    status = ccall(
        (:sdp, CSDP.libcsdp),
        CSDP_INT,
        (
            CSDP_INT,
            CSDP_INT, # n, k
            blockmatrix,
            Ptr{Cdouble},
            Cdouble,
            Ptr{constraintmatrix},
            Ptr{Ptr{sparseblock}},
            constraintmatrix, # byblocks, fill
            blockmatrix,
            Ptr{Cdouble},
            blockmatrix,
            blockmatrix,
            blockmatrix,            # cholxinv, cholzinv
            Ref{Cdouble},
            Ref{Cdouble},          # pobj, dobj
            blockmatrix,
            blockmatrix,
            blockmatrix, # work1, work2, work3
            Ptr{Cdouble},
            Ptr{Cdouble},
            Ptr{Cdouble},
            Ptr{Cdouble},
            Ptr{Cdouble},
            Ptr{Cdouble},
            Ptr{Cdouble},
            Ptr{Cdouble},
            Ptr{Cdouble},            # diagO
            blockmatrix,             # bestx
            Ptr{Cdouble},            # besty
            blockmatrix,
            blockmatrix, # bestz, Zi
            Ptr{Cdouble},
            Ptr{Cdouble},
            blockmatrix,
            blockmatrix,
            Ptr{Cdouble},
            Ptr{Cdouble},
            Ptr{Cdouble},
            CSDP_INT,
            paramstruc,
        ),
        n,
        k,
        C,
        a,
        constant_offset,
        constraints,
        byblocks,
        fill[],
        X,
        y,
        Z,
        cholxinv,
        cholzinv,
        pobj,
        dobj,
        work1,
        work2,
        work3,
        workvec1,
        workvec2,
        workvec3,
        workvec4,
        workvec5,
        workvec6,
        workvec7,
        workvec8,
        diagO,
        bestx,
        besty,
        bestz,
        Zi,
        O,
        rhs,
        dZ,
        dX,
        dy,
        dy1,
        Fp,
        printlevel,
        parameters,
    )

    free_mat(work1)
    free_mat(work2)
    free_mat(work3)
    free_mat_packed(bestx)
    free_mat_packed(bestz)
    free_mat_packed(cholxinv)
    free_mat_packed(cholzinv)

    free_mat(Zi)
    free_mat(dZ)
    free_mat(dX)

    return status, pobj[], dobj[]
end

function loaded_sdp(
    problem::Ptr{Cvoid},
    constant_offset::Cdouble,
    pX::Ref{blockmatrix},
    py::Ref{Ptr{Cdouble}},
    pZ::Ref{blockmatrix},
    printlevel::CSDP_INT,
    parameters::paramstruc,
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
function parametrized_sdp(
    n::CSDP_INT,
    k::CSDP_INT,
    C::blockmatrix,
    a::Ptr{Cdouble},
    constraints::Ptr{constraintmatrix},
    constant_offset::Cdouble,
    pX::Ptr{blockmatrix},
    py::Ref{Ptr{Cdouble}},
    pZ::Ptr{blockmatrix},
    printlevel::CSDP_INT,
    parameters::paramstruc,
)
    pobj = Ref{Cdouble}(0.0)
    dobj = Ref{Cdouble}(0.0)
    status = ccall(
        (:parametrized_sdp, CSDP.libcsdp),
        CSDP_INT,
        (
            CSDP_INT,
            CSDP_INT,
            blockmatrix,
            Ptr{Cdouble},
            Ptr{constraintmatrix},
            Cdouble,
            Ptr{blockmatrix},
            Ref{Ptr{Cdouble}},
            Ptr{blockmatrix},
            Ref{Cdouble},
            Ref{Cdouble},
            CSDP_INT,
            paramstruc,
        ),
        n,
        k,
        C,
        a,
        constraints,
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
function easy_sdp(
    n::CSDP_INT,
    k::CSDP_INT,
    C::blockmatrix,
    a::Ptr{Cdouble},
    constraints::Ptr{constraintmatrix},
    constant_offset::Cdouble,
    pX::Ptr{blockmatrix},
    py::Ref{Ptr{Cdouble}},
    pZ::Ptr{blockmatrix},
)
    pobj = Ref{Cdouble}(0.0)
    dobj = Ref{Cdouble}(0.0)
    status = ccall(
        (:easy_sdp, CSDP.libcsdp),
        CSDP_INT,
        (
            CSDP_INT,
            CSDP_INT,
            blockmatrix,
            Ptr{Cdouble},
            Ptr{constraintmatrix},
            Cdouble,
            Ptr{blockmatrix},
            Ref{Ptr{Cdouble}},
            Ptr{blockmatrix},
            Ref{Cdouble},
            Ref{Cdouble},
        ),
        n,
        k,
        C,
        a,
        constraints,
        constant_offset,
        pX,
        py,
        pZ,
        pobj,
        dobj,
    )
    return status, pobj[], dobj[]
end

function tweakgap(
    n::CSDP_INT,
    k::CSDP_INT,
    a::Ptr{Cdouble},
    constraints::Ptr{constraintmatrix},
    gap::Cdouble,
    Z::blockmatrix,
    dZ::blockmatrix,
    y::Ptr{Cdouble},
    dy::Ptr{Cdouble},
    work1::blockmatrix,
    work2::blockmatrix,
    work3::blockmatrix,
    work4::blockmatrix,
    workvec1::Ptr{Cdouble},
    workvec2::Ptr{Cdouble},
    workvec3::Ptr{Cdouble},
    workvec4::Ptr{Cdouble},
    printlevel::CSDP_INT,
)
    return ccall(
        (:tweakgap, CSDP.libcsdp),
        Nothing,
        (
            CSDP_INT,
            CSDP_INT,
            Ptr{Cdouble},
            Ptr{constraintmatrix},
            Cdouble,
            blockmatrix,
            blockmatrix,
            Ptr{Cdouble},
            Ptr{Cdouble},
            blockmatrix,
            blockmatrix,
            blockmatrix,
            blockmatrix,
            Ptr{Cdouble},
            Ptr{Cdouble},
            Ptr{Cdouble},
            Ptr{Cdouble},
            CSDP_INT,
        ),
        n,
        k,
        a,
        constraints,
        gap,
        Z,
        dZ,
        y,
        dy,
        work1,
        work2,
        work3,
        work4,
        workvec1,
        workvec2,
        workvec3,
        workvec4,
        printlevel,
    )
end

function bisect_(
    n::Ptr{CSDP_INT},
    eps1::Ptr{Cdouble},
    d::Ptr{Cdouble},
    e::Ptr{Cdouble},
    e2::Ptr{Cdouble},
    lb::Ptr{Cdouble},
    ub::Ptr{Cdouble},
    mm::Ptr{CSDP_INT},
    m::Ptr{CSDP_INT},
    w::Ptr{Cdouble},
    ind::Ptr{CSDP_INT},
    ierr::Ptr{CSDP_INT},
    rv4::Ptr{Cdouble},
    rv5::Ptr{Cdouble},
)
    return ccall(
        (:bisect_, CSDP.libcsdp),
        CSDP_INT,
        (
            Ptr{CSDP_INT},
            Ptr{Cdouble},
            Ptr{Cdouble},
            Ptr{Cdouble},
            Ptr{Cdouble},
            Ptr{Cdouble},
            Ptr{Cdouble},
            Ptr{CSDP_INT},
            Ptr{CSDP_INT},
            Ptr{Cdouble},
            Ptr{CSDP_INT},
            Ptr{CSDP_INT},
            Ptr{Cdouble},
            Ptr{Cdouble},
        ),
        n,
        eps1,
        d,
        e,
        e2,
        lb,
        ub,
        mm,
        m,
        w,
        ind,
        ierr,
        rv4,
        rv5,
    )
end
