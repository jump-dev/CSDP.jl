using CSDP
reload("CSDP")

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

C1 = Float64[[2 1]
             [1 2]]
C2 = Float64[[3 0 1]
             [0 2 0]
             [1 0 3]]
C3 = Diagonal{Float64}([0, 0])

C = Blockmatrix(C1, C2, C3)
b = [1.0, 2.0]

A1 = SparseBlockMatrix(
   [3 1
    1 3],
          [0 0 0
           0 0 0
           0 0 0],
       Diagonal([1,
                   0]))

A2 = SparseBlockMatrix(
      [0 0
       0 0],
          [3 0 1
           0 4 0
           1 0 5],
       Diagonal([0,
                   1]))


