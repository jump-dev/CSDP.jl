using MathOptInterface
const MOI = MathOptInterface
const MOIT = MOI.Test
const MOIB = MOI.Bridges

const MOIU = MOI.Utilities
MOIU.@model(SDModelData,
            (),
            (MOI.EqualTo, MOI.GreaterThan, MOI.LessThan),
            (MOI.Zeros, MOI.Nonnegatives, MOI.Nonpositives,
             MOI.PositiveSemidefiniteConeTriangle),
            (),
            (MOI.SingleVariable,),
            (MOI.ScalarAffineFunction,),
            (MOI.VectorOfVariables,),
            (MOI.VectorAffineFunction,))

const optimizer = MOIU.CachingOptimizer(SDModelData{Float64}(), CSDP.Optimizer(printlevel=0))
const config = MOIT.TestConfig(atol=1e-4, rtol=1e-4)

@testset "Unit" begin
    MOIT.unittest(MOIB.SplitInterval{Float64}(optimizer), config,
                  [# Quadratic functions are not supported
                   "solve_qcp_edge_cases", "solve_qp_edge_cases",
                   # Integer and ZeroOne sets are not supported
                   "solve_integer_edge_cases", "solve_objbound_edge_cases"])
end
@testset "Continuous Linear" begin
    MOIT.contlineartest(MOIB.SplitInterval{Float64}(optimizer), config)
end
@testset "Continuous Conic" begin
    MOIT.contconictest(MOIB.RootDet{Float64}(MOIB.GeoMean{Float64}(MOIB.RSOCtoPSD{Float64}(MOIB.SOCtoPSD{Float64}(optimizer)))), config, ["psds", "rootdets", "logdet", "exp"])
end
