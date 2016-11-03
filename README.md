# CSDP

[![Build Status](https://travis-ci.org/EQt/CSDP.jl.svg?branch=master)](https://travis-ci.org/EQt/CSDP.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/23qb5jkbbhx4ritw/branch/master?svg=true)](https://ci.appveyor.com/project/EQt/csdp-jl)


Julia wrapper to [CSDP](https://projects.coin-or.org/Csdp) semidefinite programming solver.

The original algorithm is described by
B. Borchers.
*CSDP, A C Library for Semidefinite Programming*.
Optimization Methods and Software 11(1):613-623, 1999.
DOI [10.1080/10556789908805765](http://dx.doi.org/10.1080/10556789908805765).
[Preprint](http://euler.nmt.edu/~brian/csdppaper.pdf).


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
