using MathOptInterface
const MOI = MathOptInterface
const MOIU = MOI.Utilities
const AFFEQ = MOI.ConstraintIndex{MOI.ScalarAffineFunction{Cdouble}, MOI.EqualTo{Cdouble}}

mutable struct Optimizer <: MOI.AbstractOptimizer
    objconstant::Cdouble
    objsign::Int
    blockdims::Vector{CSDP_INT}
    varmap::Vector{Tuple{Int, Int, Int}} # Variable Index vi -> blk, i, j
    num_entries::Dict{Tuple{Int, Int}, Int}
    b::Vector{Cdouble}
    C::blockmatrix
    problem::Union{Nothing, LoadingProblem}
    X::blockmatrix
    y::Union{Nothing, Vector{Cdouble}}
    Z::blockmatrix
    status::CSDP_INT
    pobj::Cdouble
    dobj::Cdouble
    solve_time::Float64
    silent::Bool
    options::Dict{Symbol, Any}
    function Optimizer(; kwargs...)
        optimizer = new(
            zero(Cdouble), 1, CSDP_INT[], Tuple{Int, Int, Int}[],
            Dict{Tuple{Int, Int}, Int}(), Cdouble[],
            blockmatrix(), nothing, blockmatrix(), nothing, blockmatrix(),
            -1, NaN, NaN, NaN, false, Dict{Symbol, Any}())
        for (key, value) in kwargs
            MOI.set(optimizer, MOI.RawParameter(String(key)), value)
        end
        # May need to call `free_loaded_prob` and `free_loading_prob`.
        finalizer(MOI.empty!, optimizer)
        return optimizer
    end
end

varmap(optimizer::Optimizer, vi::MOI.VariableIndex) = optimizer.varmap[vi.value]

function MOI.supports(optimizer::Optimizer, param::MOI.RawParameter)
    return Symbol(param.name) in ALLOWED_OPTIONS
end
function MOI.set(optimizer::Optimizer, param::MOI.RawParameter, value)
    if !(param.name isa String)
        Base.depwarn(
            "passing `$(param.name)` to `MOI.RawParameter` as type " *
            "`$(typeof(param.name))` is deprecated. Use a string instead.",
            Symbol("MOI.set")
        )
    end
    if !MOI.supports(optimizer, param)
        throw(MOI.UnsupportedAttribute(param))
    end
    optimizer.options[Symbol(param.name)] = value
end
function MOI.get(optimizer::Optimizer, param::MOI.RawParameter)
    # TODO: This gives a poor error message if the name of the parameter is invalid.
    if !(param.name isa String)
        Base.depwarn(
            "passing `$(param.name)` to `MOI.RawParameter` as type " *
            "`$(typeof(param.name))` is deprecated. Use a string instead.",
            Symbol("MOI.set")
        )
    end
    return optimizer.options[Symbol(param.name)]
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
        isone(optimizer.objsign) &&
        isempty(optimizer.blockdims) &&
        isempty(optimizer.varmap) &&
        isempty(optimizer.num_entries) &&
        isempty(optimizer.b) &&
        iszero(optimizer.C.nblocks) &&
        optimizer.C.blocks == C_NULL &&
        optimizer.problem === nothing
end

function MOI.empty!(optimizer::Optimizer)
    optimizer.objconstant = zero(Cdouble)
    optimizer.objsign = 1
    empty!(optimizer.blockdims)
    empty!(optimizer.varmap)
    empty!(optimizer.num_entries)
    empty!(optimizer.b)
    if optimizer.problem !== nothing
        if optimizer.y !== nothing
            free_loaded_prob(optimizer.problem, optimizer.X, optimizer.y, optimizer.Z)
        end
        free_loading_prob(optimizer.problem)
    end
    optimizer.problem = nothing
    optimizer.C.nblocks = 0
    optimizer.C.blocks = C_NULL
    optimizer.X.nblocks = 0
    optimizer.X.blocks = C_NULL
    optimizer.y = nothing
    optimizer.Z.nblocks = 0
    optimizer.Z.blocks = C_NULL
    optimizer.status = -1
    optimizer.pobj = 0.0
    optimizer.dobj = 0.0
end

function MOI.supports(
    optimizer::Optimizer,
    ::Union{MOI.ObjectiveSense,
            MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Cdouble}}})
    return true
end

MOI.supports_add_constrained_variables(::Optimizer, ::Type{MOI.Reals}) = false

const SupportedSets = Union{MOI.Nonnegatives, MOI.PositiveSemidefiniteConeTriangle}
MOI.supports_add_constrained_variables(::Optimizer, ::Type{<:SupportedSets}) = true
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
function MOIU.allocate(::Optimizer, ::MOI.ObjectiveFunction, ::MOI.ScalarAffineFunction) end

function MOIU.load(::Optimizer, ::MOI.ObjectiveSense, ::MOI.OptimizationSense) end
# Loads objective coefficient α * vi
function load_objective_term!(optimizer::Optimizer, α, vi::MOI.VariableIndex)
    blk, i, j = varmap(optimizer, vi)
    # in SDP format, it is max and in MPB Conic format it is min
    coef = optimizer.objsign * α
    if i != j
        coef /= 2
    end
    addentry(optimizer.problem, 0, blk, i, j, coef, true)
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
        optimizer.blockdims = [optimizer.blockdims; CSDP_INT(-1)]
        count_entry(optimizer, 1, length(optimizer.blockdims))
    end
    optimizer.C.nblocks = length(optimizer.blockdims)
    num_entries = zeros(CSDP_INT, length(optimizer.b), length(optimizer.blockdims))
    for (key, value) in optimizer.num_entries
        num_entries[key...] = value
    end
    optimizer.problem = allocate_loading_prob(Ref(optimizer.C), optimizer.blockdims, length(optimizer.b), num_entries, 3)
    if dummy
        # See https://github.com/coin-or/Csdp/issues/2
        duplicate = addentry(optimizer.problem, 1, length(optimizer.blockdims), 1, 1, 1.0, true)
        @assert !duplicate
    end

