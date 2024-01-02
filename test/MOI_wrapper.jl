# Copyright (c) 2016: CSDP.jl contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

module TestCSDP

using Test
import MathOptInterface as MOI
import CSDP

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
    model = MOI.instantiate(CSDP.Optimizer, with_bridge_type = Float64)
    # `Variable.ZerosBridge` makes dual needed by some tests fail.
    MOI.Bridges.remove_bridge(model, MOI.Bridges.Variable.ZerosBridge{Float64})
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
        exclude = Regex[
            # Known test failures.
            #   Empty constraint not supported:
            r"test_conic_PositiveSemidefiniteConeTriangle$",
            r"test_linear_VectorAffineFunction_empty_row$",
            #   Terminates with status `5` which means "Stuck at edge of primal feasibility."
            r"test_quadratic_constraint_basic",
            r"test_quadratic_constraint_minimize",
            # Unknown test failures.
            # Working locally but getting into numerical issues in CI
            r"test_quadratic_constraint_basic$",
            r"test_quadratic_constraint_minimize$",
            r"test_conic_SecondOrderCone_negative_post_bound$",
            r"test_conic_SecondOrderCone_no_initial_bound$",
            r"test_linear_integration$",
            r"test_modification_coef_scalar_objective$",
            r"test_modification_const_scalar_objective$",
            r"test_modification_delete_variable_with_single_variable_obj$",
            r"test_modification_transform_singlevariable_lessthan$",
            r"test_objective_FEASIBILITY_SENSE_clears_objective$",
            r"test_objective_ObjectiveFunction_blank$",
            r"test_objective_ObjectiveFunction_duplicate_terms$",
            r"test_solve_result_index$",
            r"test_modification_set_singlevariable_lessthan$",
            r"test_objective_ObjectiveFunction_VariableIndex$",
            r"test_conic_SecondOrderCone_nonnegative_initial_bound$",
            r"test_solve_TerminationStatus_DUAL_INFEASIBLE$",
            r"test_conic_RotatedSecondOrderCone_VectorOfVariables$",
        ],
    )
    return
end

end  # module

TestCSDP.runtests()
