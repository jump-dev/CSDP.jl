using Test

using MathOptInterface
const MOI = MathOptInterface
const MOIT = MOI.Test
const MOIU = MOI.Utilities
const MOIB = MOI.Bridges

import CSDP
const optimizer_constructor = MOI.OptimizerWithAttributes(CSDP.Optimizer, MOI.Silent() => true)
const optimizer = MOI.instantiate(optimizer_constructor)

@testset "SolverName" begin
    @test MOI.get(optimizer, MOI.SolverName()) == "CSDP"
end

@testset "supports_default_copy_to" begin
    @test MOIU.supports_allocate_load(optimizer, false)
    @test !MOIU.supports_allocate_load(optimizer, true)
end

const bridged = MOI.instantiate(optimizer_constructor, with_bridge_type=Float64)
const config = MOIT.TestConfig(atol=1e-4, rtol=1e-4)

@testset "Options" begin
    param = MOI.RawParameter("bad_option")
    err = MOI.UnsupportedAttribute(param)
    @test_throws err MOI.set(optimizer, MOI.RawParameter("bad_option"), 0)
end

@testset "Unit" begin
    MOIT.unittest(bridged, config, [
        # `NUMERICAL_ERROR` on Mac: https://travis-ci.org/JuliaOpt/CSDP.jl/jobs/601302777#L217-L219
        "solve_unbounded_model",
        # `NumberOfThreads` not supported.
        "number_threads",
        # `TimeLimitSec` not supported.
        "time_limit_sec",
        # Quadratic functions are not supported
        "solve_qcp_edge_cases", "solve_qp_edge_cases",
        # Integer and ZeroOne sets are not supported
        "solve_integer_edge_cases", "solve_objbound_edge_cases",
        "solve_zero_one_with_bounds_1",
        "solve_zero_one_with_bounds_2",
        "solve_zero_one_with_bounds_3"])
end
@testset "Continuous Linear" begin
    # See explanation in `MOI/test/Bridges/lazy_bridge_optimizer.jl`.
    # This is to avoid `Variable.VectorizeBridge` which does not support
    # `ConstraintSet` modification.
    MOIB.remove_bridge(bridged, MOIB.Constraint.ScalarSlackBridge{Float64})
    MOIT.contlineartest(bridged, config, [
        # Finds `MOI.ALMOST_OPTIMAL` instead of `MOI.OPTIMAL`
        "linear10b",
        # Empty constraint
        "linear15"
    ])
end
@testset "Continuous Conic" begin
    MOIT.contconictest(bridged, config, [
        # Finds `MOI.OPTIMAL` instead of `MOI.INFEASIBLE`.
        "soc3",
        # Empty constraint `c4`
        "psdt2",
        # See https://github.com/coin-or/Csdp/issues/11
        "rotatedsoc1v",
        # Missing bridges
        "rootdets",
        # Does not support power and exponential cone
        "pow", "dualpow", "logdet", "exp", "dualexp", "relentr"])
end
