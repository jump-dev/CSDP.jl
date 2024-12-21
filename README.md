![](https://www.coin-or.org/wordpress/wp-content/uploads/2014/08/COINOR.png)
# CSDP.jl


[![Build Status](https://github.com/jump-dev/CSDP.jl/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/jump-dev/CSDP.jl/actions?query=workflow%3ACI)
[![codecov](https://codecov.io/gh/jump-dev/CSDP.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/jump-dev/CSDP.jl)

[`CSDP.jl`](https://github.com/jump-dev/CSDP.jl) is a wrapper for the
[COIN-OR SemiDefinite Programming](https://projects.coin-or.org/Csdp) solver.

The wrapper has two components:
 * a thin wrapper around the low-level C API
 * an interface to [MathOptInterface](https://github.com/jump-dev/MathOptInterface.jl)

## Affiliation

This wrapper is maintained by the JuMP community and is not a COIN-OR project.

The original algorithm is described by B. Borchers (1999). _CSDP, A C Library
for Semidefinite Programming_. Optimization Methods and Software. 11(1), 613-623.
[[preprint]](http://euler.nmt.edu/~brian/csdppaper.pdf)

## License

`CSDP.jl` is licensed under the [MIT License](https://github.com/jump-dev/CSDP.jl/blob/master/LICENSE.md).

The underlying solver, [coin-or/Csdp](https://github.com/coin-or/Csdp), is
licensed under the [Eclipse public license](https://github.com/coin-or/Csdp/blob/master/LICENSE).

## Installation

Install CSDP using `Pkg.add`:
```julia
import Pkg
Pkg.add("CSDP")
```

In addition to installing the CSDP.jl package, this will also download and
install the CSDP binaries. You do not need to install CSDP separately.

## Use with JuMP

To use CSDP with JuMP, use `CSDP.Optimizer`:
```julia
using JuMP, CSDP
model = Model(CSDP.Optimizer)
set_attribute(model, "maxiter", 1000)
```

## MathOptInterface API

The CSDP optimizer supports the following constraints and attributes.

List of supported objective functions:

 * [`MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}`](@ref)

List of supported variable types:

 * [`MOI.Nonnegatives`](@ref)
 * [`MOI.PositiveSemidefiniteConeTriangle`](@ref)

List of supported constraint types:

 * [`MOI.ScalarAffineFunction{Float64}`](@ref) in [`MOI.EqualTo{Float64}`](@ref)

List of supported model attributes:

 * [`MOI.ObjectiveSense()`](@ref)

## Options

The CSDP options are listed in the table below.

| Name          | Default Value  | Explanation                                                                                                          |
| ------------- | -------------- | -------------------------------------------------------------------------------------------------------------------- |
| `axtol`       | `1.0e-8`       | Tolerance for primal feasibility                                                                                     |
| `atytol`      | `1.0e-8`       | Tolerance for dual feasibility                                                                                       |
| `objtol`      | `1.0e-8`       | Tolerance for relative duality gap                                                                                   |
| `pinftol`     | `1.0e8`        | Tolerance for determining primal infeasibility                                                                       |
| `dinftol`     | `1.0e8`        | Tolerance for determining dual infeasibility                                                                         |
| `maxiter`     | `100`          | Limit for the total number of iterations                                                                             |
| `minstepfrac` | `0.90`         | The `minstepfrac` and `maxstepfrac` parameters determine how close to the edge of the feasible region CSDP will step |
| `maxstepfrac` | `0.97`         | The `minstepfrac` and `maxstepfrac` parameters determine how close to the edge of the feasible region CSDP will step |
| `minstepp`    | `1.0e-8`       | If the primal step is shorter than `minstepp` then CSDP declares a line search failure                               |
| `minstepd`    | `1.0e-8`       | If the dual step is shorter than `minstepd` then CSDP declares a line search failure                                 |
| `usexzgap`    | `1`            | If `usexzgap` is `0` then CSDP will use the objective duality gap `d - p` instead of the XY duality gap `⟨Z, X⟩`     |
| `tweakgap`    | `0`            | If `tweakgap` is set to `1`, and `usexzgap` is set to `0`, then CSDP will attempt to "fix" negative duality gaps     |
| `affine`      | `0`            | If `affine` is set to `1`, then CSDP will take only primal-dual affine steps and not make use of the barrier term. This can be useful for some problems that do not have feasible solutions that are strictly in the interior of the cone of semidefinite matrices |
| `perturbobj`  | `1`            | The `perturbobj` parameter determines whether the objective function will be perturbed to help deal with problems that have unbounded optimal solution sets. If `perturbobj` is `0`, then the objective will not be perturbed. If `perturbobj` is `1`, then the objective function will be perturbed by a default amount. Larger values of `perturbobj` (for example, `100`) increase the size of the perturbation. This can be helpful in solving some difficult problems. |
| `fastmode`    | `0`            | The `fastmode` parameter determines whether or not CSDP will skip certain time consuming operations that slightly improve the accuracy of the solutions. If `fastmode` is set to `1`, then CSDP may be somewhat faster, but also somewhat less accurate |
| `printlevel`  | `1`            | The `printlevel` parameter determines how much debugging information is output. Use a `printlevel` of `0` for no output and a `printlevel` of `1` for normal output. Higher values of `printlevel` will generate more debugging output |

## Problem representation

The primal is represented internally by CSDP as follows:
```
max ⟨C, X⟩
      A(X) = a
         X ⪰ 0
```
where `A(X) = [⟨A_1, X⟩, ..., ⟨A_m, X⟩]`. The corresponding dual is:
```
min ⟨a, y⟩
     A'(y) - C = Z
             Z ⪰ 0
```
where `A'(y) = y_1A_1 + ... + y_mA_m`

## Termination criteria

CSDP will terminate successfully (or partially) in the following cases:

* If CSDP finds `X, Z ⪰ 0` such that the following 3 tolerances are satisfied:
  * primal feasibility tolerance: `||A(x) - a||_2 / (1 + ||a||_2) < axtol`
  * dual feasibility tolerance: `||A'(y) - C - Z||_F / (1 + ||C||_F) < atytol`
  * relative duality gap tolerance: `gap / (1 + |⟨a, y⟩| + |⟨C, X⟩|) < objtol`
    * objective duality gap: if `usexygap` is `0`, `gap = ⟨a, y⟩ - ⟨C, X⟩`
    * XY duality gap: if `usexygap` is `1`, `gap = ⟨Z, X⟩`
  then it returns `0`.
* If CSDP finds `y` and `Z ⪰ 0` such that `-⟨a, y⟩ / ||A'(y) - Z||_F > pinftol`,
  it returns `1` with `y` such that `⟨a, y⟩ = -1`.
* If CSDP finds `X ⪰ 0` such that `⟨C, X⟩ / ||A(X)||_2 > dinftol`, it returns
  `2` with `X` such that `⟨C, X⟩ = 1`.
* If CSDP finds `X, Z ⪰ 0` such that the following 3 tolerances are satisfied
  with `1000*axtol`, `1000*atytol` and `1000*objtol` but at least one of them is
  not satisfied with `axtol`, `atytol` and `objtol` and cannot make progress,
  then it returns `3`.

In addition, if the `printlevel` option is at least `1`, the following will be
printed:

* If the return code is `1`, CSDP will print `⟨a, y⟩` and `||A'(y) - Z||_F`
* If the return code is `2`, CSDP will print `⟨C, X⟩` and `||A(X)||_F`
* Otherwise, CSDP will print
  * the primal/dual objective value,
  * the relative primal/dual infeasibility,
  * the objective duality gap `⟨a, y⟩ - ⟨C, X⟩` and objective relative duality
    gap `(⟨a, y⟩ - ⟨C, X⟩) / (1 + |⟨a, y⟩| + |⟨C, X⟩|)`,
  * the XY duality gap `⟨Z, X⟩` and XY relative duality gap
    `⟨Z, X⟩ / (1 + |⟨a, y⟩| + |⟨C, X⟩|)`
  * and the DIMACS error measures.

In theory, for feasible primal and dual solutions, `⟨a, y⟩ - ⟨C, X⟩ = ⟨Z, X⟩`,
so the objective and XY duality gap should be equivalent. However, in practice,
there are sometimes solution which satisfy primal and dual feasibility
tolerances but have objective duality gap which are not close to XY duality gap.
In some cases, the objective duality gap may even become negative (hence the
`tweakgap` option). This is the reason `usexygap` is `1` by default.

CSDP considers that `X ⪰ 0` (resp. `Z ⪰ 0`) is satisfied when the Cholesky
factorizations can be computed. In practice, this is somewhat more conservative
than simply requiring all eigenvalues to be nonnegative.

## Status

The table below shows how the different CSDP statuses are converted to the
MathOptInterface statuses.

| CSDP code | State           | Description                                                   | MOI status            |
| --------- | --------------- | ------------------------------------------------------------- | --------------------- |
| `0`       | Success         | SDP solved                                                    | `MOI.OPTIMAL`         |
| `1`       | Success         | The problem is primal infeasible, and we have a certificate   | `MOI.INFEASIBLE`      |
| `2`       | Success         | The problem is dual infeasible, and we have a certificate     | `MOI.DUAL_INFEASIBLE` |
| `3`       | Partial Success | A solution has been found, but full accuracy was not achieved | `MOI.ALMOST_OPTIMAL`  |
| `4`       | Failure         | Maximum iterations reached                                    | `MOI.ITERATION_LIMIT` |
| `5`       | Failure         | Stuck at edge of primal feasibility                           | `MOI.SLOW_PROGRESS`   |
| `6`       | Failure         | Stuck at edge of dual infeasibility                           | `MOI.SLOW_PROGRESS`   |
| `7`       | Failure         | Lack of progress                                              | `MOI.SLOW_PROGRESS`   |
| `8`       | Failure         | `X`, `Z`, or `O` was singular                                 | `MOI.NUMERICAL_ERROR` |
| `9`       | Failure         | Detected `NaN` or `Inf` values                                | `MOI.NUMERICAL_ERROR` |