end

function count_entry(optimizer::Optimizer, con_idx::Integer, blk::Integer)
    key = (con_idx, blk)
    optimizer.num_entries[key] = get(optimizer.num_entries, key, 0) + 1
end

function MOIU.allocate_constraint(optimizer::Optimizer,
                                  func::MOI.ScalarAffineFunction{Cdouble},
                                  set::MOI.EqualTo{Cdouble})
    if !iszero(MOI.constant(func))
        throw(MOI.ScalarFunctionConstantNotZero{
            Cdouble, MOI.ScalarAffineFunction{Cdouble}, MOI.EqualTo{Cdouble}}(
                MOI.constant(func)))
    end
    push!(optimizer.b, MOI.constant(set))
    func = MOIU.canonical(func) # sum terms with same variables and same output_index
    for t in func.terms
        if !iszero(t.coefficient)
            blk, i, j = varmap(optimizer, t.variable_index)
            count_entry(optimizer, length(optimizer.b), blk)
        end
    end
    return AFFEQ(length(optimizer.b))
end

function MOIU.load_constraint(optimizer::Optimizer, ci::AFFEQ,
                              f::MOI.ScalarAffineFunction, s::MOI.EqualTo)
    if !iszero(MOI.constant(f))
        throw(MOI.ScalarFunctionConstantNotZero{
            Cdouble, MOI.ScalarAffineFunction{Cdouble}, MOI.EqualTo{Cdouble}}(
                MOI.constant(f)))
    end
    setconstant(optimizer.problem, ci.value, MOI.constant(s))
    f = MOIU.canonical(f) # sum terms with same variables and same output_index
    if isempty(f.terms)
        throw(ArgumentError("Empty constraint $ci: $f-in-$s. Not supported by CSDP."))
    end
    for t in f.terms
        if !iszero(t.coefficient)
            blk, i, j = varmap(optimizer, t.variable_index)
            coef = t.coefficient
            if i != j
                coef /= 2
            end
            duplicate = addentry(optimizer.problem, ci.value, blk, i, j, coef, true)
            @assert !duplicate
        end
    end
end


function MOI.optimize!(optimizer::Optimizer)
    write_prob(optimizer)

    start_time = time()
    optimizer.y = loaded_initsoln(optimizer.problem, length(optimizer.b), Ref(optimizer.X), Ref(optimizer.Z))

    options = optimizer.options
    if optimizer.silent
        options = copy(options)
        options[:printlevel] = 0
    end

    optimizer.status, optimizer.pobj, optimizer.dobj = loaded_sdp(
        optimizer.problem, Ref(optimizer.X), optimizer.y,
        Ref(optimizer.Z), options)
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

function MOI.get(m::Optimizer, attr::MOI.PrimalStatus)
    if attr.N > MOI.get(m, MOI.ResultCount())
        return MOI.NO_SOLUTION
    end
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

function MOI.get(m::Optimizer, attr::MOI.DualStatus)
    if attr.N > MOI.get(m, MOI.ResultCount())
        return MOI.NO_SOLUTION
    end
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
function MOI.get(m::Optimizer, attr::MOI.ObjectiveValue)
    MOI.check_result_index_bounds(m, attr)
    return m.objsign * m.pobj + m.objconstant
end
function MOI.get(m::Optimizer, attr::MOI.DualObjectiveValue)
    MOI.check_result_index_bounds(m, attr)
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

function MOI.get(optimizer::Optimizer, attr::MOI.VariablePrimal, vi::MOI.VariableIndex)
    MOI.check_result_index_bounds(optimizer, attr)
    blk, i, j = varmap(optimizer, vi)
    return block(MOI.get(optimizer, PrimalSolutionMatrix()), blk)[i, j]
end

function MOI.get(optimizer::Optimizer, attr::MOI.ConstraintPrimal,
                 ci::MOI.ConstraintIndex{MOI.VectorOfVariables, S}) where S<:SupportedSets
    MOI.check_result_index_bounds(optimizer, attr)
    return vectorize_block(MOI.get(optimizer, PrimalSolutionMatrix()), block(optimizer, ci), S)
end
function MOI.get(optimizer::Optimizer, attr::MOI.ConstraintPrimal, ci::AFFEQ)
    MOI.check_result_index_bounds(optimizer, attr)
    return optimizer.b[ci.value]
end

function MOI.get(optimizer::Optimizer, attr::MOI.ConstraintDual,
                 ci::MOI.ConstraintIndex{MOI.VectorOfVariables, S}) where S<:SupportedSets
    MOI.check_result_index_bounds(optimizer, attr)
    return vectorize_block(MOI.get(optimizer, DualSlackMatrix()), block(optimizer, ci), S)
end
function MOI.get(optimizer::Optimizer, attr::MOI.ConstraintDual, ci::AFFEQ)
    MOI.check_result_index_bounds(optimizer, attr)
    return -MOI.get(optimizer, DualSolutionVector())[ci.value]
end
