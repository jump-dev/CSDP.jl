using BinDeps

@BinDeps.setup

include("constants.jl")
include("compile.jl")
# info("libname = $libname")
blas = library_dependency("libblas", alias=["libblas.dll"])
lapack = library_dependency("liblapack", alias=["liblapack.dll"])
depends = JULIA_LAPACK ? [] : [blas, lapack]

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
                  patch_int
                  compile_objs
             end
         end),
         [csdp])

# Lapack build https://icl.cs.utk.edu/lapack-for-windows/lapack/#build
provides(Binaries,
   URI("https://github.com/EQt/winlapack/blob/master/winlapack.7z?raw=true"),
   [lapack, blas], unpacked_dir="bin$WORD_SIZE", os = :Windows)


@windows_only push!(BinDeps.defaults, BuildProcess)
@BinDeps.install Dict(:csdp => :csdp)
@windows_only pop!(BinDeps.defaults)
