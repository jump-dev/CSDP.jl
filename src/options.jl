const allowed_options = [:printlevel, :axtol, :atytol, :objtol, :pinftol, :dinftol, :maxiter, :minstepfrac, :maxstepfrac, :minstepp, :minstepd, :usexzgap, :tweakgap, :affine, :perturbobj, :fastmode, :write_prob]

# The :write_prob option is for the following function
function write_prob(m)
    let wrt = string(get(m.options, :write_prob, ""))
        if length(wrt) > 0
            k = 1
            wrtf = "$wrt.$k"
            while isfile(wrtf)
                wrtf = "$wrt.$k"
                k += 1
            end
            info("Writing problem to $(pwd())/$(wrtf)")
            write_prob(wrtf, m.C, m.b, map(A->A.csdp, m.As))
        end
    end
end

function checkoptions(d::Dict{Symbol, Any})
    for key in keys(d)
        if !(key in allowed_options)
            error("Option $key is not not a valid CSDP option. The valid options are $allowed_options.")
        end
    end
    d
end

options(params::Dict{Symbol}) = get(params, :printlevel, 1), paramstruc(params)
