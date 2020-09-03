# COIN-OR SemiDefinite Programming Interface (CSDP.jl)

![](https://www.coin-or.org/wordpress/wp-content/uploads/2014/08/COINOR.png)

`CSDP.jl` is an interface to the **[COIN-OR SemiDefinite
Programming](https://projects.coin-or.org/Csdp)** solver. It provides a complete
interface to the low-level C API, as well as an implementation of the
solver-independent `MathProgBase` and `MathOptInterface` API's.

*Note: This wrapper is maintained by the JuMP community and is not a COIN-OR
project.*

| **Build Status** |
|:----------------:|
| [![Build Status][build-img]][build-url] [![Build Status][winbuild-img]][winbuild-url] |
| [![Codecov branch][codecov-img]][codecov-url] |

The original algorithm is described by
B. Borchers.
*CSDP, A C Library for Semidefinite Programming*.
Optimization Methods and Software 11(1):613-623, 1999.
DOI [10.1080/10556789908805765](http://dx.doi.org/10.1080/10556789908805765).
[Preprint](http://euler.nmt.edu/~brian/csdppaper.pdf).

## Installing CSDP

You can either use the system LAPACK and BLAS libaries or the libraries shipped with Julia.
First, make sure that you have a compiler available, e.g. on Ubuntu do
```
$ sudo apt-get install build-essential
```
To use the libraries shipped by Julia, simply do
```julia
$ CSDP_USE_JULIA_LAPACK=true julia -e 'import Pkg; Pkg.add("CSDP"); Pkg.build("CSDP")'
```
To use the system libaries, first make sure it is installed, e.g. on Ubuntu do
```julia
$ sudo apt-get install liblapack-dev libopenblas-dev
```
and then do
```julia
$ CSDP_USE_JULIA_LAPACK=false julia -e 'import Pkg; Pkg.add("CSDP"); Pkg.build("CSDP")'
```

Note that if the environment variable `CSDP_USE_JULIA_LAPACK` is not set, it defaults
to using the system libraries if available and the Julia libraries otherwise.

To use CSDP with JuMP v0.19 and later, do
```julia
using JuMP, CSDP
model = Model(with_optimizer(CSDP.Optimizer))
```
and with JuMP v0.18 and earlier, do
```julia
using JuMP, CSDP
model = Model(solver=CSDPSolver())
```

## CSDP problem representation

The primal is represented internally by CSDP as follows:
```
max ⟨C, X⟩
      A(X) = a
         X ⪰ 0
```
where `A(X) = [⟨A_1, X⟩, ..., ⟨A_m, X⟩]`.
The corresponding dual is:
```
min ⟨a, y⟩
     A'(y) - C = Z
             Z ⪰ 0
```
where `A'(y) = y_1A_1 + ... + y_mA_m`

## Termination criteria

CSDP will terminate successfully (or partially) in the following cases:

* If CSDP finds `y` and `Z ⪰ 0` such that `-⟨a, y⟩ / ||A'(y) - Z||_F > pinftol`, it returns `1` with `y` such that `⟨a, y⟩ = -1`.
* If CSDP finds `X ⪰ 0` such that `⟨C, X⟩ / ||A(X)||_2 > dinftol`, it returns `2` with `X` such that `⟨C, X⟩ = 1`.
* If CSDP finds `X, Z ⪰ 0` such that the following 3 tolerances are satisfied:
  * primal feasibility tolerance: `||A(x) - a||_2 / (1 + ||a||_2) < axtol`
  * dual feasibility tolerance: `||A'(y) - C - Z||_F / (1 + ||C||_F) < atytol`
  * relative duality gap tolerance: `gap / (1 + |⟨a, y⟩| + |⟨C, X⟩|) < objtol`
    * objective duality gap: If `usexygap` is `0`, `gap = ⟨a, y⟩ - ⟨C, X⟩`
    * XY duality gap: If `usexygap` is `1`, `gap = ⟨Z, X⟩`
  then it returns `0`.
* If CSDP finds `X, Z ⪰ 0` such that the following 3 tolerances are satisfied with `1000*axtol`, `1000*atytol` and `1000*objtol` but at least one of them is not satisfied with `axtol`, `atytol` and `objtol` and cannot make progress then it returns `3`.

**Remark:** In theory, for feasible primal and dual solutions, `⟨a, y⟩ - ⟨C, X⟩ = ⟨Z, X⟩` so the objective and XY duality gap should be equivalent. However, in practice, there are sometimes solution which satisfy primal and dual feasibility tolerances but have objective duality gap which are not close to XY duality gap. In some cases, the objective duality gap may even become negative (hence the `tweakgap` option). This is the reason `usexygap` is `1` by default.

**Remark:** CSDP considers that `X ⪰ 0` (resp. `Z ⪰ 0`) is satisfied when the Cholesky factorizations can be computed.
In practice, this is somewhat more conservative than simply requiring all eigenvalues to be nonnegative.

## Status

The table below shows how the different CSDP status are converted to [MathProgBase](https://github.com/JuliaOpt/MathProgBase.jl) status.

CSDP code | State           | Description                                                   | MathProgBase status |
--------- | --------------- | ------------------------------------------------------------- | ------------------- |
`0`       | Success         | SDP solved                                                    | Optimal             |
`1`       | Success         | The problem is primal infeasible, and we have a certificate   | Infeasible          |
`2`       | Success         | The problem is dual infeasible, and we have a certificate     | Unbounded           |
`3`       | Partial Success | A solution has been found, but full accuracy was not achieved | Suboptimal          |
`4`       | Failure         | Maximum iterations reached                                    | UserLimit           |
`5`       | Failure         | Stuck at edge of primal feasibility                           | Error               |
`6`       | Failure         | Stuck at edge of dual infeasibility                           | Error               |
`7`       | Failure         | Lack of progress                                              | Error               |
`8`       | Failure         | `X`, `Z`, or `O` was singular                                 | Error               |
`9`       | Failure         | Detected `NaN` or `Inf` values                                | Error               |

If the `printlevel` option is at least `1`, the following will be printed:

* If the return code is `1`, CSDP will print `⟨a, y⟩` and `||A'(y) - Z||_F`
* if the return code is `2`, CSDP will print `⟨C, X⟩` and `||A(X)||_F`
* otherwise, CSDP will print
  * the primal/dual objective value,
  * the relative primal/dual infeasibility,
  * the objective duality gap `⟨a, y⟩ - ⟨C, X⟩` and objective relative duality  gap `(⟨a, y⟩ - ⟨C, X⟩) / (1 + |⟨a, y⟩| + |⟨C, X⟩|)`,
  * the XY duality gap `⟨Z, X⟩` and XY relative duality gap `⟨Z, X⟩ / (1 + |⟨a, y⟩| + |⟨C, X⟩|)`
  * and the DIMACS error measures.

## Options

The CSDP options are listed in the table below. Their value can be specified in the constructor of the CSDP solver, e.g. `CSDPSolver(axtol=1e-7, printlevel=0)`.

Name          |                                                                                                                      | Default Value  |
 ------------ | -----------------------------------                                                                                  | -------------- |
`axtol`       | Tolerance for primal feasibility                                                                                     | `1.0e-8`       |
`atytol`      | Tolerance for dual feasibility                                                                                       | `1.0e-8`       |
`objtol`      | Tolerance for relative duality gap                                                                                   | `1.0e-8`       |
`pinftol`     | Tolerance for determining primal infeasibility                                                                       | `1.0e8`        |
`dinftol`     | Tolerance for determining dual infeasibility                                                                         | `1.0e8`        |
`maxiter`     | Limit for the total number of iterations                                                                             | `100`          |
`minstepfrac` | The `minstepfrac` and `maxstepfrac` parameters determine how close to the edge of the feasible region CSDP will step | `0.90`         |
`maxstepfrac` | The `minstepfrac` and `maxstepfrac` parameters determine how close to the edge of the feasible region CSDP will step | `0.97`         |
`minstepp`    | If the primal step is shorter than `minstepp` then CSDP declares a line search failure                               | `1.0e-8`       |
`minstepd`    | If the dual step is shorter than `minstepd` then CSDP declares a line search failure                                 | `1.0e-8`       |
`usexzgap`    | If `usexzgap` is `0` then CSDP will use the objective duality gap `d - p` instead of the XY duality gap `⟨Z, X⟩`     | `1`            |
`tweakgap`    | If `tweakgap` is set to `1`, and `usexzgap` is set to `0`, then CSDP will attempt to "fix" negative duality gaps     | `0`            |
`affine`      | If `affine` is set to `1`, then CSDP will take only primal-dual affine steps and not make use of the barrier term. This can be useful for some problems that do not have feasible solutions that are strictly in the interior of the cone of semidefinite matrices | `0`            |
`perturbobj`  | The `perturbobj` parameter determines whether the objective function will be perturbed to help deal with problems that have unbounded optimal solution sets. If `perturbobj` is `0`, then the objective will not be perturbed. If `perturbobj` is `1`, then the objective function will be perturbed by a default amount. Larger values of `perturbobj` (e.g. `100`) increase the size of the perturbation. This can be helpful in solving some difficult problems. | `1`            |
`fastmode`    | The `fastmode` parameter determines whether or not CSDP will skip certain time consuming operations that slightly improve the accuracy of the solutions. If `fastmode` is set to `1`, then CSDP may be somewhat faster, but also somewhat less accurate | `0`            |
`printlevel`  | The `printlevel` parameter determines how much debugging information is output. Use a `printlevel` of `0` for no output and a `printlevel` of `1` for normal output. Higher values of printlevel will generate more debugging output | `1`            |

## Getting the CSDP Library
The original make-file build system only provides a static library.
The quite old (September 2010) [`pycsdp`](https://github.com/BenjaminKern/pycsdp) interface by [Benjamin Kern](http://ifatwww.et.uni-magdeburg.de/syst/about_us/people/kern/index.shtml) circumvents the problem by writing some C++ [code](https://github.com/BenjaminKern/pycsdp/tree/master/CXX) to which the static library is linked.
The Sage [module](https://github.com/mghasemi/pycsdp) by @mghasemi is a Cython interface; I don't know how the libcsdp is installed or whether they assume that it is already available on the system.

That is why this package tries to parse the makefile and compiles it itself on Unix systems (so `gcc` is needed).
<!-- ~~Furthermore `libblas` and `liblapack` are needed to be installed.~~ -->
For Windows, a pre-compiled DLL is downloaded (unless you configure the `build.jl` differently).

<!-- On Windows you need the MinGW `gcc` compiler available in the `PATH`.
    Currently, only the Win32 builds work. -->


## Next Steps (TODOs)

- [ ] Maybe port `libcsdp` to use 64bit Lapack, aka replace “some `int`s” by `long int` (the variables used in a Lapack call).  Started in brach `julias_openblas64`
- [ ] Maybe think about an own array type to circumvent the 1-index problems in `libcsdp`.
- [ ] Map Julia's sparse arrays to `sparsematrixblock`.
- [ ] Upload `libcsdp.dll` for Windows via Appveyor deployment as described at
      [JuliaCon](https://www.youtube.com/watch?v=XKdKdfHB2KM&index=12&list=PLP8iPy9hna6SQPwZUDtAM59-wPzCPyD_S).
      Currently we use a [separate repository](https://github.com/EQt/winlapack).

[build-img]: https://travis-ci.org/jump-dev/CSDP.jl.svg?branch=master
[build-url]: https://travis-ci.org/jump-dev/CSDP.jl
[winbuild-img]: https://ci.appveyor.com/api/projects/status/v8nb0yb7ahn9n7ol?svg=true
[winbuild-url]: https://ci.appveyor.com/project/jump-dev/csdp-jl
[codecov-img]: http://codecov.io/github/jump-dev/CSDP.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/jump-dev/CSDP.jl?branch=master
