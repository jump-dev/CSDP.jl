using MathOptInterface
const MOI = MathOptInterface
const MOIT = MOI.Test
const MOIB = MOI.Bridges

const MOIU = MOI.Utilities
MOIU.@model SDModelData () (EqualTo, GreaterThan, LessThan) (Zeros, Nonnegatives, Nonpositives, PositiveSemidefiniteConeTriangle) () (SingleVariable,) (ScalarAffineFunction,) (VectorOfVariables,) (VectorAffineFunction,)
const optimizer = MOIU.CachingOptimizer(SDModelData{Float64}(), CSDP.CSDPOptimizer(printlevel=0))
const config = MOIT.TestConfig(atol=1e-4, rtol=1e-4)

@testset "Linear tests" begin
    MOIT.contlineartest(MOIB.SplitInterval{Float64}(optimizer), config)
end
@testset "Conic tests" begin
    MOIT.contconictest(MOIB.RootDet{Float64}(MOIB.GeoMean{Float64}(MOIB.RSOCtoPSD{Float64}(MOIB.SOCtoPSD{Float64}(optimizer)))), config, ["psds", "rootdets", "logdet", "exp"])
end
