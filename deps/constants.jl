# use Julia's libopenblas instead of system's liblapack and libblas?
const JULIA_LAPACK = false
const suffix       = JULIA_LAPACK ? ".64" : ""
const version      = "6.2.0"
const libname      = "libcsdp$suffix.$(Libdl.dlext)"
const csdpversion  = "Csdp-$version"
const download_url =
    "http://www.coin-or.org/download/source/Csdp/Csdp-$version.tgz"

patchf      = joinpath(dirname(@__FILE__), "src$suffix", "debug-mat.c")
srcdir      = joinpath(dirname(@__FILE__), "src$suffix", csdpversion, "lib")
prefix      = joinpath(dirname(@__FILE__), "usr")
builddir    = joinpath(dirname(@__FILE__), "build$suffix")
cflags      = ["-I$srcdir/../include",  "-DNOSHORTS", "-g"]
libdir      = joinpath(prefix, @static Sys.iswindows() ? "bin" : "lib/")
dlpath      = joinpath(libdir, libname)
Makefile    = joinpath(srcdir, "Makefile")
CC          = get(ENV, "CCOMPILER", "gcc")

"""Name of the current Git branch"""
git_branch() = chomp(read(`git rev-parse --abbrev-ref HEAD`, String))
