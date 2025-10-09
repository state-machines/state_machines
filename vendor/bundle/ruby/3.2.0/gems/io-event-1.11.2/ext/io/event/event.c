// Released under the MIT License.
// Copyright, 2021-2025, by Samuel Williams.

#include "event.h"
#include "fiber.h"
#include "selector/selector.h"

void Init_IO_Event(void)
{
#ifdef HAVE_RB_EXT_RACTOR_SAFE
	rb_ext_ractor_safe(true);
#endif
	
	VALUE IO_Event = rb_define_module_under(rb_cIO, "Event");
	
	Init_IO_Event_Fiber(IO_Event);

	#ifdef HAVE_IO_EVENT_WORKER_POOL
	Init_IO_Event_WorkerPool(IO_Event);
	#endif

	VALUE IO_Event_Selector = rb_define_module_under(IO_Event, "Selector");
	Init_IO_Event_Selector(IO_Event_Selector);
	
	#ifdef IO_EVENT_SELECTOR_URING
	Init_IO_Event_Selector_URing(IO_Event_Selector);
	#endif
	
	#ifdef IO_EVENT_SELECTOR_EPOLL
	Init_IO_Event_Selector_EPoll(IO_Event_Selector);
	#endif
	
	#ifdef IO_EVENT_SELECTOR_KQUEUE
	Init_IO_Event_Selector_KQueue(IO_Event_Selector);
	#endif
}
