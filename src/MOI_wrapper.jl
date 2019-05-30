using SemidefiniteOptInterface
SDOI = SemidefiniteOptInterface

using MathOptInterface
MOI = MathOptInterface

mutable struct SDOptimizer <: SDOI.AbstractSDOptimizer
    C::Union{Nothing, BlockMatrix}
    b::Union{Nothing, Vector{Cdouble}}
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
    function SDOptimizer(; kwargs...)
        optimizer = new(nothing, nothing, nothing, nothing, nothing, nothing,
            -1, NaN, NaN, NaN, false, Dict{Symbol, Any}())
        for (key, value) in kwargs
            MOI.set(optimizer, MOI.RawParameter(key), value)
        end
        return optimizer
    end
end
Optimizer(; kws...) = SDOI.SDOIOptimizer(SDOptimizer(; kws...))

function MOI.supports(optimizer::SDOptimizer, param::MOI.RawParameter)
    return param.name in ALLOWED_OPTIONS
end
function MOI.set(optimizer::SDOptimizer, param::MOI.RawParameter, value)
    if !MOI.supports(optimizer, param)
        throw(MOI.UnsupportedAttribute(param))
    end
    optimizer.options[param.name] = value
end
function MOI.get(optimizer::SDOptimizer, param::MOI.RawParameter)
    # TODO: This gives a poor error message if the name of the parameter is invalid.
    return optimizer.options[param.name]
end

MOI.supports(::SDOptimizer, ::MOI.Silent) = true
function MOI.set(optimizer::SDOptimizer, ::MOI.Silent, value::Bool)
    optimizer.silent = value
end
MOI.get(optimizer::SDOptimizer, ::MOI.Silent) = optimizer.silent

MOI.get(::SDOptimizer, ::MOI.SolverName) = "CSDP"
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

function MOI.get(optimizer::SDOptimizer, ::MOI.RawStatusString)
    return RAW_STATUS[optimizer.status + 1]
end
function MOI.get(optimizer::SDOptimizer, ::MOI.SolveTime)
    return optimizer.solve_time
end

function MOI.empty!(optimizer::SDOptimizer)
    optimizer.C = nothing
    optimizer.b = nothing
    optimizer.As = nothing
    optimizer.X = nothing
    optimizer.y = nothing
    optimizer.Z = nothing
    optimizer.status = -1
    optimizer.pobj = 0.0
    optimizer.dobj = 0.0
end

function SDOI.init!(m::SDOptimizer, blkdims::Vector{Int}, nconstrs::Int)
    @assert nconstrs >= 0
    dummy = nconstrs == 0
    if dummy
        # See https://github.com/coin-or/Csdp/issues/2
        nconstrs = 1
        blkdims = [blkdims; -1]
    end
    m.C = blockmatzeros(blkdims)
    m.b = zeros(Cdouble, nconstrs)
    m.As = [constrmatzeros(i, blkdims) for i in 1:nconstrs]
    if dummy
        # See https://github.com/coin-or/Csdp/issues/2
        m.b[1] = 1
        SDOI.block(m.As[1], length(blkdims))[1,1] = 1
    end
end

function SDOI.setconstraintconstant!(m::SDOptimizer, val, constr::Integer)
    #println("b[$constr] = $val")
    m.b[constr] = val
end
function SDOI.setconstraintcoefficient!(m::SDOptimizer, coef, constr::Integer, blk::Integer, i::Integer, j::Integer)
    #println("A[$constr][$blk][$i, $j] = $coef")
    SDOI.block(m.As[constr], blk)[i, j] = coef
end
function SDOI.setobjectivecoefficient!(m::SDOptimizer, coef, blk::Integer, i::Integer, j::Integer)
    #println("C[$blk][$i, $j] = $coef")
    SDOI.block(m.C, blk)[i, j] = coef
end

function MOI.optimize!(optimizer::SDOptimizer)
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

function MOI.get(m::SDOptimizer, ::MOI.TerminationStatus)
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

function MOI.get(m::SDOptimizer, ::MOI.PrimalStatus)
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

function MOI.get(m::SDOptimizer, ::MOI.DualStatus)
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

function MOI.get(m::SDOptimizer, ::MOI.ObjectiveValue)
    return m.pobj
end
function MOI.get(m::SDOptimizer, ::MOI.DualObjectiveValue)
    return m.dobj
end
function SDOI.getX(m::SDOptimizer)
    return m.X
end
function SDOI.gety(m::SDOptimizer)
    return m.y
end
function SDOI.getZ(m::SDOptimizer)
    return m.Z
end
