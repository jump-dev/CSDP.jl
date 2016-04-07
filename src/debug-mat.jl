function print_block(b::blockrec)
    ccall((:printb, CSDP.csdp), Void, (blockrec,), b)
end

function printm(A::blockmatrix)
    ccall((:printm, CSDP.csdp), Void, (blockmatrix,), A)
end
