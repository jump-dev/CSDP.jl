# Copyright (c) 2016: CSDP.jl contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

import CSDP

#=
# Example copied from `example/example.c`
   An example showing how to call the easy_sdp() interface to CSDP.  In
   this example, we solve the problem

      max tr(C*X)
          tr(A1*X)=1
          tr(A2*X)=2
          X >= 0       (X is PSD)

   where

    C=[2 1
       1 2
           3 0 1
           0 2 0
           1 0 3
                 0
                   0]

   A1=[3 1
       1 3
           0 0 0
           0 0 0
           0 0 0
                 1
                   0]

   A2=[0 0
       0 0
           3 0 1
           0 4 0
           1 0 5
                 0
                   1]

  Notice that all of the matrices have block diagonal structure.  The first
  block is of size 2x2.  The second block is of size 3x3.  The third block
  is a diagonal block of size 2.

=#

C = CSDP.BlockMatrix(
    Float64[2 1; 1 2],
    Float64[3 0 1; 0 2 0; 1 0 3],
    Float64[0 0; 0 0],
)

b = Float64[1.0, 2.0]

A1 = CSDP.ConstraintMatrix(1, Float64[3 1; 1 3], zeros(3, 3), Float64[1 0; 0 0])

A2 = CSDP.ConstraintMatrix(
    2,
    zeros(2, 2),
    Float64[3 0 1; 0 4 0; 1 0 5],
    Float64[0 0; 0 1],
)

constraints = [A1.csdp, A2.csdp]

CSDP.write_prob("prob.dat-s", 7, 2, C, b, constraints)

X, y, Z = CSDP.initsoln(7, 2, C, b, constraints)

status, pobj, dobj = CSDP.easy_sdp(7, 2, C, b, constraints, 0.0, X, y, Z)

@static if !Sys.iswindows()
    CSDP.write_sol("prob.sol", 7, 2, X, y, Z)
end
