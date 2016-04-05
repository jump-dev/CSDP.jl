using CSDP

if !isdefined(:I)
    I = [1 3
         5 6]
    I = map(Float64, I)
end


br = CSDP.brec(reshape(I, length(I)), CSDP.MATRIX, 4)
ccall((:printb, CSDP.csdp), Void, (CSDP.blockrec,), br)
bra = [br, br]
block = CSDP.blockmatrix(1, pointer(bra))
println(block)
# ccall((:printm, CSDP.csdp), Void, (CSDP.blockmatrix,), block)
CSDP.triu(block)
