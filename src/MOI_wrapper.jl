using MathOptInterface
const MOI = MathOptInterface
const MOIU = MOI.Utilities
const AFFEQ = MOI.ConstraintIndex{MOI.ScalarAffineFunction{Cdouble}, MOI.EqualTo{Cdouble}}

mutable struct Optimizer <: MOI.AbstractOptimizer
    objconstant::Cdouble
    objsign::Int
    blockdims::Vector{Int}
    varmap::Vector{Tuple{Int, Int, Int}} # Variable Index vi -> blk, i, j
    b::Vector{Cdouble}
    C::Union{Nothing, BlockMatrix}
    As::Union{Nothing, Vector{ConstraintMatrix}}
    X::Union{Nothing, BlockMatrix}
    y::Union{Nothing, Vector{Cdouble}}
    Z::Union{Nothing, BlockMatrix}
    status::Cint
    pobj::Cdouble
    dobj::Cdouble
    solve_time::Float64
    silent::Bool
    options::Dict{Symbol, Any}
    function Optimizer(; kwargs...)
        optimizer = new(
            zero(Cdouble), 1, Int[], Tuple{Int, Int, Int}[], Cdouble[],
            nothing, nothing, nothing, nothing, nothing,
            -1, NaN, NaN, NaN, false, Dict{Symbol, Any}())
        for (key, value) in kwargs
            MOI.set(optimizer, MOI.RawParameter(key), value)
        end
        return optimizer
    end
end

varmap(optimizer::Optimizer, vi::MOI.VariableIndex) = optimizer.varmap[vi.value]

function MOI.supports(optimizer::Optimizer, param::MOI.RawParameter)
    return param.name in ALLOWED_OPTIONS
end
function MOI.set(optimizer::Optimizer, param::MOI.RawParameter, value)
    if !MOI.supports(optimizer, param)
        throw(MOI.UnsupportedAttribute(param))
    end
    optimizer.options[param.name] = value
end
function MOI.get(optimizer::Optimizer, param::MOI.RawParameter)
    # TODO: This gives a poor error message if the name of the parameter is invalid.
    return optimizer.options[param.name]
end

MOI.supports(::Optimizer, ::MOI.Silent) = true
function MOI.set(optimizer::Optimizer, ::MOI.Silent, value::Bool)
    optimizer.silent = value
end
MOI.get(optimizer::Optimizer, ::MOI.Silent) = optimizer.silent

MOI.get(::Optimizer, ::MOI.SolverName) = "CSDP"
# See table "Return codes for easy_sdp() and CSDP" in `doc/csdpuser.pdf`.
const RAW_STATUS = [
    "Problem solved to optimality.",
    "Problem is primal infeasible.",
    "Problem is dual infeasible.",
    "Problem solved to near optimality.",
    "Maximum iterations reached.",
    "Stuck at edge of primal feasibility.",
    "Stuck at edge of dual feasibility.",
    "Lack of progress.",
    "X, Z, or O is singular.",
    "NaN or Inf values encountered.",
    "Program stopped by signal (SIXCPU, SIGTERM, etc.)"]

function MOI.get(optimizer::Optimizer, ::MOI.RawStatusString)
    return RAW_STATUS[optimizer.status + 1]
end
function MOI.get(optimizer::Optimizer, ::MOI.SolveTime)
    return optimizer.solve_time
end

function MOI.is_empty(optimizer::Optimizer)
    return iszero(optimizer.objconstant) &&
        optimizer.objsign == 1 &&
        isempty(optimizer.blockdims) &&
        isempty(optimizer.varmap) &&
        isempty(optimizer.b) &&
        optimizer.C === nothing &&
        optimizer.As === nothing
end

