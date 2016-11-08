using CSDP
using Base.Test

vec = Cdouble[1.0, 2.0, 0.0, -1.0]
l = length(vec)
inc = 1
const llapack = Libdl.dlpath(LinAlg.LAPACK.liblapack)
const dasum = endswith(splitext(llapack)[1], "64_") ? :dasum_64_ : :dasum_
try
    n1 = ccall((dasum, llapack), Float64, (Ptr{Int}, Ptr{Cdouble}, Ptr{Int}), &l, vec, &inc)
    @assert abs(n1 - 4) < 1e-15 "n1 = $n1"
catch
    println(dasum)
    println(llapack)
    rethrow()
end

n1 = ccall( (:norm1, CSDP.csdp), Float64, (Cint, Ptr{Cdouble}), length(vec), vec)
@assert abs(n1 - 4) < 1e-15 "n1 = $n1"

@testset "Example" begin
    cd("../examples/") do
        include(joinpath(pwd(), "example.jl"))
        @test size(X) == (7, 7)
        @test length(y) == 2
        @test size(Z) == (7, 7)
        X✓ = [3 3  0 0 0 0 0;
              3 3  0 0 0 0 0;
              0 0 16 0 0 0 0;
              0 0  0 0 0 0 0;
              0 0  0 0 0 0 0;
              0 0  0 0 0 0 0;
              0 0  0 0 0 0 0] / 24
        @test norm(Array(X) - X✓) < 1e-6
        y✓ = [3, 4] / 4
        @test norm(Array(y) - y✓) < 1e-6
        Z✓ = [1 -1 0 0 0 0 0;
             -1  1 0 0 0 0 0;
              0  0 0 0 0 0 0;
              0  0 0 8 0 0 0;
              0  0 0 0 8 0 0;
              0  0 0 0 0 3 0;
              0  0 0 0 0 0 4] / 4
        @test norm(Array(Z) - Z✓) < 1e-6
    end
end

include(joinpath(Pkg.dir("MathProgBase"),"test","conicinterface.jl"))
coniclineartest(CSDP.CSDPSolver(), duals=true, tol=1e-6)
conicSOCtest(CSDP.CSDPSolver(), duals=true, tol=1e-6)
conicSOCRotatedtest(CSDP.CSDPSolver(), duals=true, tol=1e-6)
conicSDPtest(CSDP.CSDPSolver(), duals=false, tol=1e-6)
