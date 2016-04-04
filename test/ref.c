#include <stdio.h>


struct S {
  int n;
  double *e;
};

double sum(struct S s) {
  printf("Hello\\n");
  double r = 0;
  printf("sum(s): s.n = %d, s.e = %p\\n", s.n, s.e);
  for (int i = 0; i < s.n; i++) {
    printf("s.e[%d] = %f\\n", i, s.e[i]);
    r += s.e[i];
  }
  return r;
}
