using MathOptInterface
const MOI = MathOptInterface
const AFF = MOI.ScalarAffineFunction{Cdouble}
const EQ = MOI.EqualTo{Cdouble}
const AFFEQ = MOI.ConstraintIndex{AFF,EQ}

mutable struct Optimizer <: MOI.AbstractOptimizer
    objective_constant::Cdouble
    objective_sign::Int
    blockdims::Vector{CSDP_INT}
    varmap::Vector{Tuple{Int,Int,Int}} # Variable Index vi -> blk, i, j
    num_entries::Dict{Tuple{Int,Int},Int}
    b::Vector{Cdouble}
    C::blockmatrix
    problem::Union{Nothing,LoadingProblem}
    X::blockmatrix
    y::Union{Nothing,Vector{Cdouble}}
    Z::blockmatrix
    status::CSDP_INT
    pobj::Cdouble
    dobj::Cdouble
    solve_time::Float64
    silent::Bool
    options::Dict{Symbol,Any}
    function Optimizer(; kwargs...)
        optimizer = new(
            zero(Cdouble),
            1,
            CSDP_INT[],
            Tuple{Int,Int,Int}[],
            Dict{Tuple{Int,Int},Int}(),
            Cdouble[],
            blockmatrix(),
            nothing,
            blockmatrix(),
            nothing,
            blockmatrix(),
            -1,
            NaN,
            NaN,
            NaN,
            false,
            Dict{Symbol,Any}(),
        )
        for (key, value) in kwargs
            MOI.set(optimizer, MOI.RawOptimizerAttribute(String(key)), value)
        end
        # May need to call `free_loaded_prob` and `free_loading_prob`.
        finalizer(MOI.empty!, optimizer)
        return optimizer
    end
end

varmap(optimizer::Optimizer, vi::MOI.VariableIndex) = optimizer.varmap[vi.value]

function MOI.supports(optimizer::Optimizer, param::MOI.RawOptimizerAttribute)
    return Symbol(param.name) in ALLOWED_OPTIONS
end
function MOI.set(optimizer::Optimizer, param::MOI.RawOptimizerAttribute, value)
    if !(param.name isa String)
        Base.depwarn(
            "passing `$(param.name)` to `MOI.RawOptimizerAttribute` as type " *
            "`$(typeof(param.name))` is deprecated. Use a string instead.",
            Symbol("MOI.set"),
        )
    end
    if !MOI.supports(optimizer, param)
        throw(MOI.UnsupportedAttribute(param))
    end
    return optimizer.options[Symbol(param.name)] = value
end
function MOI.get(optimizer::Optimizer, param::MOI.RawOptimizerAttribute)
    # TODO: This gives a poor error message if the name of the parameter is invalid.
    if !(param.name isa String)
        Base.depwarn(
            "passing `$(param.name)` to `MOI.RawOptimizerAttribute` as type " *
            "`$(typeof(param.name))` is deprecated. Use a string instead.",
            Symbol("MOI.set"),
        )
    end
    return optimizer.options[Symbol(param.name)]
end

MOI.supports(::Optimizer, ::MOI.Silent) = true
function MOI.set(optimizer::Optimizer, ::MOI.Silent, value::Bool)
    return optimizer.silent = value
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
    "Program stopped by signal (SIXCPU, SIGTERM, etc.)",
]

function MOI.get(optimizer::Optimizer, ::MOI.RawStatusString)
    return RAW_STATUS[optimizer.status+1]
end
function MOI.get(optimizer::Optimizer, ::MOI.SolveTimeSec)
    return optimizer.solve_time
end

function MOI.is_empty(optimizer::Optimizer)
    return iszero(optimizer.objective_constant) &&
           isone(optimizer.objective_sign) &&
           isempty(optimizer.blockdims) &&
           isempty(optimizer.varmap) &&
           isempty(optimizer.num_entries) &&
           isempty(optimizer.b) &&
           iszero(optimizer.C.nblocks) &&
           optimizer.C.blocks == C_NULL &&
           optimizer.problem === nothing
end

