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
    options::Dict{Symbol,Any}
    function SDOptimizer(; kwargs...)
        new(nothing, nothing, nothing, nothing, nothing, nothing,
            -1, 0.0, 0.0, checkoptions(Dict{Symbol, Any}(kwargs)))
    end
end
Optimizer(; kws...) = SDOI.SDOIOptimizer(SDOptimizer(; kws...))

MOI.get(::SDOptimizer, ::MOI.SolverName) = "CSDP"

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

function MOI.optimize!(m::SDOptimizer)
    As = map(A->A.csdp, m.As)

    write_prob(m)

    m.X, m.y, m.Z = initsoln(m.C, m.b, As)
    #verbose = get(m.options, :verbose, true)
    #m.status, m.pobj, m.dobj = easy_sdp(m.C, m.b, As, m.X, m.y, m.Z, verbose)
    m.status, m.pobj, m.dobj = sdp(m.C, m.b, m.As, m.X, m.y, m.Z, m.options)
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

function SDOI.getprimalobjectivevalue(m::SDOptimizer)
    m.pobj
end
function SDOI.getdualobjectivevalue(m::SDOptimizer)
    m.dobj
end
function SDOI.getX(m::SDOptimizer)
    m.X
end
function SDOI.gety(m::SDOptimizer)
    m.y
end
function SDOI.getZ(m::SDOptimizer)
    m.Z
end
