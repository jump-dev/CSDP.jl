using CSDP
using Base.Test

vec = Cdouble[1.0, 2.0, 0.0, -1.0]
n1 = ccall( (:norm1, CSDP.csdp), Float64, (Int, Ptr{Cdouble}), length(vec), vec)

@test abs(n1 - 4) < 1e-15

