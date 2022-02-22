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
