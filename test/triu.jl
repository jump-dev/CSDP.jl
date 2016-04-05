using CSDP

if !isdefined(:J) || !isa(J, AbstractArray)
    J = [1 3
         5 6]
    J = map(Float64, J)
end


br = CSDP.brec(reshape(J, length(J)), CSDP.MATRIX, 4)
ccall((:printb, CSDP.csdp), Void, (CSDP.blockrec,), br)
bra = [br, br]
block = CSDP.blockmatrix(1, pointer(bra))
println(block)
# ccall((:printm, CSDP.csdp), Void, (CSDP.blockmatrix,), block)
CSDP.triu(block)
