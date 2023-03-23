# Copyright (c) 2016: CSDP.jl contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

module TestCSDP

using Test
using MathOptInterface
import CSDP

const MOI = MathOptInterface

function runtests()
    for name in names(@__MODULE__; all = true)
        if startswith("$(name)", "test_")
            @testset "$(name)" begin
                getfield(@__MODULE__, name)()
            end
        end
    end
    return
end

function test_solver_name()
    @test MOI.get(CSDP.Optimizer(), MOI.SolverName()) == "CSDP"
    return
end

function test_options()
    param = MOI.RawOptimizerAttribute("bad_option")
    err = MOI.UnsupportedAttribute(param)
    @test_throws err MOI.set(
        CSDP.Optimizer(),
        MOI.RawOptimizerAttribute("bad_option"),
        0,
    )
    return
end

function test_unsupported_constraint()
    model = MOI.Utilities.Model{Float64}()
    x = MOI.add_variable(model)
    MOI.add_constraint(model, x, MOI.GreaterThan(0.0))
    MOI.add_constraint(model, 1.0 * x, MOI.EqualTo(0.0))
    @test_throws(
        MOI.UnsupportedConstraint{MOI.VariableIndex,MOI.GreaterThan{Float64}}(),
        MOI.copy_to(CSDP.Optimizer(), model),
    )
    return
end

function test_runtests()
    model = MOI.Utilities.CachingOptimizer(
        MOI.Utilities.UniversalFallback(MOI.Utilities.Model{Float64}()),
        MOI.instantiate(CSDP.Optimizer, with_bridge_type = Float64),
    )
    # `Variable.ZerosBridge` makes dual needed by some tests fail.
    MOI.Bridges.remove_bridge(
        model.optimizer,
        MathOptInterface.Bridges.Variable.ZerosBridge{Float64},
    )
    MOI.set(model, MOI.Silent(), true)
    MOI.Test.runtests(
        model,
        MOI.Test.Config(
            rtol = 1e-3,
            atol = 1e-3,
            exclude = Any[
                MOI.ConstraintBasisStatus,
                MOI.VariableBasisStatus,
                MOI.ObjectiveBound,
                MOI.SolverVersion,
            ],
        ),
        exclude = String[
            # Known test failures.
            #   Empty constraint not supported:
            "test_conic_PositiveSemidefiniteConeTriangle",
            "test_linear_VectorAffineFunction_empty_row",
            #   Unable to bridge RotatedSecondOrderCone to PSD because the the dimension is too small: got 2, expected >= 3
            "test_conic_SecondOrderCone_INFEASIBLE",
            "test_constraint_PrimalStart_DualStart_SecondOrderCone",
            # TODO(odow): unknown test failures.
            "test_conic_RotatedSecondOrderCone_VectorOfVariables",
            "test_variable_solve_with_lowerbound",
            "test_modification_delete_variables_in_a_batch",
            # Working locally but `SLOW_PROGRESS` in CI
            "test_quadratic_constraint_basic",
            "test_quadratic_constraint_minimize",
        ],
    )
    return
end

end  # module

TestCSDP.runtests()
