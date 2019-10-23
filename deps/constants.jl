# use Julia's libopenblas instead of system's liblapack and libblas?
const version      = "6.2.0"
const libname      = "libcsdp.$(Libdl.dlext)"
const csdpversion  = "Csdp-readprob"
const download_url =
    "https://github.com/blegat/Csdp/archive/readprob.zip"

patchf      = joinpath(dirname(@__FILE__), "src", "debug-mat.c")
srcdir      = joinpath(dirname(@__FILE__), "src", csdpversion, "lib")
prefix      = joinpath(dirname(@__FILE__), "usr")
builddir    = joinpath(dirname(@__FILE__), "build")
cflags      = ["-I$srcdir/../include",  "-DNOSHORTS", "-g"]
libdir      = joinpath(prefix, @static Sys.iswindows() ? "bin" : "lib/")
dlpath      = joinpath(libdir, libname)
Makefile    = joinpath(srcdir, "Makefile")
CC          = get(ENV, "CCOMPILER", "gcc")

"""Name of the current Git branch"""
git_branch() = chomp(read(`git rev-parse --abbrev-ref HEAD`, String))
