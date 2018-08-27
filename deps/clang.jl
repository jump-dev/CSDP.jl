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
push!(Compat.Libdl.DL_LOAD_PATH, readchomp(`$(ENV["LLVM_CONFIG"]) --libdir`))

include(joinpath(dirname(@__FILE__), "constants.jl"))
cd(joinpath(dirname(@__FILE__), "src", csdpversion))

wrap_c.cl_to_jl[Clang.cindex.Pointer] = :Ptr
header_naming = n -> joinpath(dirname(@__FILE__), "..", "src", "$(basename(n)).jl")
context = wrap_c.init(header_outputfile = header_naming,
                      header_library = "CSDP.csdp",
                      clang_diagnostics=true,
                      common_file = joinpath(dirname(@__FILE__), "..", "src", "blockmat.h.jl"),
                      clang_args = ["-DNOSHORTS"])
                      # rewriter = s -> (println(s); s))
context.options.wrap_structs = true
wrap_c.wrap_c_headers(context, ["include/blockmat.h", "include/declarations.h"])

function readchangewrite(f, fname)
    content = Compat.read(fname)
    open(fname, "w") do file
        write(file, f(content))
    end
end

readchangewrite(header_naming("blockmat.h")) do b
    for (pat, subs) in [(r"^( begin enum)"m, s"#\1")
                       ,(r"^(nst NOSHORTS = 1)$"m, s"co\1")
                      #,(r"::Ptr", s"::Ref")
                       ,(r"\ntype "m, "\nimmutable ")
                       ]
        b = replace(b, pat, subs)
    end
    b
end

readchangewrite(header_naming("declarations.h")) do d
    replace(d, r"\nfunction \w+_\(\)\n(.+?)\nend\n"sm, "")
end

