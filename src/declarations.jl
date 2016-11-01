export initsoln, easy_sdp

type Cvector{T}
    e::Ptr{T}
end
mypointer{T}(x::Cvector{T}) = reinterpret(Ptr{Ptr{T}}, pointer_from_objref(x))
function initsoln(C::BlockMatrix, b::Vector{Cdouble}, As::Vector{constraintmatrix})
    Xcsdp = CSDP.blockmatrix(0, C_NULL)
    ycsdp = Cvector{Cdouble}(C_NULL)
    Zcsdp = CSDP.blockmatrix(0, C_NULL)
    m = length(As)
    initsoln(Cint(size(C, 1)), Cint(m), C.csdp, fptr(b), fptr(As), ptr(Xcsdp), mypointer(ycsdp), ptr(Zcsdp))
    finalizer(Xcsdp, free_blockmatrix)
    X = BlockMatrix(Xcsdp)
    finalizer(Zcsdp, free_blockmatrix)
    Z = BlockMatrix(Zcsdp)
    # I give false to unsafe_wrap to specify that Julia do not own the array so it should not free it
    # because the pointer it has has an offset
    y = unsafe_wrap(Array, ycsdp.e + sizeof(Cdouble), m, false)
    # fptr takes care of this offset
    finalizer(y, s -> Libc.free(fptr(s)))
    X, y, Z
end
function initsoln(C::BlockMatrix, b::Vector{Cdouble}, As::Vector{ConstraintMatrix})
    initsoln(C, b, [A.csdp for A in As])
end

function easy_sdp(C::BlockMatrix, b::Vector{Cdouble}, As::Vector{constraintmatrix}, X::BlockMatrix, y::Vector{Cdouble}, Z::BlockMatrix)
    pobj = Cdouble[0.0]
    dobj = Cdouble[0.0]
    # I pass pointers pX, py and pZ to X, y and Z but only *pX, *py and *pZ are use in the code
    # so no need to worry, they won't change :)
    Xcsdp = X.csdp
    ycsdp = fptr(y)
    Zcsdp = Z.csdp
    easy_sdp(Cint(size(C, 1)), Cint(length(As)), C.csdp, fptr(b), fptr(As), 0.0, ptr(Xcsdp), ptr(ycsdp), ptr(Zcsdp), pointer(pobj), pointer(dobj))
    # I can even assert that they won't change
    @assert Xcsdp == X.csdp
    @assert ycsdp == fptr(y)
    @assert Zcsdp == Z.csdp
    pobj[1], dobj[1]
end

function write_prob(fname::String, C::BlockMatrix, b::Vector{Cdouble}, As::Vector{constraintmatrix})
    write_prob(fname, Cint(size(C, 1)), Cint(length(As)), C.csdp, fptr(b), fptr(As))
end

function write_sol(fname::String, X::BlockMatrix, y::Vector{Cdouble}, Z::BlockMatrix)
    write_sol(fname, Cint(size(X, 1)), Cint(length(y)), X.csdp, fptr(y), Z.csdp)
end
