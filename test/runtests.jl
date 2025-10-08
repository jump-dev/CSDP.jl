# Copyright (c) 2016: CSDP.jl contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

using Test
using CSDP
import LinearAlgebra

@testset "Call libcsdp.norm1" begin
    vec = Cdouble[1.0, 2.0, 0.0, -1.0]
    n1 = @ccall(
        CSDP.libcsdp.norm1(length(vec)::Cint, vec::Ptr{Cdouble})::Cdouble
    )
    @test abs(n1 - 4) < 1e-15
end

function test_example()
    C = BlockMatrix(
        [2 1; 1 2],
        [3 0 1; 0 2 0; 1 0 3],
        LinearAlgebra.Diagonal([0, 0]),
    )
    b = [1.0, 2.0]
    constraints = [
        ConstraintMatrix(
            1,
            [3 1; 1 3],
            [0 0 0; 0 0 0; 0 0 0],
            LinearAlgebra.Diagonal([1, 0]),
        ).csdp,
        ConstraintMatrix(
            2,
            [0 0; 0 0],
            [3 0 1; 0 4 0; 1 0 5],
            LinearAlgebra.Diagonal([0, 1]),
        ).csdp,
    ]
    CSDP.write_prob("prob.dat-s", C, b, constraints)
    X, y, Z = initsoln(C, b, constraints)
    pobj, dobj = easy_sdp(C, b, constraints, X, y, Z)
    CSDP.write_sol("prob.sol", X, y, Z)
    X✓ = [
        3 3 0 0 0 0 0
        3 3 0 0 0 0 0
        0 0 16 0 0 0 0
        0 0 0 0 0 0 0
        0 0 0 0 0 0 0
        0 0 0 0 0 0 0
        0 0 0 0 0 0 0
    ]
    @test isapprox(X, X✓ / 24; atol = 1e-6)
    @test isapprox(y, [0.75, 1.0]; atol = 1e-6)
    Z✓ = [
        1 -1 0 0 0 0 0
        -1 1 0 0 0 0 0
        0 0 0 0 0 0 0
        0 0 0 8 0 0 0
        0 0 0 0 8 0 0
        0 0 0 0 0 3 0
        0 0 0 0 0 0 4
    ]
    @test isapprox(Z, Z✓ / 4; atol = 1e-6)
    return
end

@testset "Example" begin
    if !Sys.iswindows()
        test_example()
    end
end

@testset "Options" begin
    @test CSDP.paramstruc(Dict(:axtol => 1e-7)).axtol == 1e-7
end

@testset "MathOptInterface" begin
    include("MOI_wrapper.jl")
end
