export initsoln, easy_sdp

function initsoln(C::BlockMatrix, b::Vector{Cdouble}, As::Vector{constraintmatrix})
    m = length(As)
    X, y, Z = initsoln(BlasInt(size(C, 1)), BlasInt(m), C.csdp, fptr(b), fptr(As))
    mywrap(X), mywrap(y, m), mywrap(Z)
end
function initsoln(C::BlockMatrix, b::Vector{Cdouble}, As::Vector{ConstraintMatrix})
    initsoln(C, b, [A.csdp for A in As])
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
    status, pobj, dobj = easy_sdp(BlasInt(size(C, 1)), BlasInt(length(As)), C.csdp, fptr(b), fptr(As), 0.0, ptr(Xcsdp), ptr(ycsdp), ptr(Zcsdp))
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
    write_prob(fname, BlasInt(size(C, 1)), BlasInt(length(As)), C.csdp, fptr(b), fptr(As))
end

function write_sol(fname::String, X::BlockMatrix, y::Vector{Cdouble}, Z::BlockMatrix)
    write_sol(fname, BlasInt(size(X, 1)), BlasInt(length(y)), X.csdp, fptr(y), Z.csdp)
end
