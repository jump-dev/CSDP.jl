# Copyright (c) 2016: CSDP.jl contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

using CSDP
using MathOptInterface
const MOI = MathOptInterface
using SemidefiniteOptInterface
const SOI = SemidefiniteOptInterface
m = CSDP.CSDPSolverInstance()
SOI.initinstance!(m, [-2], 0)
SOI.setobjectivecoefficient!(m, -1.0, 1, 1, 1)
SOI.setobjectivecoefficient!(m, -1.0, 1, 2, 2)
MOI.optimize!(m)
@show m.status
