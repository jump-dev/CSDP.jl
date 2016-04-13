# Rebuild shared library
try
    using CSDP
    isfile(CSDP.csdp) && rm(CSDP.csdp)
catch
    println("Lib unloadable")
end

Pkg.build("CSDP")
