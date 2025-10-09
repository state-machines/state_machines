// Released under the MIT License.
// Copyright, 2025, by Samuel Williams.

#include "fiber.h"

static ID id_transfer, id_alive_p;

VALUE IO_Event_Fiber_transfer(VALUE fiber, int argc, VALUE *argv) {
	// TODO Consider introducing something like `rb_fiber_scheduler_transfer(...)`.
#ifdef HAVE__RB_FIBER_TRANSFER
	if (RTEST(rb_obj_is_fiber(fiber))) {
		if (RTEST(rb_fiber_alive_p(fiber))) {
			return rb_fiber_transfer(fiber, argc, argv);
		}
		
		// If it's a fiber, but dead, we are done.
		return Qnil;
	}
#endif
	if (RTEST(rb_funcall(fiber, id_alive_p, 0))) {
		return rb_funcallv(fiber, id_transfer, argc, argv);
	}
	
	return Qnil;
}

#ifndef HAVE__RB_FIBER_RAISE
static ID id_raise;

VALUE IO_Event_Fiber_raise(VALUE fiber, int argc, VALUE *argv) {
	return rb_funcallv(fiber, id_raise, argc, argv);
}
#endif

#ifndef HAVE_RB_FIBER_CURRENT
static ID id_current;

VALUE IO_Event_Fiber_current(void) {
	return rb_funcall(rb_cFiber, id_current, 0);
}
#endif

// There is no public interface for this... yet.
static ID id_blocking_p;

int IO_Event_Fiber_blocking(VALUE fiber) {
	return RTEST(rb_funcall(fiber, id_blocking_p, 0));
}

void Init_IO_Event_Fiber(VALUE IO_Event) {
	id_transfer = rb_intern("transfer");
	id_alive_p = rb_intern("alive?");
	
#ifndef HAVE__RB_FIBER_RAISE
	id_raise = rb_intern("raise");
#endif
	
#ifndef HAVE_RB_FIBER_CURRENT
	id_current = rb_intern("current");
#endif
	
	id_blocking_p = rb_intern("blocking?");
}
