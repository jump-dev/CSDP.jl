import MathProgBase
const MPB = MathProgBase.SolverInterface
import SemidefiniteModels
const SDM = SemidefiniteModels

export CSDPMathProgModel, CSDPSolver

function checkoptions(d::Dict{Symbol, Any})
    for key in keys(d)
        if !(key in ALLOWED_OPTIONS)
            error("Option $key is not not a valid CSDP option. The valid options are $ALLOWED_OPTIONS.")
        end
    end
    return d
end

struct CSDPSolver <: MPB.AbstractMathProgSolver
    options::Dict{Symbol,Any}
end
CSDPSolver(; kwargs...) = CSDPSolver(checkoptions(Dict{Symbol,Any}(kwargs)))

mutable struct CSDPMathProgModel <: SDM.AbstractSDModel
    blockdims::Vector{Cint}
    b::Vector{Cdouble}
    entries::Vector{Tuple{Cint,Cint,Cint,Cint,Cdouble}}
    C::blockmatrix
    problem::Union{Nothing, LoadingProblem}
    X::blockmatrix
    y::Union{Nothing, Vector{Cdouble}}
    Z::blockmatrix
    status::Cint
    pobj::Cdouble
    dobj::Cdouble
    options::Dict{Symbol,Any}
    function CSDPMathProgModel(; kwargs...)
        new(Cint[], Cdouble[], Tuple{Cint,Cint,Cint,Cint,Cdouble}[],
            blockmatrix(), nothing, blockmatrix(), nothing, blockmatrix(),
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
    if m.problem !== nothing
        if m.y !== nothing
            free_loaded_prob(m.problem, m.X, m.y, m.Z)
        end
        free_loading_prob(m.problem)
    end
    m.problem = nothing
    m.y = nothing
    if endswith(filename,".dat-s")
        m.problem = load_prob_from_file(filename, Ref(m.C))
    else
        error("unrecognized input format extension in $filename")
    end
end
#writeproblem(m, filename::String)
function MPB.loadproblem!(m::CSDPMathProgModel, blkdims::Vector{Int}, constr::Int)
    if m.problem !== nothing
        if m.y !== nothing
            free_loaded_prob(m.problem, m.X, m.y, m.Z)
        end
        free_loading_prob(m.problem)
    end
    m.problem = nothing
    m.y = nothing
    m.blockdims = blkdims
    m.b = zeros(Cdouble, constr)
    empty!(m.entries)
end

function SDM.setconstrB!(m::CSDPMathProgModel, val, constr::Integer)
    m.b[constr] = val
end
function SDM.setconstrentry!(m::CSDPMathProgModel, coef, constr::Integer, blk::Integer, i::Integer, j::Integer)
    push!(m.entries, (constr, blk, i, j, coef))
end
function SDM.setobjentry!(m::CSDPMathProgModel, coef, blk::Integer, i::Integer, j::Integer)
    push!(m.entries, (0, blk, i, j, coef))
end

function MPB.optimize!(m::CSDPMathProgModel)
    if m.problem === nothing
        # `m.problem` is not `nothing` if it was loaded from a file.
        m.C.nblocks = length(m.blockdims)
        num_entries = zeros(Cint, length(m.b), length(m.blockdims))
        for entry in m.entries
            if entry[1] > 0
                num_entries[entry[1], entry[2]] += 1
            end
        end
        m.problem = allocate_loading_prob(Ref(m.C), m.blockdims, length(m.b), num_entries, 3)
        for (i, x) in enumerate(m.b)
            setconstant(m.problem, i, x)
        end
        for entry in m.entries
            duplicate = addentry(m.problem, entry..., true)
            @assert !duplicate
        end
    end
    m.y = loaded_initsoln(m.problem, length(m.b), Ref(m.X), Ref(m.Z))
    m.status, m.pobj, m.dobj = loaded_sdp(m.problem, Ref(m.X), m.y, Ref(m.Z), m.options)
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
