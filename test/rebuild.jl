# Copyright (c) 2016: CSDP.jl contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

# Rebuild shared library
try
    using CSDP
    isfile(CSDP.csdp) && rm(CSDP.csdp)
catch
    println("Lib unloadable")
end

Pkg.build("CSDP")
