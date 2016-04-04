using BinDeps

@BinDeps.setup

include("constants.jl")
include("compile.jl")

if !JULIA_LAPACK
    @windows_only begin
        info("Downloading DLLs to $libdir")
        mkpath(libdir)
        download("http://icl.cs.utk.edu/lapack-for-windows/libraries/VisualStudio/3.6.0/Dynamic-MINGW/Win64/liblapack.dll", "$libdir/liblapack.dll")
        download("http://icl.cs.utk.edu/lapack-for-windows/libraries/VisualStudio/3.6.0/Dynamic-MINGW/Win64/libblas.dll", "$libdir/libblas.dll")
        depends = []
    end

    if false
        blas = library_dependency("libblas", alias=["libblas.dll"])
        lapack = library_dependency("liblapack", alias=["libblas.dll"])
        depends = [blas, lapack]
    end
else
    depends = []
end

info("libname = $libname")

csdp = library_dependency("csdp", aliases=[libname], depends=depends)

provides(Sources,
         URI("http://www.coin-or.org/download/source/Csdp/Csdp-$version.tgz"),
         csdp,
         unpacked_dir="Csdp-$version")


provides(BuildProcess,
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


@windows_only push!(BinDeps.defaults, BuildProcess)
@BinDeps.install Dict(:csdp => :csdp)
@windows_only pop!(BinDeps.defaults)
