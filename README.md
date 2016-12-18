# CSDP

[![Build Status](https://travis-ci.org/JuliaOpt/CSDP.jl.svg?branch=master)](https://travis-ci.org/JuliaOpt/CSDP.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/23qb5jkbbhx4ritw/branch/master?svg=true)](https://ci.appveyor.com/project/EQt/csdp-jl)


Julia wrapper to [CSDP](https://projects.coin-or.org/Csdp) semidefinite programming solver.

The original algorithm is described by
B. Borchers.
*CSDP, A C Library for Semidefinite Programming*.
Optimization Methods and Software 11(1):613-623, 1999.
DOI [10.1080/10556789908805765](http://dx.doi.org/10.1080/10556789908805765).
[Preprint](http://euler.nmt.edu/~brian/csdppaper.pdf).

## Status

The table below shows how the different CSDP status are converted to [MathProgBase](https://github.com/JuliaOpt/MathProgBase.jl) status.

CSDP code | State           | Description                                                        | MathProgBase status |
--------- | --------------- | ------------------------------------------------------------------ | ------------------- |
0         | Success         | SDP solved                                                         | Optimal             |
1         | Success         | The problem is primal infeasible, and we have a certificate        | Infeasible          |
2         | Success         | The problem is dual infeasible, and we have a certificate          | Unbounded           |
3         | Partial Success | A solution has been found, but full accuracy was not achieved.<br> One or more of primal infeasibility, dual infeasibility,<br> or relative duality gap are larger than their tolerances,<br> but by a factor of less than 1000.                                 | Unknown             |
4         | Failure         | Maximum iterations reached.                                        | Unknown             |
5         | Failure         | Stuck at edge of primal feasibility.                               | Unknown             |
6         | Failure         | Stuck at edge of dual infeasibility.                               | Unknown             |
7         | Failure         | Lack of progress.                                                  | Unknown             |
8         | Failure         | X, Z, or O was singular.                                           | Error               |
9         | Failure         | Detected NaN or Inf values.                                        | Error               |

If the `printlevel` option is at least 1, the following will be printed:

* If the return code is 1, the dual variable `y` provides a certificate for primal infeasibility, CSDP will print `⟨a, y⟩` and `||A'(y) - Z||`
* if the return code is 2, the primal variable `X` provides a certificate of dual infeasibility, CSDP will print `⟨C, X⟩` and `||A(X)||`
* otherwise, CSDP will print
  * the primal/dual objective value,
  * the relative primal/dual infeasibility,
  * the real gap `d - p` and real realtive gap `(d - p) / (1 + |d| + |p|)`,
  * the XY gap `⟨Z, X⟩` and XY relative gap `⟨Z, X⟩ / (1 + |d| + |p|)`
  * and the DIMACS error measures.

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
- [ ] Return solution matrix X (as Julia::Matrix)
- [ ] Show a Blockmatrix accordingly
- [ ] Integrate in SemidefinitePorgramming.jl
- [ ] Make more user friendly interface
- [ ] Maybe port `libcsdp` to use 64bit Lapack, aka replace “some `int`s” by `long int` (the variables used in a Lapack call).
      When this was done, one could set `JULIA_LAPACK` to `true` in the `deps/constants.jl` file.
      The [`pycparser`](https://github.com/eliben/pycparser) or `Clang.cindex` might be useful for that.
- [ ] Add a C header for the Lapack routines in order to check the types and reduce the possibility to crash.
      Use http://www.netlib.org/clapack/clapack.h as starting point.
- [ ] Maybe think about an own array type to circumvent the 1-index problems in `libcsdp`.
- [ ] Map Julia's sparse arrays to `sparsematrixblock`.
- [ ] Upload `libcsdp.dll` for Windows via Appveyor deployment as described at
      [JuliaCon](https://www.youtube.com/watch?v=XKdKdfHB2KM&index=12&list=PLP8iPy9hna6SQPwZUDtAM59-wPzCPyD_S)