function MOI.empty!(optimizer::Optimizer)
    optimizer.objective_constant = zero(Cdouble)
    optimizer.objective_sign = 1
    empty!(optimizer.blockdims)
    empty!(optimizer.varmap)
    empty!(optimizer.num_entries)
    empty!(optimizer.b)
    if optimizer.problem !== nothing
        if optimizer.y !== nothing
            free_loaded_prob(
                optimizer.problem,
                optimizer.X,
                optimizer.y,
                optimizer.Z,
            )
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
    return optimizer.dobj = 0.0
end

function MOI.supports(
    optimizer::Optimizer,
    ::Union{MOI.ObjectiveSense,MOI.ObjectiveFunction{AFF}},
)
    return true
end

MOI.supports_add_constrained_variables(::Optimizer, ::Type{MOI.Reals}) = false

const SupportedSets =
    Union{MOI.Nonnegatives,MOI.PositiveSemidefiniteConeTriangle}
function MOI.supports_add_constrained_variables(
    ::Optimizer,
    ::Type{<:SupportedSets},
)
    return true
end
function MOI.supports_constraint(::Optimizer, ::Type{AFF}, ::Type{EQ})
    return true
end

function _new_block(optimizer::Optimizer, set::MOI.Nonnegatives)
    push!(optimizer.blockdims, -MOI.dimension(set))
    blk = length(optimizer.blockdims)
    for i in 1:MOI.dimension(set)
        push!(optimizer.varmap, (blk, i, i))
    end
end

function _new_block(
    optimizer::Optimizer,
    set::MOI.PositiveSemidefiniteConeTriangle,
)
    push!(optimizer.blockdims, set.side_dimension)
    blk = length(optimizer.blockdims)
    for i in 1:set.side_dimension
        for j in 1:i
            push!(optimizer.varmap, (blk, i, j))
        end
    end
end

function _add_constrained_variables(optimizer::Optimizer, set::SupportedSets)
    offset = length(optimizer.varmap)
    _new_block(optimizer, set)
    ci = MOI.ConstraintIndex{MOI.VectorOfVariables,typeof(set)}(offset + 1)
    return [MOI.VariableIndex(i) for i in offset .+ (1:MOI.dimension(set))], ci
end

function _error(start, stop)
    return error(
        start,
        ". Use `MOI.instantiate(CSDP.Optimizer, with_bridge_type = Float64)` ",
        stop,
    )
end

function constrain_variables_on_creation(
    dest::MOI.ModelLike,
    src::MOI.ModelLike,
    index_map::MOI.Utilities.IndexMap,
    ::Type{S},
) where {S<:MOI.AbstractVectorSet}
    for ci_src in
        MOI.get(src, MOI.ListOfConstraintIndices{MOI.VectorOfVariables,S}())
        f_src = MOI.get(src, MOI.ConstraintFunction(), ci_src)
        if !allunique(f_src.variables)
            _error(
                "Cannot copy constraint `$(ci_src)` as variables constrained on creation because there are duplicate variables in the function `$(f_src)`",
                "to bridge this by creating slack variables.",
            )
        elseif any(vi -> haskey(index_map, vi), f_src.variables)
            _error(
                "Cannot copy constraint `$(ci_src)` as variables constrained on creation because some variables of the function `$(f_src)` are in another constraint as well.",
                "to bridge constraints having the same variables by creating slack variables.",
            )
        else
            set = MOI.get(src, MOI.ConstraintSet(), ci_src)::S
            vis_dest, ci_dest = _add_constrained_variables(dest, set)
            index_map[ci_src] = ci_dest
            for (vi_src, vi_dest) in zip(f_src.variables, vis_dest)
                index_map[vi_src] = vi_dest
            end
        end
    end
end

function count_entry(optimizer::Optimizer, con_idx::Integer, blk::Integer)
    key = (con_idx, blk)
    return optimizer.num_entries[key] = get(optimizer.num_entries, key, 0) + 1
end

