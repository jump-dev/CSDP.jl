const solver = CSDP.CSDPSolver(printlevel=0)

import MathProgBase
@static if VERSION >= v"0.7-"
    const MPB_test_path = joinpath(dirname(pathof(MathProgBase)), "..", "test")
else
    const MPB_test_path = joinpath(Pkg.dir("MathProgBase"), "test")
end

@testset "Linear tests" begin
    include(joinpath(MPB_test_path, "linproginterface.jl"))
    linprogsolvertest(solver, 1e-6)
end

@testset "Conic tests" begin
    include(joinpath(MPB_test_path, "conicinterface.jl"))
    # FIXME fails on Windows 32 bits... Maybe I should put linear vars/cons
    # in a diagonal matrix in SemidefiniteModels.jl instead of many 1x1 blocks
    @static if !Compat.Sys.iswindows() || Compat.Sys.WORD_SIZE != 32
        @testset "Conic linear tests" begin
            coniclineartest(solver, duals=true, tol=1e-6)
        end

# TODO Fixed by https://github.com/JuliaOpt/SemidefiniteModels.jl/commit/d03248428f93772a05bd3d63a224982e2b85d88c
#      uncomment when this is released or when Julia v0.6 is dropped
#        @testset "Conic SOC tests" begin
#            conicSOCtest(CSDP.CSDPSolver(printlevel=0, write_prob="soc.prob"), duals=true, tol=1e-6)
#        end

        @testset "Conic SOC rotated tests" begin
            conicSOCRotatedtest(solver, duals=true, tol=1e-6)
        end
    end

    @testset "Conic SDP tests" begin
        conicSDPtest(solver, duals=false, tol=1e-6)
    end
end
