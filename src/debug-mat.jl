function print_block(b::blockrec)
    ccall((:printb, CSDP.libcsdp), Nothing, (blockrec,), b)
end

function printm(A::blockmatrix)
    ccall((:printm, CSDP.libcsdp), Nothing, (blockmatrix,), A)
end
printm(A::BlockMatrix) = printm(A.csdp)
export printm

print_sparseblock(A::sparseblock) = print_sparseblock(pointer_from_objref(A))
function print_sparseblock(a::Ptr{sparseblock})
    ccall((:print_sparse_block, CSDP.libcsdp), Nothing, (Ptr{sparseblock},), a)
end


function print_sizeof()
    ccall((:print_sizeof, CSDP.libcsdp), Nothing, ())
end

function print_constraints(C::Vector{constraintmatrix})
    ccall((:print_constraints, CSDP.libcsdp), Nothing, (CSDP_INT, Ptr{constraintmatrix}), length(C), fptr(C))
end


function Base.show(io::IO, b::sparseblock)
    println(io, "\nsparseblock(", pointer_from_objref(b))
    println(io, " next          :  ",  b.next         )
    println(io, " nextbyblock   :  ",  b.nextbyblock  )
    println(io, " entries       :  ",  b.entries      )
    println(io, " iindices      :  ",  b.iindices     )
    println(io, " jindices      :  ",  b.jindices     )
    println(io, " numentries    :  ",  b.numentries   )
    println(io, " blocknum      :  ",  b.blocknum     )
    println(io, " blocksize     :  ",  b.blocksize    )
    println(io, " constraintnum :  ",  b.constraintnum)
    println(io, " issparse      :  ",  b.issparse     )
    println(io, ")")
end
