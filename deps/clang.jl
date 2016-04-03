# Automated generation by c header files using Clang.jl
# See
# http://nbviewer.jupyter.org/github/ihnorton/Clang.jl/blob/master/examples/parsing_c_with_clangjl/notebook.ipynb
#
using Clang.wrap_c

# add libclang to DL_LOAD_PATH
try
    ENV["LLVM_CONFIG"] = readchomp(`which llvm-config-3.6`)
catch
    try
        ENV["LLVM_CONFIG"] = readchomp(`which llvm-config`)
    catch
        error("llvm-config not found")
    end
end
push!(Libdl.DL_LOAD_PATH, readchomp(`$(ENV["LLVM_CONFIG"]) --libdir`))

include(joinpath(dirname(@__FILE__), "constants.jl"))
cd(Pkg.dir("CSDP", "deps", "src", csdpversion))

wrap_c.cl_to_jl[Clang.cindex.Pointer] = :Ptr
outfile = Pkg.dir("CSDP", "src", "blockmat_.jl")

context = wrap_c.init(output_file=outfile,
                      clang_diagnostics=true,
                      clang_args = ["-DNOSHORTS"])
                      # rewriter = s -> (println(s); s))
context.options.wrap_structs = true
wrap_c.wrap_c_headers(context, ["include/blockmat.h"])

blockmat_ = readall(outfile)
for (pat, subs) in [(r"^( begin enum)"m, s"#\1"),
                    (r"^(nst NOSHORTS = 1)$"m, s"co\1"),
                    (r"::Ptr", s"::Ref")]
    blockmat_ = replace(blockmat_, pat, subs)
end
open(outfile, "w") do f
    write(f, blockmat_)
end

