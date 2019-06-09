using Test

using MathOptInterface
const MOI = MathOptInterface
const MOIT = MOI.Test
const MOIB = MOI.Bridges

const MOIU = MOI.Utilities
MOIU.@model(SDModelData,
            (), (MOI.EqualTo, MOI.GreaterThan, MOI.LessThan),
            (MOI.Zeros, MOI.Nonnegatives, MOI.Nonpositives,
             MOI.PositiveSemidefiniteConeTriangle), (),
            (), (MOI.ScalarAffineFunction,), (MOI.VectorOfVariables,), ())

import CSDP
const optimizer = CSDP.Optimizer()
MOI.set(optimizer, MOI.Silent(), true)
const cache = MOIU.UniversalFallback(SDModelData{Float64}())
const cached = MOIU.CachingOptimizer(cache, optimizer)
const bridged = MOIB.full_bridge_optimizer(cached, Float64)
const config = MOIT.TestConfig(atol=1e-4, rtol=1e-4)

@testset "SolverName" begin
    @test MOI.get(optimizer, MOI.SolverName()) == "CSDP"
end

@testset "Options" begin
    param = MOI.RawParameter(:bad_option)
    err = MOI.UnsupportedAttribute(param)
    @test_throws err CSDP.Optimizer(bad_option = 1)
end

@testset "Unit" begin
    MOIT.unittest(bridged, config,
                  [# Multiple variable constraints on same variable
                   "solve_with_lowerbound", "solve_affine_interval",
                   "solve_with_upperbound",
                   # Quadratic functions are not supported
                   "solve_qcp_edge_cases", "solve_qp_edge_cases",
                   # Integer and ZeroOne sets are not supported
                   "solve_integer_edge_cases", "solve_objbound_edge_cases"])
end
@testset "Continuous Linear" begin
    MOIT.contlineartest(bridged, config,
                        [
                         # https://github.com/JuliaOpt/MathOptInterface.jl/issues/693
                         "linear1",
                         # Multiple variable constraints on same variable
                         "linear10", "linear10b", "linear14"])
end
@testset "Continuous Conic" begin
    MOIT.contconictest(bridged, config,
                       [
                        # Need to investigate
                        "psds0v",
                        # Multiple variable constraints on same variable
                        "rotatedsoc3",
                        # Missing bridges
                        "rootdets",
                        # Does not support exponential cone
                        "logdet", "exp"])
end
