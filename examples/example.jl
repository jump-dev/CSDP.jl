using CSDP
# reload("CSDP")

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

if !isdefined(:C1)
    C1 = Float64[[2 1]
                 [1 2]]
end
println("&C1 = $(pointer(C1))")
C1b = CSDP.brec(C1)
println("brec(C1) = $C1b")
CSDP.print_block(C1b)

if !isdefined(:C2)
    C2 = Float64[[3 0 1]
                 [0 2 0]
                 [1 0 3]]
    println("&C2 = $(pointer(C2))")
end

C3 = Diagonal{Float64}([0, 0])

println("&C3 = $(pointer(diag(C3)))")

C = Blockmatrix(C1, C2, C3)

for block in C.blocks
    CSDP.print_block(block)
end

## C = Blockmatrix(
##    [2 1
##     1 2],
##          [3 0 1
##           0 2 0
##           1 0 3],
##        Diagonal([0,
##                    0]))

b = [1.0, 2.0]

A1 = ConstraintMatrix(
   [3 1
    1 3],
          [0 0 0
           0 0 0
           0 0 0],
       Diagonal([1,
                   0]))
#
A2 = ConstraintMatrix(
      [0 0
       0 0],
          [3 0 1
           0 4 0
           1 0 5],
       Diagonal([0,
                   1]))
A = [A1, A2]

constraints = [cmat(s, i) for (i,s) in enumerate(A)]


# for block in constraints
#     CSDP.print_sparseblock(block.blocks)
# end
# println(A_[1])
# println(pointer(constraints))
# println(first(A_))

# CSDP.print_constraints(Cint(2), constraints)

n = 7
k = 2

CSDP.write_prob("prob.dat-s", n, k, C, b, constraints)


X = CSDP.blockmatrix(0, C_NULL)
Z = CSDP.blockmatrix(0, C_NULL)
pobj = Cdouble[0.0]
dobj = Cdouble[0.0]
y = Cvector{Cdouble}(C_NULL)

CSDP.initsoln(Cint(7),
              Cint(2),
              blockmatrix(C),
              fptr(b),
              fptr(constraints),
              ptr(X),
              pointer(y),
              ptr(Z))
finalizer(X, free_blockmatrix)
finalizer(Z, free_blockmatrix)
finalizer(y, s -> Libc.free(s.e))

println("\n\n**** X ******")
CSDP.printm(X)
println("\n\n**** Z ******")
CSDP.printm(Z)
println("\n\n**** y ******")
println(y)

println("\n\n**** constraints ******")
println(constraints)

# https://thenewphalls.wordpress.com/2014/03/21/capturing-output-in-julia/
oldstdout = STDOUT
rd, wr = redirect_stdout()
ret = CSDP.easy_sdp(Cint(7),                # n
                    Cint(2),                # k
                    blockmatrix(C),         # C
                    fptr(b),
                    fptr(constraints),
                    0.0,
                    ptr(X),
                    pointer(y),
                    ptr(Z),
                    pointer(pobj),
                    pointer(dobj))

output = ASCIIString(readavailable(rd))
redirect_stdout(oldstdout)
println("Bye")
println(output)
