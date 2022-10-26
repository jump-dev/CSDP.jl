# Copyright (c) 2016: CSDP.jl contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

import MathOptInterface

const MOI = MathOptInterface

mutable struct Optimizer <: MOI.AbstractOptimizer
    objective_constant::Cdouble
    objective_sign::Int
    blockdims::Vector{CSDP_INT}
    varmap::Vector{Tuple{Int,Int,Int}} # Variable Index vi -> blk, i, j
    num_entries::Dict{Tuple{Int,Int},Int}
    b::Vector{Cdouble}
    C::blockmatrix
    problem::Union{Nothing,Ptr{Cvoid}}
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
        model = new(
            zero(Cdouble),
            1,
            CSDP_INT[],
            Tuple{Int,Int,Int}[],
            Dict{Tuple{Int,Int},Int}(),
            Cdouble[],
            blockmatrix(CSDP_INT(0), C_NULL),
            nothing,
            blockmatrix(CSDP_INT(0), C_NULL),
            nothing,
            blockmatrix(CSDP_INT(0), C_NULL),
            -1,
            NaN,
            NaN,
            NaN,
            false,
            Dict{Symbol,Any}(),
        )
        for (key, value) in kwargs
            MOI.set(model, MOI.RawOptimizerAttribute(String(key)), value)
        end
        # May need to call `free_loaded_prob` and `free_loading_prob`.
        finalizer(MOI.empty!, model)
        return model
    end
end

varmap(model::Optimizer, vi::MOI.VariableIndex) = model.varmap[vi.value]

function MOI.is_empty(model::Optimizer)
    return iszero(model.objective_constant) &&
           isone(model.objective_sign) &&
           isempty(model.blockdims) &&
           isempty(model.varmap) &&
           isempty(model.num_entries) &&
           isempty(model.b) &&
           iszero(model.C.nblocks) &&
           model.C.blocks == C_NULL &&
           model.problem === nothing
end

function MOI.empty!(model::Optimizer)
    model.objective_constant = zero(Cdouble)
    model.objective_sign = 1
    empty!(model.blockdims)
    empty!(model.varmap)
    empty!(model.num_entries)
    empty!(model.b)
    model.C.nblocks = 0
    model.C.blocks = C_NULL
    if model.problem !== nothing
        if model.y !== nothing
            free_loaded_prob(model.problem, model.X, offset(model.y), model.Z)
        end
        free_loading_prob(model.problem)
    end
    model.problem = nothing
    model.X.nblocks = 0
    model.X.blocks = C_NULL
    model.y = nothing
    model.Z.nblocks = 0
    model.Z.blocks = C_NULL
    model.status = -1
    model.pobj = 0.0
    model.dobj = 0.0
    return
end

###
### RawOptimizerAttribute
###

function MOI.supports(::Optimizer, param::MOI.RawOptimizerAttribute)
    return hasfield(paramstruc, Symbol(param.name)) || param == "printlevel"
end

function MOI.set(model::Optimizer, param::MOI.RawOptimizerAttribute, value)
    if !MOI.supports(model, param)
        throw(MOI.UnsupportedAttribute(param))
    end
    return model.options[Symbol(param.name)] = value
end

function MOI.get(model::Optimizer, param::MOI.RawOptimizerAttribute)
    return model.options[Symbol(param.name)]
end

###
### Silent
###

MOI.supports(::Optimizer, ::MOI.Silent) = true

function MOI.set(model::Optimizer, ::MOI.Silent, value::Bool)
    model.silent = value
    return
end

MOI.get(model::Optimizer, ::MOI.Silent) = model.silent

###
### SolverName
###

MOI.get(::Optimizer, ::MOI.SolverName) = "CSDP"

###
### ObjectiveSense
###

MOI.supports(::Optimizer, ::MOI.ObjectiveSense) = true

###
### ObjectiveFunction
###

function MOI.supports(
    ::Optimizer,
    ::MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Cdouble}},
)
    return true
