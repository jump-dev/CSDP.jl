using CSDP

C = Blockmatrix(eye(0),
                [1 3
                 5 6])

println("C.blocks[1].blockcategory = $(C.blocks[1].blockcategory)")

c = convert(CSDP.blockmatrix, C)

println(Base.unsafe_convert(Ptr{CSDP.blockrec}, c.blocks))

CSDP.triu(c)

C
