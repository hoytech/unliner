// gcc -Wall -O2 allocator.c io.c tp.c -o tp -lpthread

#include <stdio.h>
#include <sys/uio.h>

#include "unpipe.h"

main() {
  int id;
  struct unpipe_ctx *c;
  char *str = "BLAH BLAH";
  char istr[1025];
  struct iovec iov;
  size_t len;
  int i=0;

  id = unpipe_create(16);
  //fprintf(stderr, "ID: %d\n", id);

  if (fork()) {
    c = unpipe_connect(id, 1);

    for (i=0; i<10000000; i++) {
      iov.iov_base = str;
      iov.iov_len = strlen(str);

      unpipe_writev(c, &iov, 1);
    }

fprintf(stdout, "IN DISCON 1\n");
    unpipe_disconnect(c, 1);
fprintf(stdout, "OUT DISCON 1\n");

    exit(0);
  }


  c = unpipe_connect(id, 0);

  while(1) {
    memset(istr, '\0', sizeof(istr));
    iov.iov_base = &istr[0];
    iov.iov_len = sizeof(istr) - 1;

fprintf(stdout, "IN!\n");
    len = unpipe_readv(c, &iov, 1);
fprintf(stdout, "GOT: %d\n", len);

    if (len <= 0) {
fprintf(stdout, "IN DISCON 0\n");
      unpipe_disconnect(c, 0);
fprintf(stdout, "OUT DISCON 0\n");
      exit(0);
    }

    //istr[len] = '\0';

    //fprintf(stdout, "GOT %d: [%s]\n", i, istr);

    i++;
  }

}
