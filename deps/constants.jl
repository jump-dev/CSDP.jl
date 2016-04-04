const version = "6.1.1"
const libname = "libcsdp.$(Libdl.dlext)"
const csdpversion = "Csdp-$version"

cflags      = ["-I$srcdir/../include",  "-DNOSHORTS"]
patchf      = Pkg.dir("CSDP", "deps", "src", "debug-mat.c")
srcdir      = Pkg.dir("CSDP", "deps", "src", csdpversion, "lib")
prefix      = Pkg.dir("CSDP", "deps", "usr")
builddir    = Pkg.dir("CSDP", "deps", "build")
libdir      = joinpath(prefix, "lib/")
dlpath      = joinpath(libdir, libname)
Makefile    = joinpath(srcdir, "Makefile")
