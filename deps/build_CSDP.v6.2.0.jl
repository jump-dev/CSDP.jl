# Generated by running
# julia --color=yes generate_buildjl.jl C/Coin-OR/CSDP/build_tarballs.jl JuliaBinaryWrappers/CSDP_jll.jl CSDP-v6.2.0+4
# in the root the the source tree of https://github.com/JuliaPackaging/Yggdrasil/
# by first replacing the `include` by its content, see https://github.com/JuliaPackaging/Yggdrasil/issues/858
# We also added `prefix, ` after `LibraryProduct(`.
using BinaryProvider # requires BinaryProvider 0.3.0 or later

# Parse some basic command-line arguments
const verbose = "--verbose" in ARGS
const prefix = Prefix(get([a for a in ARGS if a != "--verbose"], 1, joinpath(@__DIR__, "usr")))
products = [
    LibraryProduct(prefix, ["libcsdp"], :libcsdp)
]

# Download binaries from hosted location
bin_prefix = "https://github.com/JuliaBinaryWrappers/CSDP_jll.jl/releases/download/CSDP-v6.2.0+4"

# Listing of files generated by BinaryBuilder:
download_info = Dict(
    Linux(:aarch64, libc=:glibc) => ("$bin_prefix/CSDP.v6.2.0.aarch64-linux-gnu.tar.gz", "446a2d5c60a9270a345d2aab12093c76accab967c175ff96de7f684e48c2f482"),
    Linux(:aarch64, libc=:musl) => ("$bin_prefix/CSDP.v6.2.0.aarch64-linux-musl.tar.gz", "1e0c1e5c89e6b70538ff9b4e705bda3d267721ae4d58ee600152bc5f6101bf46"),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf) => ("$bin_prefix/CSDP.v6.2.0.armv7l-linux-gnueabihf.tar.gz", "88532fc19eb7a33b72bad0b7e01d61b1bd29b6069b4a883d468d6e12f00cf711"),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf) => ("$bin_prefix/CSDP.v6.2.0.armv7l-linux-musleabihf.tar.gz", "f1dd8bba6a91b4c94394ad421487b99249c8abd592dfbb2256d0dee704ea2a82"),
    Linux(:i686, libc=:glibc) => ("$bin_prefix/CSDP.v6.2.0.i686-linux-gnu.tar.gz", "80e2a2b2263ca378efb23cd565814bd66f5e120cdb955e9bdf548ab32b43b75d"),
    Linux(:i686, libc=:musl) => ("$bin_prefix/CSDP.v6.2.0.i686-linux-musl.tar.gz", "df0608d84f7b4c511ef002271f0f6a9481a81da3e3c751d36392d6fc89540cf2"),
    Windows(:i686) => ("$bin_prefix/CSDP.v6.2.0.i686-w64-mingw32.tar.gz", "33f83f94bcec13087f9fa9276345ec296722b14b6a28c3790bb494e419bf41ea"),
    Linux(:powerpc64le, libc=:glibc) => ("$bin_prefix/CSDP.v6.2.0.powerpc64le-linux-gnu.tar.gz", "461214a00369395ccd544ec40e7c89d787fcc2a869aeb73a832f79ff06c16b97"),
    MacOS(:x86_64) => ("$bin_prefix/CSDP.v6.2.0.x86_64-apple-darwin14.tar.gz", "af4cbf6d324b32f26e3700d50ed2950eebbd3bdc6cc13eae8c1d15ba25c70de6"),
    Linux(:x86_64, libc=:glibc) => ("$bin_prefix/CSDP.v6.2.0.x86_64-linux-gnu.tar.gz", "7ddaafbe0079f6852b60c3479bbed050b367931da3c231ba26ef20c2b71c698f"),
    Linux(:x86_64, libc=:musl) => ("$bin_prefix/CSDP.v6.2.0.x86_64-linux-musl.tar.gz", "337e68f51132e080d8bb5cdf79197326df9637ede69ed9258c67626a99edc7b5"),
    FreeBSD(:x86_64) => ("$bin_prefix/CSDP.v6.2.0.x86_64-unknown-freebsd11.1.tar.gz", "d7affbc5d639bff71fce4848d77d368dbca49dd8125cf849a416c4c059668201"),
    Windows(:x86_64) => ("$bin_prefix/CSDP.v6.2.0.x86_64-w64-mingw32.tar.gz", "181520ca04efb32323a369ecee7d067937d9a59d5f45ed4b78d3669f8a52769d"),
)

# Install unsatisfied or updated dependencies:
unsatisfied = any(!satisfied(p; verbose=verbose) for p in products)
dl_info = choose_download(download_info, platform_key_abi())
if dl_info === nothing && unsatisfied
    # If we don't have a compatible .tar.gz to download, complain.
    # Alternatively, you could attempt to install from a separate provider,
    # build from source or something even more ambitious here.
    error("Your platform (\"$(Sys.MACHINE)\", parsed as \"$(triplet(platform_key_abi()))\") is not supported by this package!")
end

# If we have a download, and we are unsatisfied (or the version we're
# trying to install is not itself installed) then load it up!
if unsatisfied || !isinstalled(dl_info...; prefix=prefix)
    # Download and install binaries
    install(dl_info...; prefix=prefix, force=true, verbose=verbose)
end

# Write out a deps.jl file that will contain mappings for our products
write_deps_file(joinpath(@__DIR__, "deps.jl"), products, verbose=verbose)
