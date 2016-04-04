#include <stdio.h>

enum category {OP1, OP2};

struct S {
  enum category c;
  int n;
  double *e;
};


double hello() {
  printf("Hello Worls");
  return 13.42;
}


double sum(struct S s) {
  printf("sum(struct S)\n");
  switch (s.c) {
  case OP1:
    printf("OP1\n");
    break;
  case OP2:
    printf("OP2\n");
    break;
  default:
    printf("s.category = %d\n", (int) s.c);
  }
  double r = 0;
  printf("sum(s): s.n = %d, s.e = %p\n", s.n, s.e);
  for (int i = 0; i < s.n; i++) {
    printf("s.e[%d] = %f\n", i, s.e[i]);
    r += s.e[i];
  }
  return r;
}