function MOI.empty!(optimizer::Optimizer)
    optimizer.objconstant = zero(Cdouble)
    optimizer.objsign = 1
    empty!(optimizer.blockdims)
    empty!(optimizer.varmap)
    empty!(optimizer.b)
    optimizer.C = nothing
    optimizer.As = nothing
    optimizer.X = nothing
    optimizer.y = nothing
    optimizer.Z = nothing
    optimizer.status = -1
    optimizer.pobj = 0.0
    optimizer.dobj = 0.0
end

function MOI.supports(
    optimizer::Optimizer,
    ::Union{MOI.ObjectiveSense,
            MOI.ObjectiveFunction{<:Union{MOI.SingleVariable,
                                          MOI.ScalarAffineFunction{Cdouble}}}})
    return true
end

function MOI.supports_constraint(
    ::Optimizer, ::Type{MOI.VectorOfVariables}, ::Type{MOI.Reals})
    return false
end
const SupportedSets = Union{MOI.Nonnegatives, MOI.PositiveSemidefiniteConeTriangle}
function MOI.supports_constraint(
    ::Optimizer, ::Type{MOI.VectorOfVariables},
    ::Type{<:SupportedSets})
    return true
end
function MOI.supports_constraint(
    ::Optimizer, ::Type{MOI.ScalarAffineFunction{Cdouble}},
    ::Type{MOI.EqualTo{Cdouble}})
    return true
end

function MOI.copy_to(dest::Optimizer, src::MOI.ModelLike; kws...)
    return MOIU.automatic_copy_to(dest, src; kws...)
end
MOIU.supports_allocate_load(::Optimizer, copy_names::Bool) = !copy_names

function MOIU.allocate(optimizer::Optimizer, ::MOI.ObjectiveSense, sense::MOI.OptimizationSense)
    # To be sure that it is done before load(optimizer, ::ObjectiveFunction, ...), we do it in allocate
    optimizer.objsign = sense == MOI.MIN_SENSE ? -1 : 1
end
function MOIU.allocate(::Optimizer, ::MOI.ObjectiveFunction, ::Union{MOI.SingleVariable, MOI.ScalarAffineFunction}) end

function MOIU.load(::Optimizer, ::MOI.ObjectiveSense, ::MOI.OptimizationSense) end
# Loads objective coefficient α * vi
function load_objective_term!(optimizer::Optimizer, α, vi::MOI.VariableIndex)
    blk, i, j = varmap(optimizer, vi)
    coef = optimizer.objsign * α
    if i != j
        coef /= 2
    end
    # in SDP format, it is max and in MPB Conic format it is min
    block(optimizer.C, blk)[i, j] = coef
end
function MOIU.load(optimizer::Optimizer, ::MOI.ObjectiveFunction, f::MOI.ScalarAffineFunction)
    obj = MOIU.canonical(f)
    optimizer.objconstant = f.constant
    for t in obj.terms
        if !iszero(t.coefficient)
            load_objective_term!(optimizer, t.coefficient, t.variable_index)
        end
    end
end
function MOIU.load(optimizer::Optimizer, ::MOI.ObjectiveFunction, f::MOI.SingleVariable)
    load_objective_term!(optimizer, one(Cdouble), f.variable)
end

function new_block(optimizer::Optimizer, set::MOI.Nonnegatives)
    push!(optimizer.blockdims, -MOI.dimension(set))
    blk = length(optimizer.blockdims)
    for i in 1:MOI.dimension(set)
        push!(optimizer.varmap, (blk, i, i))
    end
end

function new_block(optimizer::Optimizer, set::MOI.PositiveSemidefiniteConeTriangle)
    push!(optimizer.blockdims, set.side_dimension)
    blk = length(optimizer.blockdims)
    for i in 1:set.side_dimension
        for j in 1:i
            push!(optimizer.varmap, (blk, i, j))
        end
    end
end

function MOIU.allocate_constrained_variables(optimizer::Optimizer,
                                             set::SupportedSets)
    offset = length(optimizer.varmap)
    new_block(optimizer, set)
    ci = MOI.ConstraintIndex{MOI.VectorOfVariables, typeof(set)}(offset + 1)
    return [MOI.VariableIndex(i) for i in offset .+ (1:MOI.dimension(set))], ci
