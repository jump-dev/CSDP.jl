using BinDeps

@BinDeps.setup

include("constants.jl")
include("compile.jl")

# blas = library_dependency("libblas")
# lapack = library_dependency("liblapack")
csdp = library_dependency("csdp", aliases=[libname])

provides(Sources,
         URI("http://www.coin-or.org/download/source/Csdp/Csdp-$version.tgz"),
         csdp,
         unpacked_dir="Csdp-$version")


provides(SimpleBuild,
         (@build_steps begin
             GetSources(csdp)
             CreateDirectory(libdir)
             CreateDirectory(builddir)
             @build_steps begin
                  ChangeDirectory(srcdir)
                  compile_objs
             end
         end),
         [csdp])


# TODO: provide win32 binaries
# http://icl.cs.utk.edu/lapack-for-windows/lapack/#libraries_mingw
# provides(Binaries,
#    URI("http://icl.cs.utk.edu/lapack-for-windows/libraries/VisualStudio/3.6.0/Dynamic-MINGW/Win64/liblapack.dll"),
#    [lapack], unpacked_dir="bin$WORD_SIZE", os = :Windows)

# provides(Binaries,
#    URI("http://icl.cs.utk.edu/lapack-for-windows/libraries/VisualStudio/3.6.0/Dynamic-MINGW/Win64/libblas.dll"),
#    [blas], unpacked_dir="bin$WORD_SIZE", os = :Windows)


@BinDeps.install Dict(:csdp => :csdp)
