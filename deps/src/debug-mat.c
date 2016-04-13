#include <stdio.h>
#include "blockmat.h"


void printb(struct blockrec b) {
  int i;
  printf("blockrec:\n");
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


void print_sizeof() {
  printf("sizeof(void*)                 %d\n",
         (int) sizeof(void*));
  printf("sizeof(int)                   %d\n",
         (int) sizeof(int));
  printf("sizeof(enum blockcat)         %d\n",
         (int) sizeof(enum blockcat));
  printf("sizeof(struct blockrec)       %d\n",
         (int) sizeof(struct blockrec));
  printf("sizeof(struct blockmatrix)    %d\n",
         (int) sizeof(struct blockmatrix));
  printf("sizeof(struct sparseblock)    %d\n",
         (int) sizeof(struct sparseblock));
}



void printm(struct blockmatrix A) {
  int blk;
  printf("A.nblocks = %d\n", A.nblocks);
  printf("A.blocks  = %p\n", A.blocks);
  for (blk=0; blk <= A.nblocks; blk++) {
    printf("block[%d]: %p\n", blk, &A.blocks[blk]);
    printb(A.blocks[blk]);
  }

}


void print_sparse_block(struct sparseblock *b) {
  int i;
  printf("Printing block: %p\n", b);
  if (b == NULL)
    return;
  printf(" next: %p\n", b->next);
  printf(" nextbyblock: %p\n", b->nextbyblock);
  printf(" constraintnum: %d\n", b->constraintnum);
  printf(" blocknum: %d\n", b->blocknum);
  printf(" blocksize: %d\n", b->blocksize);
  printf(" numentries: %d\n", b->numentries);
  if (b->blocksize <= 30) {
    for (i = 1; i <= b->numentries; i++) {
      printf("  block[%d, %d] = %f\n",
             b->iindices[i],
             b->jindices[i],
             b->entries[i]);
    }
  } else {
    printf(" TOO LARGE\n");
  }
  print_sparse_block(b->next);
}

void  print_constraints(int k,
                        struct constraintmatrix *constraints)
{
  int i, j;
  FILE *fid = stderr;
  struct sparseblock *p;

  for (i=1; i<=k; i++)
    {
      fprintf(fid, "printing constraints[%d].blocks\n", i);
      p=constraints[i].blocks;
      while (p != NULL)
        {
          print_sparse_block(p);
          for (j=1; j<=p->numentries; j++)
            {
              fprintf(fid, "i=%d, j=%d\n", i, j);
              fprintf(fid,"%d %d %d %d %.18e \n",i,p->blocknum,
                      p->iindices[j],
                      p->jindices[j],
                      p->entries[j]);
            };
          p=p->next;
        };
    };
}
