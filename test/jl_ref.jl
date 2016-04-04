if !isdefined(:libn)
    const libn = Pkg.dir("CSDP", "deps", "usr", "lib", "ref.$(Libdl.dlext)")
end
run(`gcc -fPIC -shared -o $libn -std=c99 ref.c`)

type S
    n::Cint
    e::Ref{Cdouble}
end


vec = Cdouble[1.0, 2.0]

s = S(length(vec), Ref(vec))

ccall((:sum,libn), Cdouble, (S,), s)

