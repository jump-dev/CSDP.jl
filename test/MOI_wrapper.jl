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
end

function test_options()
    param = MOI.RawOptimizerAttribute("bad_option")
    err = MOI.UnsupportedAttribute(param)
    @test_throws err MOI.set(
        CSDP.Optimizer(),
        MOI.RawOptimizerAttribute("bad_option"),
        0,
    )
end

function test_runtests()
    model = MOI.Utilities.CachingOptimizer(
        MOI.Utilities.UniversalFallback(MOI.Utilities.Model{Float64}()),
        MOI.instantiate(CSDP.Optimizer, with_bridge_type=Float64),
    )
    # `Variable.ZerosBridge` makes dual needed by some tests fail.
    MOI.Bridges.remove_bridge(model.optimizer, MathOptInterface.Bridges.Variable.ZerosBridge{Float64})
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
            # Empty constraint not supported
            "test_linear_VectorAffineFunction_empty_row",
            "test_conic_PositiveSemidefiniteConeTriangle",
            # SLOW_PROGRESS
            "test_quadratic_constraint_basic",
            "test_quadratic_constraint_minimize",
            # FIXME need to investigate
            #  Expression: MOI.get(model, MOI.TerminationStatus()) == config.infeasible_status
            #   Evaluated: MathOptInterface.OPTIMAL == MathOptInterface.INFEASIBLE
            "test_conic_SecondOrderCone_INFEASIBLE",
            # FIXME need to investigate
            "test_objective_qp_ObjectiveFunction_edge_cases",
            # FIXME need to investigate
            #   Expression: isapprox(MOI.get(model, MOI.ObjectiveValue()), objective_value, config)
            #   Evaluated: isapprox(-0.9999999999999991, 1.0, ...
            #   Expression: isapprox(MOI.get(model, MOI.VariablePrimal(), index), solution_value, config)
            #   Evaluated: isapprox(-0.9999999999999991, 1.0, ...
            #BoundsError: attempt to access 1-element Vector{Float64} at index [3]
            "test_constraint_PrimalStart_DualStart_SecondOrderCone",
            # FIXME investigate
            # Internal library error: status=-1
            "test_model_default_DualStatus",
            "test_model_default_PrimalStatus",
            # FIXME investigate
            #  Expression: isapprox(MOI.get(model, MOI.ObjectiveValue()), T(2), config)
            #   Evaluated: isapprox(6.0, 2.0, ...
            "test_modification_delete_variables_in_a_batch",
            # FIXME investigate
            #   Expression: isapprox(MOI.get(model, MOI.ObjectiveValue()), objective_value, config)
            #    Evaluated: isapprox(4.162643563176971e-9, 5.0
            "test_objective_qp_ObjectiveFunction_zero_ofdiag",
            # FIXME investigate
            #  Expression: isapprox(MOI.get(model, MOI.ConstraintPrimal(), index), solution_value, config)
            #   Evaluated: isapprox(9.973062820023415e-9, 1.0, ...
            "test_variable_solve_with_lowerbound",
            # TODO CSDP just returns an infinite ObjectiveValue
            "test_unbounded_MIN_SENSE",
            "test_unbounded_MIN_SENSE_offset",
            "test_unbounded_MAX_SENSE",
            "test_unbounded_MAX_SENSE_offset",
            # TODO SDPT3 just returns an infinite DualObjectiveValue
            "test_infeasible_MAX_SENSE",
            "test_infeasible_MAX_SENSE_offset",
            "test_infeasible_MIN_SENSE",
            "test_infeasible_MIN_SENSE_offset",
            "test_infeasible_affine_MAX_SENSE",
            "test_infeasible_affine_MAX_SENSE_offset",
            "test_infeasible_affine_MIN_SENSE",
            "test_infeasible_affine_MIN_SENSE_offset",
            # See https://github.com/jump-dev/MathOptInterface.jl/issues/1758
            "test_model_copy_to_UnsupportedAttribute",
        ],
    )
end

end  # module

TestCSDP.runtests()
