# Copyright (c) 2016: CSDP.jl contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

using CSDP

using Test
using LinearAlgebra

@static if !Sys.iswindows() # FIXME Segfault on Windows
    @testset "Example" begin
        cd(joinpath(dirname(dirname(pathof(CSDP))), "examples")) do
            include(joinpath(pwd(), "example.jl"))
            @test size(X) == (7, 7)
            @test length(y) == 2
            @test size(Z) == (7, 7)
            X✓ =
                [
                    3 3 0 0 0 0 0
                    3 3 0 0 0 0 0
                    0 0 16 0 0 0 0
                    0 0 0 0 0 0 0
                    0 0 0 0 0 0 0
                    0 0 0 0 0 0 0
                    0 0 0 0 0 0 0
                ] / 24
            @test norm(convert(AbstractArray, X) - X✓) < 1e-6
            y✓ = [3, 4] / 4
            @test norm(convert(AbstractArray, y) - y✓) < 1e-6
            Z✓ =
                [
                    1 -1 0 0 0 0 0
                    -1 1 0 0 0 0 0
                    0 0 0 0 0 0 0
                    0 0 0 8 0 0 0
                    0 0 0 0 8 0 0
                    0 0 0 0 0 3 0
                    0 0 0 0 0 0 4
                ] / 4
            @test norm(convert(AbstractArray, Z) - Z✓) < 1e-6
        end
    end
end

@testset "Options" begin
    @test CSDP.paramstruc(Dict(:axtol => 1e-7)).axtol == 1e-7
end

@testset "MathOptInterface" begin
    include("MOI_wrapper.jl")
end
