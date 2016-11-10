# use Julia's libopenblas instead of system's liblapack and libblas?
const JULIA_LAPACK = true
const suffix       = JULIA_LAPACK ? ".64" : ""
const version      = "6.1.1"
const libname      = "libcsdp$suffix.$(Libdl.dlext)"
const csdpversion  = "Csdp-$version$suffix"
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
CC          = get(ENV, "CCOMPILER", "gcc")

