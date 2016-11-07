/* Copied from https://github.com/xianyi/OpenBLAS/blob/develop/common.h */

#if defined(OS_WINDOWS) && defined(__64BIT__)
typedef long long BLASLONG;
#else
typedef long BLASLONG;
#endif

typedef BLASLONG integer;
typedef double doublereal;
