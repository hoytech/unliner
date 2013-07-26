#include <sys/ipc.h>
#include <sys/shm.h>
#include <unistd.h>
#include <assert.h>

#include "unpipe.h"

// FIXME: don't need these except for debug code
#include <stdio.h>
#include <string.h>



int unpipe_create(int size_log2) {
  int id;
  long pagesize;
  struct unpipe_ctx *p;
  pthread_mutexattr_t m_attr;
  pthread_condattr_t c_attr_r;
  pthread_condattr_t c_attr_w;

  pagesize = sysconf(_SC_PAGESIZE);
  assert(sizeof(struct unpipe_ctx *) < pagesize);

  id = shmget(IPC_PRIVATE, pagesize + (1<<size_log2), 0644 | IPC_CREAT);
  if (id == -1) return id;

  p = shmat(id, NULL, 0); // FIXME: error check

  memset(p, '\0', sizeof(struct unpipe_ctx));

  p->id = id;
  p->size = 1<<size_log2;
  p->base_offset = pagesize;

  pthread_mutexattr_init(&m_attr);
  pthread_condattr_init(&c_attr_r);
  pthread_condattr_init(&c_attr_w);

  pthread_mutexattr_setpshared(&m_attr, PTHREAD_PROCESS_SHARED);
  pthread_condattr_setpshared(&c_attr_r, PTHREAD_PROCESS_SHARED);
  pthread_condattr_setpshared(&c_attr_w, PTHREAD_PROCESS_SHARED);

  pthread_mutex_init(&p->lock, &m_attr);
  pthread_cond_init(&p->r_cv, &c_attr_r);
  pthread_cond_init(&p->w_cv, &c_attr_w);

  shmdt(p); // FIXME: error check

  return id;
}





// FIXME: manage ref count

struct unpipe_ctx *unpipe_connect(int id, int mode) {
  struct unpipe_ctx *p;
  p = shmat(id, NULL, 0); // FIXME: error check

  pthread_mutex_lock(&p->lock);

  if (mode == 0) {
    p->r_ref_count++;
  } else if (mode == 1) {
    p->w_ref_count++;
  }

  pthread_mutex_unlock(&p->lock);

  return p;
}

int unpipe_disconnect(struct unpipe_ctx *p, int mode) {
  pthread_mutex_lock(&p->lock);

  if (mode == 0) {
    p->r_ref_count--;

    if (p->r_ref_count == 0) {
      p->r_closed = 1;
      pthread_cond_signal(&p->w_cv);
    }
  } else if (mode == 1) {
    p->w_ref_count--;

    if (p->w_ref_count == 0) {
      p->w_closed = 1;
      pthread_cond_signal(&p->r_cv);
    }
  }

  pthread_mutex_unlock(&p->lock);

  return shmdt(p);
}





int unpipe_destroy(struct unpipe_ctx *p) {
  pthread_mutex_lock(&p->lock);

  shmctl(p->id, IPC_RMID, NULL); // FIXME: error check

  // FIXME: set closed and trigger cond vars

  pthread_mutex_unlock(&p->lock);

  return 0;
}
