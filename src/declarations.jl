export initsoln, easy_sdp

function initsoln(C::BlockMatrix, b::Vector{Cdouble}, As::Vector{constraintmatrix})
    m = length(As)
    X, y, Z = initsoln(Cint(size(C, 1)), Cint(m), C.csdp, fptr(b), fptr(As))
    mywrap(X), mywrap(y, m), mywrap(Z)
end
function initsoln(C::BlockMatrix, b::Vector{Cdouble}, As::Vector{ConstraintMatrix})
    initsoln(C, b, [A.csdp for A in As])
end

function setupAs!(As::Vector{ConstraintMatrix}, C::BlockMatrix)
    # See lib/easysdp.c
    # Fills info in each ConstraintMatrix that couldn't be determined before
    # since it needs info about block category (which is in C) and other constraints matrices

    nblocks = length(C.blocks)

    byblocks = Vector{Ptr{sparseblock}}(nblocks)
    fill!(byblocks, C_NULL)

    for constr in length(As):-1:1
        A = As[constr]
        @assert nblocks == length(A.jblocks)
        for blk in 1:nblocks
            jblock = A.jblocks[blk]
            if jblock.csdp.numentries > 0.25 * jblock.csdp.blocksize && jblock.csdp.numentries > 15
                jblock.csdp.issparse = 0
            else
                jblock.csdp.issparse = 1
            end

            if C.blocks[jblock.csdp.blocknum].blockcategory == DIAG
                jblock.csdp.issparse = 1
            end

            jblock.csdp.nextbyblock = byblocks[blk]
            byblocks[blk] = pointer_from_objref(jblock.csdp)
        end
    end
    byblocks
end

sdp(C::BlockMatrix, b::Vector{Cdouble}, As::Vector{ConstraintMatrix}, X::BlockMatrix, y::Vector{Cdouble}, Z::BlockMatrix, params::Dict{Symbol}) = sdp(C, b, As, X, y, Z, options(params)...)
function sdp(C::BlockMatrix, b::Vector{Cdouble}, As::Vector{ConstraintMatrix}, X::BlockMatrix, y::Vector{Cdouble}, Z::BlockMatrix, printlevel, params)
    # I pass pointers pX, py and pZ to X, y and Z but only *pX, *py and *pZ are use in the code
    # so no need to worry, they won't change :)
    Xcsdp = X.csdp
    ycsdp = fptr(y)
    Zcsdp = Z.csdp
    Ascsdp = map(A->A.csdp, As)

    n = Cint(size(C, 1))
    k = Cint(length(As))
    nd = sizeof(Cdouble) * (n+1)
    kd = sizeof(Cdouble) * (k+1)
    md = max(nd, kd)
    ldam = (iseven(k) ? k+1 : k)
    ld = sizeof(Cdouble) * ldam * ldam

    byblocks = setupAs!(As, C)

    status, pobj, dobj = sdp(n,                             # n::Cint
                             k,                             # k::Cint
                             C.csdp,                        # C::blockmatrix
                             fptr(b),                       # a::Ptr{Cdouble}
                             0.0,                           # constant_offset::Cdouble
                             fptr(Ascsdp),                  # constraints::Ptr{constraintmatrix}
                             fptr(byblocks),
                             Xcsdp,                         # X::blockmatrix
                             ycsdp,                         # y::Ptr{Cdouble}
                             Zcsdp,                         # Z::blockmatrix
                             pointer(Vector{Cdouble}(md)),  # workvec1::Ptr{Cdouble}
                             pointer(Vector{Cdouble}(md)),  # workvec2::Ptr{Cdouble}
                             pointer(Vector{Cdouble}(md)),  # workvec3::Ptr{Cdouble}
                             pointer(Vector{Cdouble}(md)),  # workvec4::Ptr{Cdouble}
                             pointer(Vector{Cdouble}(md)),  # workvec5::Ptr{Cdouble}
                             pointer(Vector{Cdouble}(md)),  # workvec6::Ptr{Cdouble}
                             pointer(Vector{Cdouble}(md)),  # workvec7::Ptr{Cdouble}
                             pointer(Vector{Cdouble}(md)),  # workvec8::Ptr{Cdouble}
                             pointer(Vector{Cdouble}(md)),  # diagO::Ptr{Cdouble}
                             pointer(Vector{Cdouble}(kd)),  # besty::Ptr{Cdouble}
                             pointer(Vector{Cdouble}(ld)),  # O::Ptr{Cdouble}
                             pointer(Vector{Cdouble}(kd)),  # rhs::Ptr{Cdouble}
                             pointer(Vector{Cdouble}(kd)),  # dy::Ptr{Cdouble}
                             pointer(Vector{Cdouble}(kd)),  # dy1::Ptr{Cdouble}
                             pointer(Vector{Cdouble}(kd)),  # Fp::Ptr{Cdouble}
                             Cint(printlevel),              # printlevel::Cint
                             params)                        # parameters::paramstruc
    # I can even assert that they won't change
    @assert Xcsdp == X.csdp
    @assert ycsdp == fptr(y)
    @assert Zcsdp == Z.csdp
    status, pobj, dobj
end


function easy_sdp(C::BlockMatrix, b::Vector{Cdouble}, As::Vector{constraintmatrix}, X::BlockMatrix, y::Vector{Cdouble}, Z::BlockMatrix, verbose=false)
    # I pass pointers pX, py and pZ to X, y and Z but only *pX, *py and *pZ are use in the code
    # so no need to worry, they won't change :)
    Xcsdp = X.csdp
    ycsdp = fptr(y)
    Zcsdp = Z.csdp
    # https://thenewphalls.wordpress.com/2014/03/21/capturing-output-in-julia/
    if !verbose
        oldstdout = STDOUT
        rd, wr = redirect_stdout()
    end

    status, pobj, dobj = easy_sdp(Cint(size(C, 1)), # n::Cint
                                  Cint(length(As)), # k::Cint
                                  C.csdp,           # C::blockmatrix
                                  fptr(b),          # a::Ptr{Cdouble}
                                  fptr(As),         # constraints::Ptr{constraintmatrix}
                                  0.0,              # constant_offset::Cdouble
                                  ptr(Xcsdp),       # pX::Ptr{blockmatrix}
                                  ptr(ycsdp),       # py::Ptr{Ptr{Cdouble}}
                                  ptr(Zcsdp))       # pZ::Ptr{blockmatrix}
    if !verbose
        redirect_stdout(oldstdout)
    end
    # I can even assert that they won't change
    @assert Xcsdp == X.csdp
    @assert ycsdp == fptr(y)
    @assert Zcsdp == Z.csdp
    status, pobj, dobj
end

function write_prob(fname::String, C::BlockMatrix, b::Vector{Cdouble}, As::Vector{constraintmatrix})
    write_prob(fname, Cint(size(C, 1)), Cint(length(As)), C.csdp, fptr(b), fptr(As))
end

function write_sol(fname::String, X::BlockMatrix, y::Vector{Cdouble}, Z::BlockMatrix)
    write_sol(fname, Cint(size(X, 1)), Cint(length(y)), X.csdp, fptr(y), Z.csdp)
end
