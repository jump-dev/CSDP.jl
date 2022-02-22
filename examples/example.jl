using CSDP

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

C = BlockMatrix(
    [
        2 1
        1 2
    ],
    [
        3 0 1
        0 2 0
        1 0 3
    ],
    Diagonal([0, 0]),
)

b = [1.0, 2.0]

A1 = ConstraintMatrix(
    1,
    [
        3 1
        1 3
    ],
    [
        0 0 0
        0 0 0
        0 0 0
    ],
    Diagonal([1, 0]),
)

A2 = ConstraintMatrix(
    2,
    [
        0 0
        0 0
    ],
    [
        3 0 1
        0 4 0
        1 0 5
    ],
    Diagonal([0, 1]),
)

constraints = [A.csdp for A in [A1, A2]]

CSDP.write_prob("prob.dat-s", C, b, constraints)

X, y, Z = initsoln(C, b, constraints)

pobj, dobj = easy_sdp(C, b, constraints, X, y, Z)

@static if !Sys.iswindows()
    CSDP.write_sol("prob.sol", X, y, Z)
end
