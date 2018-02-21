using CSDP
using Base.Test
using Base.LinAlg.BlasInt

@testset "Interact with BLAS" begin
    vec = Cdouble[1.0, 2.0, 0.0, -1.0]
    l = length(vec)
    inc = 1
    n1 = ccall((BLAS.@blasfunc(dasum_), LinAlg.BLAS.libblas),
               Cdouble,
               (Ptr{BlasInt}, Ptr{Cdouble}, Ptr{BlasInt}),
               &l, vec, &inc)
    @test abs(n1 - 4) < 1e-15
end

@testset "Call libcsdp.norm1" begin
    vec = Cdouble[1.0, 2.0, 0.0, -1.0]
    try
        n1 = ccall((:norm1, CSDP.csdp),
                   Cdouble,
                   (Cint, Ptr{Cdouble}),
                   length(vec), vec)
        @test abs(n1 - 4) < 1e-15
    catch
        println("n1 = $n1, vec=$vec, length(vec)=$(length(vec))")
        rethrow()
    end
end

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
        @test norm(AbstractArray(X) - X✓) < 1e-6
        y✓ = [3, 4] / 4
        @test norm(AbstractArray(y) - y✓) < 1e-6
        Z✓ = [1 -1 0 0 0 0 0;
             -1  1 0 0 0 0 0;
              0  0 0 0 0 0 0;
              0  0 0 8 0 0 0;
              0  0 0 0 8 0 0;
              0  0 0 0 0 3 0;
              0  0 0 0 0 0 4] / 4
        @test norm(AbstractArray(Z) - Z✓) < 1e-6
    end
end

@testset "Options" begin
    @test_throws ErrorException CSDPOptimizer(bad_option = 1)
    @test CSDP.paramstruc(Dict(:axtol => 1e-7)).axtol == 1e-7
end

using MathOptInterface
const MOI = MathOptInterface
const MOIT = MOI.Test
const MOIU = MOI.Utilities

MOIU.@model SDModelData () (EqualTo, GreaterThan, LessThan) (Zeros, Nonnegatives, Nonpositives, PositiveSemidefiniteConeTriangle) () (SingleVariable,) (ScalarAffineFunction,) (VectorOfVariables,) (VectorAffineFunction,)

using MathOptInterfaceBridges
const MOIB = MathOptInterfaceBridges

MOIB.@bridge SplitInterval MOIB.SplitIntervalBridge () (Interval,) () () () (ScalarAffineFunction,) () ()
MOIB.@bridge SOCtoPSDC MOIB.SOCtoPSDCBridge () () (SecondOrderCone,) () () () (VectorOfVariables,) (VectorAffineFunction,)
MOIB.@bridge RSOCtoPSDC MOIB.RSOCtoPSDCBridge () () (RotatedSecondOrderCone,) () () () (VectorOfVariables,) (VectorAffineFunction,)
MOIB.@bridge GeoMean MOIB.GeoMeanBridge () () (GeometricMeanCone,) () () () (VectorOfVariables,) (VectorAffineFunction,)
MOIB.@bridge RootDet MOIB.RootDetBridge () () (RootDetConeTriangle,) () () () (VectorOfVariables,) (VectorAffineFunction,)

const optimizer = CSDP.CSDPOptimizer(printlevel=0)
const config = MOIT.TestConfig(atol=1e-4, rtol=1e-4)

@testset "Linear tests" begin
    MOIT.contlineartest(SplitInterval{Float64}(MOIU.CachingOptimizer(SDModelData{Float64}(), optimizer)), config)
end
@testset "Conic tests" begin
    MOIT.contconictest(RootDet{Float64}(GeoMean{Float64}(RSOCtoPSDC{Float64}(SOCtoPSDC{Float64}(MOIU.CachingOptimizer(SDModelData{Float64}(), optimizer))))), config, ["logdet", "exp"])
end

#   @testset "Linear tests" begin
#       include(joinpath(Pkg.dir("MathProgBase"),"test","linproginterface.jl"))
#       linprogsolvertest(CSDP.CSDPSolver(), 1e-7)
#   end
#
#   @testset "Conic tests" begin
#       include(joinpath(Pkg.dir("MathProgBase"),"test","conicinterface.jl"))
#       # FIXME fails on Windows 32 bits... Maybe I should put linear vars/cons
#       # in a diagonal matrix in SemidefiniteModels.jl instead of many 1x1 blocks
#       @static if !is_windows() || Sys.WORD_SIZE != 32
#           @testset "Conic linear tests" begin
#               coniclineartest(CSDP.CSDPSolver(), duals=true, tol=1e-6)
#           end
#
#           @testset "Conic SOC tests" begin
#               conicSOCtest(CSDP.CSDPSolver(write_prob="soc.prob"), duals=true, tol=1e-6)
#           end
#
#           @testset "Conic SOC rotated tests" begin
#               conicSOCRotatedtest(CSDP.CSDPSolver(), duals=true, tol=1e-6)
#           end
#       end
#
#       @testset "Conic SDP tests" begin
#           conicSDPtest(CSDP.CSDPSolver(), duals=false, tol=1e-6)
#       end
#   end
