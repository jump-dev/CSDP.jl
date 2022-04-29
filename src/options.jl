# Copyright (c) 2016: CSDP.jl contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

const ALLOWED_OPTIONS = [
    :printlevel,
    :axtol,
    :atytol,
    :objtol,
    :pinftol,
    :dinftol,
    :maxiter,
    :minstepfrac,
    :maxstepfrac,
    :minstepp,
    :minstepd,
    :usexzgap,
    :tweakgap,
    :affine,
    :perturbobj,
    :fastmode,
    :write_prob,
]

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
            @info "Writing problem to $(pwd())/$(wrtf)"
            write_prob(wrtf, m.C, m.b, map(A -> A.csdp, m.As))
        end
    end
end

options(params::Dict{Symbol}) = get(params, :printlevel, 1), paramstruc(params)
