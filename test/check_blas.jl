#!/usr/bin/env julia

"""
Check integer size of a blas library.
Seems like all BLAS routines return just positive indices.
"""

const blas_prec = (:ilaprec_64_, BLAS.libblas)
ccall(blas_prec, Clong, (Cstring,), "X")

const libblas = "/usr/lib/libblas.so.3"
const openblas = "/usr/lib/libopenblas.so.0"

using Base.LinAlg.BlasInt

A = [1.0 0.0; 0.0 -1.0]
lda = max(1,stride(A,2))
infot = Ref{BlasInt}()
uplo = 'U'
ccall((:dpotrf_64_, Base.LinAlg.BLAS.libblas), Void,
      (Ptr{UInt8}, Ptr{BlasInt}, Ptr{eltype(A)}, Ptr{BlasInt}, Ptr{BlasInt}),
      &uplo, &size(A,1), A, &lda, info)

ccall((:dpotrf_, openblas), Void,
      (Ptr{UInt8}, Ptr{BlasInt}, Ptr{eltype(A)}, Ptr{BlasInt}, Ptr{BlasInt}),
      &uplo, &size(A,1), A, &lda, infot)

