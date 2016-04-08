const version = "6.1.1"
const libname = "libcsdp.$(Libdl.dlext)"
const csdpversion = "Csdp-$version"

patchf      = Pkg.dir("CSDP", "deps", "src", "debug-mat.c")
srcdir      = Pkg.dir("CSDP", "deps", "src", csdpversion, "lib")
prefix      = Pkg.dir("CSDP", "deps", "usr")
builddir    = Pkg.dir("CSDP", "deps", "build")
cflags      = ["-I$srcdir/../include",  "-DNOSHORTS", "-g"]
libdir      = joinpath(prefix, @windows? "bin" : "lib/")
dlpath      = joinpath(libdir, libname)
Makefile    = joinpath(srcdir, "Makefile")

JULIA_LAPACK = false
CC = get(ENV, "CCOMPILER", "gcc")
