using BinDeps
using LinearAlgebra, Libdl

@BinDeps.setup

blas = library_dependency("libblas", alias=["libblas.dll"])
lapack = library_dependency("liblapack", alias=["liblapack.dll"])

const ENV_VAR      = "CSDP_USE_JULIA_LAPACK"
const JULIA_LAPACK = if haskey(ENV, ENV_VAR)
    value = ENV[ENV_VAR]
    if lowercase(value) in ["1", "true", "yes"]
        @info "Using the blas and lapack libraries shipped with Julia as the environment variable `$ENV_VAR` is set to `$value`."
        true
    elseif lowercase(value) in ["0", "false", "no"]
        @info "Using system blas and lapack libraries as the environment variable `$ENV_VAR` is set to `$value`."
        false
    else
        error("The environment variable `$ENV_VAR` is set to `$value`. Set it to `1` or `0` instead.")
    end
else
    if BinDeps.issatisfied(blas) && BinDeps.issatisfied(lapack)
        @info "Using system blas and lapack libraries. Set the environment variable `$ENV_VAR` to `1` to use the blas/lapack library shipped with Julia."
        false
    else
        @info "Using the blas and lapack libraries shipped with Julia as there is no system blas and lapack libraries installed."
        true
    end
end

include("constants.jl")
include("compile.jl")

# @info "libname = $libname"
depends = JULIA_LAPACK ? [] : [blas, lapack]

# LaPack/BLAS dependencies
if !JULIA_LAPACK
    @static if Sys.iswindows()
        # wheel = "numpy/windows-wheel-builder/raw/master/atlas-builds"
        # atlas = "https://github.com/$wheel"
        # atlasdll = "/atlas-3.11.38-sse2-64/lib/numpy-atlas.dll"
        # download("https://raw.githubusercontent.com/$wheel/$atlasdll"),
        #           "$libdir/libatlas.dll")
        ## at the end ...
        # push!(BinDeps.defaults, BuildProcess)
    end
end

csdp = library_dependency("csdp", aliases=[libname], depends=depends)

provides(Sources, URI(download_url), csdp, unpacked_dir=csdpversion)

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

# Prebuilt DLLs for Windows
provides(Binaries,
   URI("https://github.com/EQt/winlapack/blob/49454aee32649dc52c5b64f408a17b5270bd30f4/win-csdp-$(Sys.WORD_SIZE).7z?raw=true"),
   [csdp, lapack, blas], unpacked_dir="usr", os = :Windows)

@BinDeps.install Dict(:csdp => :csdp)

open(joinpath(dirname(@__FILE__), "deps.jl"), write = true, append = true) do io
    print(io, "const CSDP_INT = ")
    if JULIA_LAPACK
        println(io, "Clong")
    else
        println(io, "Cint")
    end
end
