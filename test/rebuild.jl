# Rebuild shared library
using CSDP
rm(CSDP.csdp)
Pkg.build("CSDP")
