function print_block(b::blockrec)
    ccall((:printb, CSDP.csdp), Void, (blockrec,), b)
end

function printm(A::blockmatrix)
    ccall((:printm, CSDP.csdp), Void, (blockmatrix,), A)
end

print_sparseblock(A::sparseblock) = print_sparseblock(pointer_from_objref(A))
function print_sparseblock(a::Ptr{sparseblock})
    ccall((:print_sparse_block, CSDP.csdp), Void, (Ptr{sparseblock},), a)
end


function print_sizeof()
    ccall((:print_sizeof, CSDP.csdp), Void, ())
end

