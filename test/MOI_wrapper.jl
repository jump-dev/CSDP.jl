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
            #   Unable to bridge RotatedSecondOrderCone to PSD because the ...
            "test_conic_SecondOrderCone_INFEASIBLE",
            "test_constraint_PrimalStart_DualStart_SecondOrderCone",
            # TODO(odow): unknown test failures.
            "test_conic_SecondOrderCone_negative_initial_bound",
            "test_conic_SecondOrderCone_negative_post_bound",
            "test_conic_SecondOrderCone_negative_post_bound_2",
            "test_conic_SecondOrderCone_negative_post_bound_3",
            "test_conic_SecondOrderCone_nonnegative_initial_bound",
            "test_conic_SecondOrderCone_no_initial_bound",
            "test_modification_coef_scalar_objective",
            "test_modification_const_scalar_objective",
            "test_modification_delete_variables_in_a_batch",
            "test_modification_delete_variable_with_single_variable_obj",
            "test_modification_set_singlevariable_lessthan",
            "test_modification_transform_singlevariable_lessthan",
            "test_objective_FEASIBILITY_SENSE_clears_objective",
            "test_objective_ObjectiveFunction_blank",
            "test_objective_ObjectiveFunction_constant",
            "test_objective_ObjectiveFunction_duplicate_terms",
            "test_objective_ObjectiveFunction_VariableIndex",
            "test_quadratic_constraint_basic",
            "test_quadratic_constraint_minimize",
            "test_solve_result_index",
            "test_solve_TerminationStatus_DUAL_INFEASIBLE",
            "test_variable_solve_with_lowerbound",
        ],
    )
    return
end

end  # module

TestCSDP.runtests()
