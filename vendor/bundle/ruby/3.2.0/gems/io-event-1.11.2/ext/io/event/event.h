// Released under the MIT License.
// Copyright, 2021-2025, by Samuel Williams.

#pragma once

#include <ruby.h>

void Init_IO_Event(void);

#ifdef HAVE_LIBURING_H
#include "selector/uring.h"
#endif

#ifdef HAVE_SYS_EPOLL_H
#include "selector/epoll.h"
#endif

#ifdef HAVE_SYS_EVENT_H
#include "selector/kqueue.h"
#endif

#ifdef HAVE_IO_EVENT_WORKER_POOL
#include "worker_pool.h"
#endif
