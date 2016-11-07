using Clang

const INCLUDE = "Csdp-6.1.1/include"

idx = Clang.cindex.parse_header("$INCLUDE/declarations.h";
                                diagnostics=true,
                                includes=[INCLUDE],
                                args=["-DNOSHORTS"])
cursor = idx.data[1]
