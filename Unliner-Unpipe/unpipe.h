#ifndef _UNPIPE_H_INCLUDED
#define _UNPIPE_H_INCLUDED

#include <sys/types.h>
#include <sys/uio.h>
#include <pthread.h>

struct unpipe_ctx {
  // Immutable
  int id;
  size_t size;
  size_t base_offset;

  // IPC
  pthread_cond_t r_cv;
  pthread_cond_t w_cv;
  pthread_mutex_t lock;

  // Mutex protected
  int r_ref_count;
  int w_ref_count;
  int r_closed;
  int w_closed;
  size_t head;
  size_t tail;
  size_t count;
};

int unpipe_create(int size_log2);
int unpipe_destroy(struct unpipe_ctx *p);
struct unpipe_ctx *unpipe_connect(int id, int mode);
int unpipe_disconnect(struct unpipe_ctx *p, int mode);

int unpipe_install(int id, int fd, int mode);
int unpipe_uninstall(int fd);
ssize_t unpipe_writev(struct unpipe_ctx *p, const struct iovec *iov, int iovcnt);
ssize_t unpipe_readv(struct unpipe_ctx *p, const struct iovec *iov, int iovcnt);

#endif
