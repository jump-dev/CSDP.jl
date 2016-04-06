The main function is `sdp(...)` in `../deps/src/Csdp-6.1.1/lib/sdp.c`, starting in line 68.
It takes about 40 parameters, including a lot of structs.
In contrast, the `easy_sdp(...)` method has only 11 parameters, because it computes an initial solution and working memory.


Csdp works always with block matrices.
For sparse matrices, I don't see the benefits, yet.

Another peculiar aspect is, that the C code uses Fortran like arrays, i.e. the first index is 1, leaving an empty entry before.
Only two dimensional arrays are accessed via the `ijtok` macro which starts at 0.

Question: Is it necessary that all the matrices C, A1, and A2 in the example have the same block structure?
