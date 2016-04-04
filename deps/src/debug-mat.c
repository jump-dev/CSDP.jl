#include <stdio.h>
#include "blockmat.h"


void printb(struct blockrec b) {
  int i;
  printf("blockrec:\n");
  printf(" sizeof(b)    : %d\n", (int) sizeof(b));
  printf(" sizeof(cat):   %d\n", (int) sizeof(b.blockcategory));
  printf(" blockcategory: %d\n", b.blockcategory);
  printf(" blocksize:     %d\n", b.blocksize);
  printf(" data.vec:      %p\n", b.data.vec);
  if (b.blocksize <= 16) {
    for (i = 0; i < b.blocksize; i++)
      printf("  %f\n", b.data.vec[i]);
  }
}


void printb_(struct blockrec *b) {
  printb(*b);
}


void printm(struct blockmatrix A) {
  int blk;
  printf("sizeof(A) = %d\n", (int) sizeof(A));
  printf("A.nblocks = %d\n", A.nblocks);
  printf("A.blocks  = %p\n", A.blocks);
  for (blk=0; blk <= A.nblocks; blk++) {
    printf("block[%d]: %p\n", blk, &A.blocks[blk]);
    printb(A.blocks[blk]);
  }

}
