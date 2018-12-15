import MathProgBase
const MPB = MathProgBase.SolverInterface
import SemidefiniteModels
const SDM = SemidefiniteModels

export CSDPMathProgModel, CSDPSolver

struct CSDPSolver <: MPB.AbstractMathProgSolver
    options::Dict{Symbol,Any}
end
CSDPSolver(; kwargs...) = CSDPSolver(checkoptions(Dict{Symbol,Any}(kwargs)))

mutable struct CSDPMathProgModel <: SDM.AbstractSDModel
    C
    b
    As
    X
    y
    Z
    status::Cint
    pobj::Cdouble
    dobj::Cdouble
    options::Dict{Symbol,Any}
    function CSDPMathProgModel(; kwargs...)
        new(nothing, nothing, nothing, nothing, nothing, nothing,
            -1, 0.0, 0.0, checkoptions(Dict{Symbol, Any}(kwargs)))
    end
end
SDM.SDModel(s::CSDPSolver) = CSDPMathProgModel(; s.options...)
MPB.ConicModel(s::CSDPSolver) = SDM.SDtoConicBridge(SDM.SDModel(s))
MPB.LinearQuadraticModel(s::CSDPSolver) = MPB.ConicToLPQPBridge(MPB.ConicModel(s))

MPB.supportedcones(s::CSDPSolver) = [:Free,:Zero,:NonNeg,:NonPos,:SOC,:RSOC,:SDP]
function MPB.setvartype!(m::CSDPMathProgModel, vtype, blk, i, j)
    if vtype != :Cont
        error("Unsupported variable type $vtype by CSDP")
    end
end

function MPB.loadproblem!(m::CSDPMathProgModel, filename::AbstractString)
    if endswith(filename,".dat-s")
       m.C, m.b, As = read_prob(filename)
       m.As = [ConstraintMatrix(As[i], i) for i in 1:length(As)]
    else
       error("unrecognized input format extension in $filename")
    end
end
#writeproblem(m, filename::String)
function MPB.loadproblem!(m::CSDPMathProgModel, blkdims::Vector{Int}, constr::Int)
    m.C = blockmatzeros(blkdims)
    m.b = zeros(Cdouble, constr)
    m.As = [constrmatzeros(i, blkdims) for i in 1:constr]
end

function SDM.setconstrB!(m::CSDPMathProgModel, val, constr::Integer)
    m.b[constr] = val
end
function SDM.setconstrentry!(m::CSDPMathProgModel, coef, constr::Integer, blk::Integer, i::Integer, j::Integer)
    SDOI.block(m.As[constr], blk)[i, j] = coef
end
function SDM.setobjentry!(m::CSDPMathProgModel, coef, blk::Integer, i::Integer, j::Integer)
    SDOI.block(m.C, blk)[i, j] = coef
end

function MPB.optimize!(m::CSDPMathProgModel)
    As = map(A->A.csdp, m.As)

    write_prob(m)

    m.X, m.y, m.Z = initsoln(m.C, m.b, As)
    #verbose = get(m.options, :verbose, true)
    #m.status, m.pobj, m.dobj = easy_sdp(m.C, m.b, As, m.X, m.y, m.Z, verbose)
    m.status, m.pobj, m.dobj = sdp(m.C, m.b, m.As, m.X, m.y, m.Z, m.options)
end

function MPB.status(m::CSDPMathProgModel)
    status = m.status
    if status == 0
        return :Optimal
    elseif status == 1
        return :Infeasible
    elseif status == 2
        return :Unbounded
    elseif status == 3
        return :Suboptimal
    elseif status == 4
        return :UserLimit
    elseif 5 <= status <= 9
        return :Error
    elseif status == -1
        return :Uninitialized
    else
        error("Internal library error: status=$status")
    end
end

function MPB.getobjval(m::CSDPMathProgModel)
    m.pobj
end
function MPB.getsolution(m::CSDPMathProgModel)
    m.X
end
function MPB.getdual(m::CSDPMathProgModel)
    m.y
end
function MPB.getvardual(m::CSDPMathProgModel)
    m.Z
end
