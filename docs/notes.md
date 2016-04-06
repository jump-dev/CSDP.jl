The main function is `sdp(...)` in `../deps/src/Csdp-6.1.1/lib/sdp.c`, starting in line 68.
It takes about 40 parameters, including a lot of structs.
In contrast, the `easy_sdp(...)` method has only 11 parameters, because it computes an initial solution and working memory.


Csdp works always with block matrices.
For sparse matrices, I don't see the benefits, yet.
