# Inspired from https://github.com/JuliaDatabases/MySQL.jl/blob/36eaf2bfbbdd9a27c408d0b2a734fff0d81b63ad/deps/build.jl
module Anon1 end
module Anon2 end

@static if VERSION < v"1.3.0"

using BinaryProvider # requires BinaryProvider 0.3.0 or later

# Parse some basic command-line arguments
const verbose = "--verbose" in ARGS
const prefix = Prefix(get([a for a in ARGS if a != "--verbose"], 1, joinpath(@__DIR__, "usr")))

products = [
    LibraryProduct(prefix, ["libcsdp"], :libcsdp)
]

Anon1.include("build_OpenBLAS32.v0.3.9.jl")
Anon2.include("build_CSDP.v6.2.0.jl")

# Finally, write out a deps.jl file
write_deps_file(joinpath(@__DIR__, "deps.jl"), products, verbose=true)

end # VERSION
