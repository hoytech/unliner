#include <errno.h>

#include "unpipe.h"


// FIXME: don't need these except for debug code
#include <stdio.h>
#include <string.h>

// WTF glibc?
#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#ifndef __USE_GNU
#define __USE_GNU
#endif

// For dlsym, RTLD_NEXT
#include <dlfcn.h>

// For getenv
#include <stdlib.h>




#define MAX_FD 64

static int setup_done;
static ssize_t (*orig_write)(int, const void *, size_t);
static ssize_t (*orig_read)(int, const void *, size_t);
static int (*orig_close)(int);

static struct unpipe_ctx *fds_in_use[MAX_FD]; // FIXME: maybe make array of structs?
static int fd_modes[MAX_FD];



static void parse_unpipe_fd_env_var();
static void on_process_exit();
static void on_epipe(int signo);


void unpipe_setup() {
  if (setup_done) return;

  setup_done = 1;

  orig_write = dlsym(RTLD_NEXT, "write");
  orig_read = dlsym(RTLD_NEXT, "read");
  orig_close = dlsym(RTLD_NEXT, "close");

  atexit(on_process_exit); // FIXME: error check
  signal(13, on_epipe);

  parse_unpipe_fd_env_var();
}




int unpipe_install(int id, int fd, int mode) {
  int pipefd[2];
  int temp_fd;
  struct unpipe_ctx *p;

  if (fd < 0 || fd > MAX_FD) {
    return -1; // FIXME: errno
  }

  if (fds_in_use[fd] != NULL) {
    unpipe_uninstall(fd); // FIXME: error check
  }

  p = unpipe_connect(id, mode); // FIXME: error check

  fds_in_use[fd] = p;
  fd_modes[fd] = mode;

  if (pipe(&pipefd[0])) {
    return -1;
  }

  if (mode == 0) {
    temp_fd = pipefd[0];
    close(pipefd[1]);
  } else if (mode == 1) {
    temp_fd = pipefd[1];
    close(pipefd[0]);
  } else {
    return -1; // FIXME: set errno
  }

  if (fd != -1) {
    dup2(temp_fd, fd);
    close(temp_fd);
  }

  return 0;
}


int unpipe_uninstall(int fd) {
  struct unpipe_ctx *p;
  int mode;

  if (fd < 0 || fd > MAX_FD) {
    return -1; // FIXME: errno
  }

  p = fds_in_use[fd];
  mode = fd_modes[fd];

  if (p == NULL) {
    return -1; // FIXME: errno
  }

  unpipe_disconnect(p, mode); // FIXME: error check

  fds_in_use[fd] = NULL;

  return 0;
}



static void on_process_exit() {
  int i;

  for (i=0; i<MAX_FD; i++) {
    unpipe_uninstall(i);
  }
}


static void on_epipe(int signo) {
  on_process_exit();
  //_exit(-1);
  kill(getpid(), 15);
}



static void parse_unpipe_fd_env_var() {
  char *v = getenv("UNPIPE_FDS");
  char *p;
  long fd, id;
  struct unpipe_ctx *ctx;
  int rw_mode;

  if (!v) return;

  while (*v) {
    fd = strtol(v, &p, 10);

    if (*p == 'r') {
      rw_mode = 0;
    } else if (*p == 'w') {
      rw_mode = 1;
    } else {
      return;
    }
    v = p + 1;

    if (v[0] != '=') return;
    v++;

    id = strtol(v, &p, 10);

    if (p[0] != ',' && p[0] != '\0') return;
    if (p[0] == ',') p++;

    v = p;

    unpipe_install(id, (int) fd, rw_mode); // FIXME: error check, mode
  }
}




ssize_t write(int fd, const void *buf, size_t count) {
  struct iovec iov[1];

  if (!setup_done) unpipe_setup();

  if (fd >= 0 && fd < MAX_FD && fds_in_use[fd]) {
    iov[0].iov_base = (void *) buf;
    iov[0].iov_len = count;
    return unpipe_writev(fds_in_use[fd], &iov[0], 1);
  } else {
    return orig_write(fd, buf, count);
  }
}


ssize_t read(int fd, void *buf, size_t count) {
  struct iovec iov[1];

  if (!setup_done) unpipe_setup();

  if (fd >= 0 && fd < MAX_FD && fds_in_use[fd]) {
    iov[0].iov_base = buf;
    iov[0].iov_len = count;
    return unpipe_readv(fds_in_use[fd], &iov[0], 1);
  } else {
    return orig_read(fd, buf, count);
  }
}


int close(int fd) {
  if (setup_done) {
    unpipe_uninstall(fd); // FIXME: error check
  } else {
    if (!orig_close) orig_close = dlsym(RTLD_NEXT, "close");
  }

  orig_close(fd);
}