end

###
### supports_constraint
###

MOI.supports_add_constrained_variables(::Optimizer, ::Type{MOI.Reals}) = false

const SupportedSets =
    Union{MOI.Nonnegatives,MOI.PositiveSemidefiniteConeTriangle}

function MOI.supports_add_constrained_variables(
    ::Optimizer,
    ::Type{<:SupportedSets},
)
    return true
end

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.ScalarAffineFunction{Cdouble}},
    ::Type{MOI.EqualTo{Cdouble}},
)
    return true
end

function _new_block(model::Optimizer, set::MOI.Nonnegatives)
    push!(model.blockdims, -MOI.dimension(set))
    blk = length(model.blockdims)
    for i in 1:MOI.dimension(set)
        push!(model.varmap, (blk, i, i))
    end
    return
end

function _new_block(model::Optimizer, set::MOI.PositiveSemidefiniteConeTriangle)
    push!(model.blockdims, set.side_dimension)
    blk = length(model.blockdims)
    for i in 1:set.side_dimension
        for j in 1:i
            push!(model.varmap, (blk, i, j))
        end
    end
    return
end

function _add_constrained_variables(model::Optimizer, set::SupportedSets)
    offset = length(model.varmap)
    _new_block(model, set)
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
                "Cannot copy constraint `$(ci_src)` as variables constrained " *
                "on creation because there are duplicate variables in the " *
                "function `$(f_src)`",
                "to bridge this by creating slack variables.",
            )
        elseif any(vi -> haskey(index_map, vi), f_src.variables)
            _error(
                "Cannot copy constraint `$(ci_src)` as variables constrained " *
                "on creation because some variables of the function " *
                "`$(f_src)` are in another constraint as well.",
                "to bridge constraints having the same variables by creating " *
                "slack variables.",
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
    return
end

function count_entry(model::Optimizer, con_idx::Integer, blk::Integer)
    key = (con_idx, blk)
    model.num_entries[key] = get(model.num_entries, key, 0) + 1
    return
end

# Loads objective coefficient α * vi
function load_objective_term!(model::Optimizer, α, vi::MOI.VariableIndex)
    blk, i, j = varmap(model, vi)
    # in SDP format, it is max and in MPB Conic format it is min
    coef = model.objective_sign * α
    if i != j
        coef /= 2
    end
    ret = addentry(model.problem, 0, blk, i, j, coef, true)
    return !iszero(ret)
end

function _check_unsupported_constraints(dest, src)
    for (F, S) in MOI.get(src, MOI.ListOfConstraintTypesPresent())
        constrained_variable =
            F == MOI.VectorOfVariables &&
            MOI.supports_add_constrained_variables(dest, S)
        if !(MOI.supports_constraint(dest, F, S) || constrained_variable)
            throw(MOI.UnsupportedConstraint{F,S}())
        end
    end
    return
end

function MOI.copy_to(dest::Optimizer, src::MOI.ModelLike)
    _check_unsupported_constraints(dest, src)
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
            "to bridge free variables into `x - y` where `x` and `y` are " *
            "nonnegative.",
        )
    end
    F, S = MOI.ScalarAffineFunction{Cdouble}, MOI.EqualTo{Cdouble}
    cis_src = MOI.get(src, MOI.ListOfConstraintIndices{F,S}())
    dest.b = Vector{Cdouble}(undef, length(cis_src))
    funcs = Vector{MOI.ScalarAffineFunction{Cdouble}}(undef, length(cis_src))
    for (k, ci_src) in enumerate(cis_src)
        funcs[k] = MOI.get(src, MOI.CanonicalConstraintFunction(), ci_src)
        set = MOI.get(src, MOI.ConstraintSet(), ci_src)
        if isempty(funcs[k].terms)
            throw(
                ArgumentError(
                    "Empty constraint $cis_src: $(funcs[k])-in-$set. Not " *
                    "supported by CSDP.",
                ),
            )
        end
        if !iszero(MOI.constant(funcs[k]))
            c = MOI.constant(funcs[k])
            throw(MOI.ScalarFunctionConstantNotZero{Cdouble,F,S}(c))
        end
        for t in funcs[k].terms
            if !iszero(t.coefficient)
                blk, _, _ = varmap(dest, index_map[t.variable])
                count_entry(dest, k, blk)
            end
        end
        dest.b[k] = MOI.constant(set)
        index_map[ci_src] = MOI.ConstraintIndex{F,S}(k)
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
        dest.C,
        offset(dest.blockdims),
        length(dest.b),
        num_entries,
        3,
    )
    if dummy
        # See https://github.com/coin-or/Csdp/issues/2
        duplicate =
            addentry(dest.problem, 1, length(dest.blockdims), 1, 1, 1.0, true)
        @assert iszero(duplicate)
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
                @assert iszero(duplicate)
            end
        end
    end
    # Throw error for variable attributes
    MOI.Utilities.pass_attributes(dest, src, index_map, vis_src)
    # Throw error for constraint attributes
    MOI.Utilities.pass_attributes(dest, src, index_map, cis_src)
    # Pass objective attributes and throw error for other ones
    model_attributes = MOI.get(src, MOI.ListOfModelAttributesSet())
    obj_attr = MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Cdouble}}()
    for attr in model_attributes
        if attr != MOI.ObjectiveSense() && attr != obj_attr
            throw(MOI.UnsupportedAttribute(attr))
        end
    end
    # We make sure to set `objective_sign` first before setting the objective
    if MOI.ObjectiveSense() in model_attributes
        sense = MOI.get(src, MOI.ObjectiveSense())
        dest.objective_sign = sense == MOI.MIN_SENSE ? -1 : 1
    end
    if obj_attr in model_attributes
        obj = MOI.Utilities.canonical(MOI.get(src, obj_attr))
        dest.objective_constant = obj.constant
        for t in obj.terms
            if !iszero(t.coefficient)
                load_objective_term!(dest, t.coefficient, index_map[t.variable])
            end
        end
    end
    return index_map
