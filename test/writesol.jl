using CSDP

X_sol = Blockmatrix(
   [2 1
    1 2],
        [3 0 1
         0 2 0
         1 0 3],
      Diagonal([0,
                  0]))

Z_sol = Blockmatrix(
   [4 1
    1 2],
        [3 0 1
         0 2 0
         1 0 3],
      Diagonal([0,
                  0]))

y_origin = [5.5, 6.2]
y = Cvector{Cdouble}(CSDP.fptr(y_origin))

k = 2
n = 7

Xs = CSDP.blockmatrix(X_sol)
println("********** Alright **********")

ys = y.e
Zs = CSDP.blockmatrix(Z_sol)
@printf "********** Alright %s\n"  @__FILE__


CSDP.write_sol("prob.dat-s",
               n,
               k,
               X_sol,
               y,
               Z_sol)
