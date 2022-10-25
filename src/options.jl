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
]

options(params::Dict{Symbol}) = get(params, :printlevel, 1), paramstruc(params)
