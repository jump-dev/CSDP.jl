module TestJlRef

code = """
struct S {
  int n;
  double *e;
};
double sum(struct S s) {
  double r = 0;
  for (int i = 0; i < s.n; i++)
    r += s.e[i];
  return r;
}
"""

libn = Pkg.dir("CSDP", "deps", "usr", "lib", "ref.$(Libdl.dlext)")
open(`gcc -fPIC -shared -o $libn -std=c99 -x c -`, "w", STDOUT) do io
    println(io, code)
end

type S
    n::Cint
    e::Ref{Cdouble}
end


vec = Cdouble[1.0, 2.0]

s = S(length(vec), Ref(vec))

ccall((:sum,libn), Cdouble, (S,), s)

end # module
