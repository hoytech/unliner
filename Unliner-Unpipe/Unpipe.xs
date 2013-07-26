#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <unistd.h>

// FIXME: don't need
#include <stdio.h>
#include <string.h>
#include <errno.h>


#include "unpipe.h"




MODULE = Unliner::Unpipe		PACKAGE = Unliner::Unpipe

PROTOTYPES: ENABLE


int
unpipe_create_xs(size)
    int size
    CODE:
        int id;
        id = unpipe_create(size);
        if (id == -1) XSRETURN_UNDEF;
        RETVAL = id;

    OUTPUT:
        RETVAL



void
unpipe_destroy_xs(id)
    int id
    CODE:
        struct unpipe_ctx *ctx;
        ctx = unpipe_connect(id);
        unpipe_destroy(ctx);
        unpipe_disconnect(ctx);
