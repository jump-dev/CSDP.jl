/* Copied from https://github.com/xianyi/OpenBLAS/blob/develop/common.h */

/* #if defined(OS_WINDOWS) && defined(__64BIT__) */
/*   typedef long long BLASLONG; */
/* #else */
/*   typedef long BLASLONG; */
/* #endif */

/* #if __WORDSIZE == 64 */
/*   typedef BLASLONG integer; */
/* #else */
/*   typedef int integer; */
/* #endif */

typedef double doublereal;
