using BinDeps

@BinDeps.setup

include("constants.jl")
include("compile.jl")

# LaPack/BLAS dependencies
if !JULIA_LAPACK
    @windows_only begin
        info("Downloading DLLs to $libdir")
        mkpath(libdir)
        atlas = "https://github.com/numpy/windows-wheel-builder/raw/master/atlas-builds"
        download("https://raw.githubusercontent.com/numpy/windows-wheel-builder/master/atlas-builds/atlas-3.11.38-sse2-64/lib/numpy-atlas.dll",
                 "$libdir/libatlas.dll")
        depends = []
    end

    @unix_only begin
        blas = library_dependency("libblas",     alias=["libblas.dll"])
        lapack = library_dependency("liblapack", alias=["liblapack.dll"])
        depends = [blas, lapack]
    end
else
    depends = []
end

info("libname = $libname")

csdp = library_dependency("csdp", aliases=["csdp", "libcsdp", libname], depends=depends)

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

@windows_only push!(BinDeps.defaults, BuildProcess)
@BinDeps.install Dict(:csdp => :csdp)
@windows_only pop!(BinDeps.defaults)
