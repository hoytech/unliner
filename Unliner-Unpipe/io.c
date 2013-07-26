#include <sys/uio.h>
#include <assert.h>
#include <errno.h>

// for kill/getpid
#include <sys/types.h>
#include <signal.h>
#include <unistd.h>

#include "unpipe.h"

// FIXME: don't need these except for debug code
#include <stdio.h>
#include <string.h>

#define MAX(a,b) ((a) > (b) ? (a) : (b))
#define MIN(a,b) ((a) < (b) ? (a) : (b))



ssize_t unpipe_writev(struct unpipe_ctx *p, const struct iovec *iov, int iovcnt) {
  char *base;
  size_t bytes_avail, iov_len, amount_to_copy, total_copied=0;
  void *iov_base;

  base = ((char*) p) + p->base_offset;

  pthread_mutex_lock(&p->lock);

  next_iov:

  if (iovcnt > 0) {
    iov_len = iov[0].iov_len;
    iov_base = iov[0].iov_base;
  } else {
    iov_len = 0;
    iov_base = NULL;
  }
  iovcnt--;

  more_available:
//fprintf(stderr, "WRITEV LOCKED\n");

  if (p->r_closed) {
    pthread_mutex_unlock(&p->lock);
    kill(getpid(), 13); // SIGPIPE to self
    errno = EPIPE;
    return -1;
  }

  bytes_avail = p->size - p->count;

  while ((iovcnt > 0 || iov_len > 0) && bytes_avail > 0) {
    amount_to_copy = MIN(MIN(bytes_avail,
                             p->size - p->head),
                             iov_len);

//fprintf(stderr, "memcpy(%p, %p, %d)\n", base + p->head, iov_base, amount_to_copy);
    memcpy(base + p->head, iov_base, amount_to_copy);

    iov_len -= amount_to_copy;
    iov_base += amount_to_copy;
    total_copied += amount_to_copy;
    p->count += amount_to_copy;
    bytes_avail -= amount_to_copy;
    p->head += amount_to_copy;

    if (p->head == p->size) {
      p->head = 0;
    }

    if (iov_len == 0) {
      iov++;
      goto next_iov;
    }
  }

  if (bytes_avail == 0) {
//fprintf(stderr, "WRITEV CW\n");
    pthread_cond_wait(&p->w_cv, &p->lock);
    goto more_available;
  }

  pthread_cond_signal(&p->r_cv);

//fprintf(stderr, "WRITEV UNLOCK %d\n", total_copied);
  pthread_mutex_unlock(&p->lock);

  return (ssize_t) total_copied;
}





ssize_t unpipe_readv(struct unpipe_ctx *p, const struct iovec *iov, int iovcnt) {
  char *base;
  size_t bytes_avail, iov_len=0, amount_to_copy, total_copied=0;
  void *iov_base = NULL;

//fprintf(stderr, "DOING READV\n");
  base = ((char*) p) + p->base_offset;

  pthread_mutex_lock(&p->lock);

  more_available:
//fprintf(stderr, "READV LOCKED\n");

  bytes_avail = p->count;
//fprintf(stderr, "READV COUNT = %ld\n", bytes_avail);

  if (bytes_avail == 0) {
    if (p->w_closed) {
      pthread_mutex_unlock(&p->lock);
      return 0;
    }

//fprintf(stderr, "READV CW\n");
    pthread_cond_wait(&p->r_cv, &p->lock);
    goto more_available;
  }

  next_iov:

  if (iov_len == 0 && iovcnt > 0) {
    iov_len = iov[0].iov_len;
    iov_base = iov[0].iov_base;
    iovcnt--;
  }

  while ((iovcnt > 0 || iov_len > 0) && bytes_avail > 0) {
    amount_to_copy = MIN(MIN(bytes_avail,
                             p->size - p->tail),
                             iov_len);

    memcpy(iov_base, base + p->tail, amount_to_copy);

    iov_len -= amount_to_copy;
    iov_base += amount_to_copy;
    total_copied += amount_to_copy;
    p->count -= amount_to_copy;
    bytes_avail -= amount_to_copy;

    p->tail += amount_to_copy;

    if (p->tail == p->size) {
      p->tail = 0;
    }

    if (iov_len == 0) {
      iov++;
      goto next_iov;
    }
  }

  pthread_cond_signal(&p->w_cv);

//fprintf(stderr, "READV UNLOCK (%d)\n", total_copied);
  pthread_mutex_unlock(&p->lock);

  return (ssize_t) total_copied;
}
