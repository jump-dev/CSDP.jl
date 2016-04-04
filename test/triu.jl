using CSDP

I = [1 3
     5 6]

I = map(Float64, I)

br = CSDP.brec(I)
ccall((:printb, CSDP.csdp), Void, (CSDP.blockrec,), br)
bra = [br, br]
block = CSDP.blockmatrix(1, pointer(bra))
println(block)
# ccall((:printm, CSDP.csdp), Void, (CSDP.blockmatrix,), block)
CSDP.triu(block)
