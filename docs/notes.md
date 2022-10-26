# First Observations...

The main function is `sdp(...)` in `../deps/src/Csdp-6.1.1/lib/sdp.c`, starting in line 68.
It takes about 40 parameters, including a lot of structs.
In contrast, the `easy_sdp(...)` method has only 11 parameters, because it computes an initial solution and working memory.


Csdp works always with block matrices.
For sparse matrices, I don't see the benefits, yet.

Question: Is it necessary that all the matrices C, A1, and A2 in the example have the same block structure?
Yes, it is: They need to be multiplied or added.

# Notify
The `sparseblock.nextbyblock` pointer is always `NULL` in the example.


# Fortran indices
Another peculiar aspect is, that the C code uses Fortran like arrays, i.e. the first index is 1, leaving an empty entry before.
Only two dimensional arrays are accessed via the `ijtok` macro which starts at 0.

To overcome the issues, one has to always add another element to the array or one should add -1 to the pointer; that is done by the `offset` function which returns the pointer to “before that object”.


# Mutable vs Immutable
A major problem seems to be the the question whether `blockmatrix` should be immutable or not:
On the one hand, in some C functions the `blockmatrix` has to be handed over; so the memory alignment, which is better for immutable's, is important.
On the other hand, `blockmatrix` has to be allocated by `init_sol`; that is why it has to be mutable.
