if !isdefined(:libn)
    const libn = Pkg.dir("CSDP", "deps", "usr", "lib", "ref.$(Libdl.dlext)")
end
run(`gcc -fPIC -shared -o $libn -std=c99 ref.c`)

type S
    n::Cint
    e::Ptr{Cdouble}
end


vec = Cdouble[1.0, 2.0]

println("&vec = $(pointer(vec))")
s = S(length(vec), pointer(vec))

println(ccall((:hello,libn), Cdouble, ()))

ccall((:sum,libn), Cdouble, (S,), s)
