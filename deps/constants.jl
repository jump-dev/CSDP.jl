# use Julia's libopenblas instead of system's liblapack and libblas?
const JULIA_LAPACK = false
const version = "6.1.1"
const libname = "libcsdp.$(Libdl.dlext)"
const csdpversion = JULIA_LAPACK ? "Csdp-$version.64" : "Csdp-$version"
const download_url =
    "http://www.coin-or.org/download/source/Csdp/Csdp-$version.tgz"

patchf      = Pkg.dir("CSDP", "deps", "src", "debug-mat.c")
srcdir      = Pkg.dir("CSDP", "deps", "src", csdpversion, "lib")
prefix      = Pkg.dir("CSDP", "deps", "usr")
builddir    = Pkg.dir("CSDP", "deps", "build")
cflags      = ["-I$srcdir/../include",  "-DNOSHORTS", "-g"]
libdir      = joinpath(prefix, @static is_windows() ? "bin" : "lib/")
dlpath      = joinpath(libdir, libname)
Makefile    = joinpath(srcdir, "Makefile")

CC = get(ENV, "CCOMPILER", "gcc")