end

function MOI.optimize!(model::Optimizer)
    start_time = time()
    y_ptr = loaded_initsoln(model.problem, model.X, model.Z)
    model.y = unsafe_wrap(
        Array,
        y_ptr + sizeof(Cdouble),
        length(model.b);
        own = false,
    )
    options = model.options
    print_level = model.silent ? Cint(0) : get(options, :print_level, Cint(1))
    model.status, model.pobj, model.dobj = loaded_sdp(
        model.problem,
        model.objective_sign * model.objective_constant,
        model.X,
        Ref{Ptr{Cdouble}}(offset(model.y)),
        model.Z,
        print_level,
        paramstruc(options),
    )
    model.solve_time = time() - start_time
    return
end

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

MOI.get(model::Optimizer, ::MOI.RawStatusString) = RAW_STATUS[model.status+1]

MOI.get(::Optimizer, ::MOI.ResultCount) = 1

function MOI.get(model::Optimizer, ::MOI.TerminationStatus)
    if model.status == -1
        return MOI.OPTIMIZE_NOT_CALLED
    elseif model.status == 0
        return MOI.OPTIMAL
    elseif model.status == 1
        return MOI.INFEASIBLE
    elseif model.status == 2
        return MOI.DUAL_INFEASIBLE
    elseif model.status == 3
        return MOI.ALMOST_OPTIMAL
    elseif model.status == 4
        return MOI.ITERATION_LIMIT
    elseif 5 <= model.status <= 7
        return MOI.SLOW_PROGRESS
    else
        @assert 8 <= model.status <= 9
        return MOI.NUMERICAL_ERROR
    end
end

