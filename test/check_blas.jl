#!/usr/bin/env julia

"""
Check integer size of a blas library.
Seems like all BLAS routines return just positive indices.
"""

const blas_prec = (:ilaprec_64_, BLAS.libblas)
ccall(blas_prec, Clong, (Cstring,), "X")

const libblas = "/usr/lib/libblas.so.3"
const openblas = "/usr/lib/libopenblas.so.0"

A = [1.0 0.0; 0.0 -1.0]
lda = max(1,stride(A,2))
infot = Ref{LinearAlgebra.BlasInt}()
uplo = 'U'
ccall((:dpotrf_64_, LinearAlgebra.BLAS.libblas), Void,
      (Ptr{UInt8}, Ptr{LinearAlgebra.BlasInt}, Ptr{eltype(A)}, Ptr{LinearAlgebra.BlasInt}, Ptr{LinearAlgebra.BlasInt}),
      &uplo, &size(A,1), A, &lda, info)

ccall((:dpotrf_, openblas), Void,
      (Ptr{UInt8}, Ptr{LinearAlgebra.BlasInt}, Ptr{eltype(A)}, Ptr{LinearAlgebra.BlasInt}, Ptr{LinearAlgebra.BlasInt}),
      &uplo, &size(A,1), A, &lda, infot)