# Loads objective coefficient α * vi
function load_objective_term!(optimizer::Optimizer, α, vi::MOI.VariableIndex)
    blk, i, j = varmap(optimizer, vi)
    # in SDP format, it is max and in MPB Conic format it is min
    coef = optimizer.objective_sign * α
    if i != j
        coef /= 2
    end
    return addentry(optimizer.problem, 0, blk, i, j, coef, true)
end

function MOI.copy_to(dest::Optimizer, src::MOI.ModelLike)
    MOI.empty!(dest)
    index_map = MOI.Utilities.IndexMap()

    # Step 1) Compute the dimensions of what needs to be allocated
    constrain_variables_on_creation(dest, src, index_map, MOI.Nonnegatives)
    constrain_variables_on_creation(
        dest,
        src,
        index_map,
        MOI.PositiveSemidefiniteConeTriangle,
    )
    vis_src = MOI.get(src, MOI.ListOfVariableIndices())
    if length(vis_src) < length(index_map.var_map)
        _error(
            "Free variables are not supported by CSDP",
            "to bridge free variables into `x - y` where `x` and `y` are nonnegative.",
        )
    end
    cis_src = MOI.get(src, MOI.ListOfConstraintIndices{AFF,EQ}())
    dest.b = Vector{Cdouble}(undef, length(cis_src))
    funcs = Vector{AFF}(undef, length(cis_src))
    for (k, ci_src) in enumerate(cis_src)
        funcs[k] = MOI.get(src, MOI.CanonicalConstraintFunction(), ci_src)
        set = MOI.get(src, MOI.ConstraintSet(), ci_src)
        if isempty(funcs[k].terms)
            throw(
                ArgumentError(
                    "Empty constraint $cis_src: $(funcs[k])-in-$set. Not supported by CSDP.",
                ),
            )
        end
        if !iszero(MOI.constant(funcs[k]))
            throw(
                MOI.ScalarFunctionConstantNotZero{Cdouble,AFF,EQ}(
                    MOI.constant(funcs[k]),
                ),
            )
        end
        for t in funcs[k].terms
            if !iszero(t.coefficient)
                blk, _, _ = varmap(dest, index_map[t.variable])
                count_entry(dest, k, blk)
            end
        end
        dest.b[k] = MOI.constant(set)
        index_map[ci_src] = AFFEQ(k)
    end

    # Step 2) Allocate CSDP datastructures
    dummy = isempty(dest.b)
    if dummy
        # See https://github.com/coin-or/Csdp/issues/2
        dest.b = [one(Cdouble)]
        dest.blockdims = [dest.blockdims; CSDP_INT(-1)]
        count_entry(dest, 1, length(dest.blockdims))
    end
    dest.C.nblocks = length(dest.blockdims)
    num_entries = zeros(CSDP_INT, length(dest.b), length(dest.blockdims))
    for (key, value) in dest.num_entries
        num_entries[key...] = value
    end
    dest.problem = allocate_loading_prob(
        Ref(dest.C),
        dest.blockdims,
        length(dest.b),
        num_entries,
        3,
    )
    if dummy
        # See https://github.com/coin-or/Csdp/issues/2
        duplicate =
            addentry(dest.problem, 1, length(dest.blockdims), 1, 1, 1.0, true)
        @assert !duplicate
    end

    # Step 3) Load data in the datastructures
    for k in eachindex(funcs)
        setconstant(dest.problem, k, dest.b[k])
        for term in funcs[k].terms
            if !iszero(term.coefficient)
                blk, i, j = varmap(dest, index_map[term.variable])
                coef = term.coefficient
                if i != j
                    coef /= 2
                end
                duplicate = addentry(dest.problem, k, blk, i, j, coef, true)
                @assert !duplicate
            end
        end
    end

    # Throw error for variable attributes
    MOI.Utilities.pass_attributes(dest, src, index_map, vis_src)
    # Throw error for constraint attributes
    MOI.Utilities.pass_attributes(dest, src, index_map, cis_src)

    # Pass objective attributes and throw error for other ones
    model_attributes = MOI.get(src, MOI.ListOfModelAttributesSet())
    for attr in model_attributes
        if attr != MOI.ObjectiveSense() && attr != MOI.ObjectiveFunction{AFF}()
            throw(MOI.UnsupportedAttribute(attr))
        end
    end
    # We make sure to set `objective_sign` first before setting the objective
    if MOI.ObjectiveSense() in model_attributes
        sense = MOI.get(src, MOI.ObjectiveSense())
        dest.objective_sign = sense == MOI.MIN_SENSE ? -1 : 1
    end
    if MOI.ObjectiveFunction{AFF}() in model_attributes
        func = MOI.get(src, MOI.ObjectiveFunction{AFF}())
        obj = MOI.Utilities.canonical(func)
        dest.objective_constant = obj.constant
        for term in obj.terms
            if !iszero(term.coefficient)
                load_objective_term!(
                    dest,
                    term.coefficient,
                    index_map[term.variable],
                )
            end
        end
    end
    return index_map
