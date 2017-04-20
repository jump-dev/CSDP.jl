importall MathProgBase.SolverInterface
importall SemidefiniteModels

export CSDPMathProgModel, CSDPSolver

immutable CSDPSolver <: AbstractMathProgSolver
    options::Dict{Symbol,Any}
end
CSDPSolver(;kwargs...) = CSDPSolver(Dict{Symbol,Any}(kwargs))

type CSDPMathProgModel <: AbstractSDModel
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
            -1, 0.0, 0.0, Dict{Symbol, Any}(kwargs))
    end
end
SDModel(s::CSDPSolver) = CSDPMathProgModel(; s.options...)
ConicModel(s::CSDPSolver) = SDtoConicBridge(SDModel(s))
LinearQuadraticModel(s::CSDPSolver) = ConicToLPQPBridge(ConicModel(s))

supportedcones(s::CSDPSolver) = [:Free,:Zero,:NonNeg,:NonPos,:SOC,:RSOC,:SDP]
function setvartype!(m::CSDPMathProgModel, vtype, blk, i, j)
    if vtype != :Cont
        error("Unsupported variable type $vtype by CSDP")
    end
end

function loadproblem!(m::CSDPMathProgModel, filename::AbstractString)
    if endswith(filename,".dat-s")
       m.C, m.b, As = read_prob(filename)
       m.As = [ConstraintMatrix(As[i], i) for i in 1:length(As)]
    else
       error("unrecognized input format extension in $filename")
    end
end
#writeproblem(m, filename::String)
function loadproblem!(m::CSDPMathProgModel, blkdims::Vector{Int}, constr::Int)
    m.C = blockmatzeros(blkdims)
    m.b = zeros(Cdouble, constr)
    m.As = [constrmatzeros(i, blkdims) for i in 1:constr]
end

function setconstrB!(m::CSDPMathProgModel, val, constr::Integer)
    m.b[constr] = val
end
function setconstrentry!(m::CSDPMathProgModel, coef, constr::Integer, blk::Integer, i::Integer, j::Integer)
    m.As[constr][blk][i,j] = coef
end
function setobjentry!(m::CSDPMathProgModel, coef, blk::Integer, i::Integer, j::Integer)
    m.C[blk][i,j] = coef
end

function optimize!(m::CSDPMathProgModel)
    As = map(A->A.csdp, m.As)

    let wrt = string(get(m.options, :write_prob, ""))
        if length(wrt) > 0
            k = 1
            wrtf = "$wrt.$k"
            while isfile(wrtf)
                wrtf = "$wrt.$k"
                k += 1
            end
            info("Writing problem to $(pwd())/$(wrtf)")
            write_prob(wrtf, m.C, m.b, As)
        end
    end

    verbose = get(m.options, :verbose, true)

    m.X, m.y, m.Z = initsoln(m.C, m.b, As)
    m.status, m.pobj, m.dobj = easy_sdp(m.C, m.b, As, m.X, m.y, m.Z, verbose)
end

function status(m::CSDPMathProgModel)
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

function getobjval(m::CSDPMathProgModel)
    m.pobj
end
function getsolution(m::CSDPMathProgModel)
    m.X
end
function getdual(m::CSDPMathProgModel)
    m.y
end
function getvardual(m::CSDPMathProgModel)
    m.Z
end