end

function MOIU.load_constrained_variables(
    optimizer::Optimizer, vis::Vector{MOI.VariableIndex},
    ci::MOI.ConstraintIndex{MOI.VectorOfVariables},
    set::SupportedSets)
end

function MOIU.load_variables(optimizer::Optimizer, nvars)
    @assert nvars == length(optimizer.varmap)
    dummy = isempty(optimizer.b)
    if dummy
        # See https://github.com/coin-or/Csdp/issues/2
        optimizer.b = [one(Cdouble)]
        optimizer.blockdims = [optimizer.blockdims; -1]
    end
    optimizer.C = blockmatzeros(optimizer.blockdims)
    optimizer.As = [constrmatzeros(i, optimizer.blockdims) for i in eachindex(optimizer.b)]
    if dummy
        # See https://github.com/coin-or/Csdp/issues/2
        block(optimizer.As[1], length(optimizer.blockdims))[1, 1] = 1
    end

end

function MOIU.allocate_constraint(optimizer::Optimizer,
                                  func::MOI.ScalarAffineFunction{Cdouble},
                                  set::MOI.EqualTo{Cdouble})
    push!(optimizer.b, MOI.constant(set))
    return AFFEQ(length(optimizer.b))
end

function MOIU.load_constraint(m::Optimizer, ci::AFFEQ,
                              f::MOI.ScalarAffineFunction, s::MOI.EqualTo)
    if !iszero(MOI.constant(f))
        throw(MOI.ScalarFunctionConstantNotZero{
            Cdouble, MOI.ScalarAffineFunction{Cdouble}, MOI.EqualTo{Cdouble}}(
                MOI.constant(f)))
    end
    f = MOIU.canonical(f) # sum terms with same variables and same outputindex
    for t in f.terms
        if !iszero(t.coefficient)
            blk, i, j = varmap(m, t.variable_index)
            coef = t.coefficient
            if i != j
                coef /= 2
            end
            block(m.As[ci.value], blk)[i, j] = coef
        end
    end
end


function MOI.optimize!(optimizer::Optimizer)
    As = map(A->A.csdp, optimizer.As)

    write_prob(optimizer)

    start_time = time()
    optimizer.X, optimizer.y, optimizer.Z = initsoln(optimizer.C, optimizer.b, As)

    options = optimizer.options
    if optimizer.silent
        options = copy(options)
        options[:printlevel] = 0
    end

    optimizer.status, optimizer.pobj, optimizer.dobj = sdp(
        optimizer.C, optimizer.b, optimizer.As, optimizer.X, optimizer.y,
        optimizer.Z, options)
    optimizer.solve_time = time() - start_time
end

function MOI.get(m::Optimizer, ::MOI.TerminationStatus)
    status = m.status
    if status == -1
        return MOI.OPTIMIZE_NOT_CALLED
    elseif status == 0
        return MOI.OPTIMAL
    elseif status == 1
        return MOI.INFEASIBLE
    elseif status == 2
        return MOI.DUAL_INFEASIBLE
    elseif status == 3
        return MOI.ALMOST_OPTIMAL
    elseif status == 4
        return MOI.ITERATION_LIMIT
    elseif 5 <= status <= 7
        return MOI.SLOW_PROGRESS
    elseif 8 <= status <= 9
        return MOI.NUMERICAL_ERROR
    else
        error("Internal library error: status=$status")
    end
end

function MOI.get(m::Optimizer, ::MOI.PrimalStatus)
    status = m.status
    if status == 0
        return MOI.FEASIBLE_POINT
    elseif status == 1
        return MOI.INFEASIBLE_POINT
    elseif status == 2
        return MOI.INFEASIBILITY_CERTIFICATE
    elseif status == 3
        return MOI.NEARLY_FEASIBLE_POINT
    elseif 4 <= status <= 9
        return MOI.UNKNOWN_RESULT_STATUS
    else
        error("Internal library error: status=$status")
    end