end

function MOI.optimize!(optimizer::Optimizer)
    write_prob(optimizer)

    start_time = time()
    optimizer.y = loaded_initsoln(
        optimizer.problem,
        length(optimizer.b),
        Ref(optimizer.X),
        Ref(optimizer.Z),
    )

    options = optimizer.options
    if optimizer.silent
        options = copy(options)
        options[:printlevel] = 0
    end

    optimizer.status, optimizer.pobj, optimizer.dobj = loaded_sdp(
        optimizer.problem,
        optimizer.objective_sign * optimizer.objective_constant,
        Ref(optimizer.X),
        optimizer.y,
        Ref(optimizer.Z),
        options,
    )
    optimizer.solve_time = time() - start_time
    return
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
    if attr.result_index > MOI.get(m, MOI.ResultCount())
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
    if attr.result_index > MOI.get(m, MOI.ResultCount())
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
    return m.objective_sign * m.pobj
end
function MOI.get(m::Optimizer, attr::MOI.DualObjectiveValue)
    MOI.check_result_index_bounds(m, attr)
    return m.objective_sign * m.dobj
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

function block(
    optimizer::Optimizer,
    ci::MOI.ConstraintIndex{MOI.VectorOfVariables},
)
    return optimizer.varmap[ci.value][1]
end
function vectorize_block(M, blk::Integer, s::Type{MOI.Nonnegatives})
    return diag(block(M, blk))
end
function vectorize_block(
    M::AbstractMatrix{Cdouble},
    blk::Integer,
    s::Type{MOI.PositiveSemidefiniteConeTriangle},
) where {T}
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

function MOI.get(
    optimizer::Optimizer,
    attr::MOI.VariablePrimal,
    vi::MOI.VariableIndex,
)
    MOI.check_result_index_bounds(optimizer, attr)
    blk, i, j = varmap(optimizer, vi)
    return block(MOI.get(optimizer, PrimalSolutionMatrix()), blk)[i, j]
end

function MOI.get(
    optimizer::Optimizer,
    attr::MOI.ConstraintPrimal,
    ci::MOI.ConstraintIndex{MOI.VectorOfVariables,S},
) where {S<:SupportedSets}
    MOI.check_result_index_bounds(optimizer, attr)
    return vectorize_block(
        MOI.get(optimizer, PrimalSolutionMatrix()),
        block(optimizer, ci),
        S,
    )
end
function MOI.get(optimizer::Optimizer, attr::MOI.ConstraintPrimal, ci::AFFEQ)
    MOI.check_result_index_bounds(optimizer, attr)
    return optimizer.b[ci.value]
end

function MOI.get(
    optimizer::Optimizer,
    attr::MOI.ConstraintDual,
    ci::MOI.ConstraintIndex{MOI.VectorOfVariables,S},
) where {S<:SupportedSets}
    MOI.check_result_index_bounds(optimizer, attr)
    return vectorize_block(
        MOI.get(optimizer, DualSlackMatrix()),
        block(optimizer, ci),
        S,
    )
end
function MOI.get(optimizer::Optimizer, attr::MOI.ConstraintDual, ci::AFFEQ)
    MOI.check_result_index_bounds(optimizer, attr)
    return -MOI.get(optimizer, DualSolutionVector())[ci.value]
end
