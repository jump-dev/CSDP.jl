# Test Julia's Ref mechanism and compare it to Ptr.
#

if !isdefined(:libn)
    const libn = Pkg.dir("CSDP", "deps", "usr", "lib", "ref.$(Libdl.dlext)")
    mkdir(libn)
    const refc = Pkg.dir("CSDP", "test", "ref.c")
end
run(`gcc -fPIC -shared -o $libn -std=c99 $refc`)

const OP1 = UInt32(0)
const OP2 = UInt32(1)

"""Simple type containing an enum and Ptr"""
type S
    c::UInt32
    n::Cint
    e::Ptr{Cdouble}
end


"""Use Ref instead of Ptr"""
type R
    c::UInt32
    n::Cint
    e::Ref{Cdouble}
end

# Say hello, print sizeof(int)
println(ccall((:hello,libn), Cdouble, ()))

vec = Cdouble[1.0, 2.0]
println("&vec = $(pointer(vec))")

# Call with S --> should work
s = S(OP1, length(vec), pointer(vec))
ccall((:sum,libn), Cdouble, (S,), s)

# Call with R --> does not work
r = R(OP2, length(vec), Ref(vec))
ccall((:sum,libn), Cdouble, (R,), r)

# Now call with S, instead of R
Base.cconvert(::Type{S}, r::R) =
    S(r.c, r.n, Base.unsafe_convert(Ptr{Cdouble}, r.e))
ccall((:sum,libn), Cdouble, (S,), r)