function MOI.get(model::Optimizer, attr::MOI.PrimalStatus)
    if attr.result_index != 1
        return MOI.NO_SOLUTION
    elseif model.status == -1
        return MOI.NO_SOLUTION
    elseif model.status == 0
        return MOI.FEASIBLE_POINT
    elseif model.status == 1
        return MOI.INFEASIBLE_POINT
        # elseif model.status == 2
        #     return MOI.INFEASIBILITY_CERTIFICATE
    elseif model.status == 3
        return MOI.NEARLY_FEASIBLE_POINT
    else
        return MOI.UNKNOWN_RESULT_STATUS
    end
end

function MOI.get(model::Optimizer, attr::MOI.DualStatus)
    if attr.result_index != 1
        return MOI.NO_SOLUTION
    elseif model.status == -1
        return MOI.NO_SOLUTION
    elseif model.status == 0
        return MOI.FEASIBLE_POINT
        # elseif model.status == 1
        #     return MOI.INFEASIBILITY_CERTIFICATE
    elseif model.status == 2
        return MOI.INFEASIBLE_POINT
    elseif model.status == 3
        return MOI.NEARLY_FEASIBLE_POINT
    else
        return MOI.UNKNOWN_RESULT_STATUS
    end
end

MOI.get(model::Optimizer, ::MOI.SolveTimeSec) = model.solve_time

function MOI.get(model::Optimizer, attr::MOI.ObjectiveValue)
    MOI.check_result_index_bounds(model, attr)
    return model.objective_sign * model.pobj
end

function MOI.get(model::Optimizer, attr::MOI.DualObjectiveValue)
    MOI.check_result_index_bounds(model, attr)
    return model.objective_sign * model.dobj
end

function MOI.get(
    model::Optimizer,
    attr::MOI.VariablePrimal,
    x::MOI.VariableIndex,
)
    MOI.check_result_index_bounds(model, attr)
    blk, i, j = varmap(model, x)
    return getblockrec(model.X, blk)[i, j]
end

function MOI.get(
    model::Optimizer,
    attr::MOI.ConstraintPrimal,
    ci::MOI.ConstraintIndex{
        MOI.ScalarAffineFunction{Cdouble},
        MOI.EqualTo{Cdouble},
    },
)
    MOI.check_result_index_bounds(model, attr)
    # TODO(odow): this isn't correct. In Ax = b, it should be Ax, not b.
    return model.b[ci.value]
end

function MOI.get(
    model::Optimizer,
    attr::MOI.ConstraintDual,
    ci::MOI.ConstraintIndex{
        MOI.ScalarAffineFunction{Cdouble},
        MOI.EqualTo{Cdouble},
    },
)
    MOI.check_result_index_bounds(model, attr)
    return -model.y[ci.value]
end

function _vectorize_block(M::blockmatrix, blk, ::Type{MOI.Nonnegatives})
    rec = getblockrec(M, blk)
    return [rec[i, i] for i in 1:rec.blocksize]
end

function _vectorize_block(
    M::blockmatrix,
    blk,
    ::Type{MOI.PositiveSemidefiniteConeTriangle},
)
    B = getblockrec(M, blk)
    n = MOI.dimension(MOI.PositiveSemidefiniteConeTriangle(B.blocksize))
    v = Vector{Cdouble}(undef, n)
    k = 0
    for j in 1:B.blocksize
        for i in 1:j
            k += 1
            v[k] = B[i, j]
        end
    end
    @assert k == n
    return v
end

function MOI.get(
    model::Optimizer,
    attr::MOI.ConstraintPrimal,
    ci::MOI.ConstraintIndex{MOI.VectorOfVariables,S},
) where {S<:SupportedSets}
    MOI.check_result_index_bounds(model, attr)
    blk = model.varmap[ci.value][1]
    return _vectorize_block(model.X, blk, S)
end

function MOI.get(
    model::Optimizer,
    attr::MOI.ConstraintDual,
    ci::MOI.ConstraintIndex{MOI.VectorOfVariables,S},
) where {S<:SupportedSets}
    MOI.check_result_index_bounds(model, attr)
    blk = model.varmap[ci.value][1]
    return _vectorize_block(model.Z, blk, S)
end
