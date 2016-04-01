# CSDP

[![Build Status](https://travis-ci.org/EQt/CSDP.jl.svg?branch=master)](https://travis-ci.org/EQt/CSDP.jl)

Julia wrapper to [CSDP](https://projects.coin-or.org/Csdp) semidefinite programming solver.
On Unix systems, the source code is downloaded and build.
On Windows, the binaries of version 6.1.0 are just downloaded.

## Static Library
The build system only provides a static library.
The quite old (September 2010) [`pycsdp`](https://github.com/BenjaminKern/pycsdp) interface by [Benjamin Kern](http://ifatwww.et.uni-magdeburg.de/syst/about_us/people/kern/index.shtml) circumvents the problem by writing some C++ [code](https://github.com/BenjaminKern/pycsdp/tree/master/CXX) to which the static library is linked.
The Sage [module](https://github.com/mghasemi/pycsdp) by @mghasemi is a Cython interface.
So far, I don't know how the libcsdp is installed or whether they assume that it is already available on the system.

That is why this package tries to parse the makefile and compiles it itself.

On Windows you need the MinGW `gcc` compiler available in the `PATH`.
Furthermore `libblas` and `liblapack` are needed to be installed.