end

function MOI.get(m::Optimizer, ::MOI.DualStatus)
    status = m.status
    if status == 0
        return MOI.FEASIBLE_POINT
    elseif status == 1
        return MOI.INFEASIBILITY_CERTIFICATE
    elseif status == 2
        return MOI.INFEASIBLE_POINT
    elseif status == 3
        return MOI.NEARLY_FEASIBLE_POINT
    elseif 4 <= status <= 9
        return MOI.UNKNOWN_RESULT_STATUS
    else
        error("Internal library error: status=$status")
    end
end

MOI.get(m::Optimizer, ::MOI.ResultCount) = 1
function MOI.get(m::Optimizer, ::MOI.ObjectiveValue)
    return m.objsign * m.pobj + m.objconstant
end
function MOI.get(m::Optimizer, ::MOI.DualObjectiveValue)
    return m.objsign * m.dobj + m.objconstant
end
struct PrimalSolutionMatrix <: MOI.AbstractModelAttribute end
MOI.is_set_by_optimize(::PrimalSolutionMatrix) = true
MOI.get(optimizer::Optimizer, ::PrimalSolutionMatrix) = optimizer.X

struct DualSolutionVector <: MOI.AbstractModelAttribute end
MOI.is_set_by_optimize(::DualSolutionVector) = true
MOI.get(optimizer::Optimizer, ::DualSolutionVector) = optimizer.y

struct DualSlackMatrix <: MOI.AbstractModelAttribute end
MOI.is_set_by_optimize(::DualSlackMatrix) = true
MOI.get(optimizer::Optimizer, ::DualSlackMatrix) = optimizer.Z

function block(optimizer::Optimizer, ci::MOI.ConstraintIndex{MOI.VectorOfVariables})
    return optimizer.varmap[ci.value][1]
end
function dimension(optimizer::Optimizer, ci::MOI.ConstraintIndex{MOI.VectorOfVariables})
    blockdim = optimizer.blockdims[block(optimizer, ci)]
    if blockdim < 0
        return -blockdim
    else
        return MOI.dimension(MOI.PositiveSemidefiniteConeTriangle(blockdim))
    end
end
function vectorize_block(M, blk::Integer, s::Type{MOI.Nonnegatives})
    return diag(block(M, blk))
end
function vectorize_block(M::AbstractMatrix{Cdouble}, blk::Integer, s::Type{MOI.PositiveSemidefiniteConeTriangle}) where T
    B = block(M, blk)
    d = LinearAlgebra.checksquare(B)
    n = MOI.dimension(MOI.PositiveSemidefiniteConeTriangle(d))
    v = Vector{Cdouble}(undef, n)
    k = 0
    for j in 1:d
        for i in 1:j
            k += 1
            v[k] = B[i, j]
        end
    end
    @assert k == n
    return v
end

function MOI.get(optimizer::Optimizer, ::MOI.VariablePrimal, vi::MOI.VariableIndex)
    blk, i, j = varmap(optimizer, vi)
    return block(optimizer.X, blk)[i, j]
end

function MOI.get(m::Optimizer, ::MOI.ConstraintPrimal,
                 ci::MOI.ConstraintIndex{MOI.VectorOfVariables, S}) where S<:SupportedSets
    return vectorize_block(m.X, block(m, ci), S)
end
function MOI.get(m::Optimizer, ::MOI.ConstraintPrimal, ci::AFFEQ)
    return m.b[ci.value]
end

function MOI.get(optimizer::Optimizer, ::MOI.ConstraintDual,
                 ci::MOI.ConstraintIndex{MOI.VectorOfVariables, S}) where S<:SupportedSets
    return vectorize_block(optimizer.Z, block(optimizer, ci), S)
end
function MOI.get(optimizer::Optimizer, ::MOI.ConstraintDual, ci::AFFEQ)
    return -optimizer.y[ci.value]
end
