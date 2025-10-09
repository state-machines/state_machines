// Released under the MIT License.
// Copyright, 2025, by Samuel Williams.

#pragma once

#include <ruby.h>

VALUE IO_Event_Fiber_transfer(VALUE fiber, int argc, VALUE *argv);

#ifdef HAVE__RB_FIBER_RAISE
#define IO_Event_Fiber_raise(fiber, argc, argv) rb_fiber_raise(fiber, argc, argv)
#else
VALUE IO_Event_Fiber_raise(VALUE fiber, int argc, VALUE *argv);
#endif

#ifdef HAVE_RB_FIBER_CURRENT
#define IO_Event_Fiber_current() rb_fiber_current()
#else
VALUE IO_Event_Fiber_current(void);
#endif

int IO_Event_Fiber_blocking(VALUE fiber);
void Init_IO_Event_Fiber(VALUE IO_Event);
