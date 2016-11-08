function print_block(b::blockrec)
    ccall((:printb, CSDP.csdp), Void, (blockrec,), b)
end

function printm(A::blockmatrix)
    ccall((:printm, CSDP.csdp), Void, (blockmatrix,), A)
end
printm(A::BlockMatrix) = printm(A.csdp)
export printm

print_sparseblock(A::sparseblock) = print_sparseblock(pointer_from_objref(A))
function print_sparseblock(a::Ptr{sparseblock})
    ccall((:print_sparse_block, CSDP.csdp), Void, (Ptr{sparseblock},), a)
end


function print_sizeof()
    ccall((:print_sizeof, CSDP.csdp), Void, ())
end

function print_constraints(C::Vector{constraintmatrix})
    ccall((:print_constraints, CSDP.csdp), Void, (Cint, Ptr{constraintmatrix}), length(C), fptr(C))
end


using Base.show

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
