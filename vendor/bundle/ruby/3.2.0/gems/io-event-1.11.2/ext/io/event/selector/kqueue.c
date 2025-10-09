// Released under the MIT License.
// Copyright, 2021-2025, by Samuel Williams.

#include "kqueue.h"
#include "selector.h"
#include "../list.h"
#include "../array.h"

#include <sys/event.h>
#include <sys/ioctl.h>
#include <time.h>
#include <errno.h>
#include <sys/wait.h>
#include <signal.h>

#include "../interrupt.h"

enum {
	DEBUG = 0,
	DEBUG_IO_READ = 0,
	DEBUG_IO_WRITE = 0,
	DEBUG_IO_WAIT = 0
};

#ifndef EVFILT_USER
#define IO_EVENT_SELECTOR_KQUEUE_USE_INTERRUPT
#endif

enum {KQUEUE_MAX_EVENTS = 64};

// This represents an actual fiber waiting for a specific event.
struct IO_Event_Selector_KQueue_Waiting
{
	struct IO_Event_List list;
	
	// The events the fiber is waiting for.
	enum IO_Event events;
	
	// The events that are currently ready.
	enum IO_Event ready;
	
	// The fiber value itself.
	VALUE fiber;
};

struct IO_Event_Selector_KQueue
{
	struct IO_Event_Selector backend;
	int descriptor;
	
	// Flag indicating whether the selector is currently blocked in a system call.
	// Set to 1 when blocked in kevent() without GVL, 0 otherwise.
	// Used by wakeup() to determine if an interrupt signal is needed.
	int blocked;
	
	struct timespec idle_duration;
	
#ifdef IO_EVENT_SELECTOR_KQUEUE_USE_INTERRUPT
	struct IO_Event_Interrupt interrupt;
#endif
	struct IO_Event_Array descriptors;
};

// This represents zero or more fibers waiting for a specific descriptor.
struct IO_Event_Selector_KQueue_Descriptor
{
	struct IO_Event_List list;
	
	// The union of all events we are waiting for:
	enum IO_Event waiting_events;
	
	// The union of events we are registered for:
	enum IO_Event registered_events;
	
	// The events that are currently ready:
	enum IO_Event ready_events;
};

static
void IO_Event_Selector_KQueue_Waiting_mark(struct IO_Event_List *_waiting)
{
	struct IO_Event_Selector_KQueue_Waiting *waiting = (void*)_waiting;
	
	if (waiting->fiber) {
		rb_gc_mark_movable(waiting->fiber);
	}
}

static
void IO_Event_Selector_KQueue_Descriptor_mark(void *_descriptor)
{
	struct IO_Event_Selector_KQueue_Descriptor *descriptor = _descriptor;
	
	IO_Event_List_immutable_each(&descriptor->list, IO_Event_Selector_KQueue_Waiting_mark);
}

static
void IO_Event_Selector_KQueue_Type_mark(void *_selector)
{
	struct IO_Event_Selector_KQueue *selector = _selector;
	IO_Event_Selector_mark(&selector->backend);
	IO_Event_Array_each(&selector->descriptors, IO_Event_Selector_KQueue_Descriptor_mark);
}

static
void IO_Event_Selector_KQueue_Waiting_compact(struct IO_Event_List *_waiting)
{
	struct IO_Event_Selector_KQueue_Waiting *waiting = (void*)_waiting;
	
	if (waiting->fiber) {
		waiting->fiber = rb_gc_location(waiting->fiber);
	}
}

static
void IO_Event_Selector_KQueue_Descriptor_compact(void *_descriptor)
{
	struct IO_Event_Selector_KQueue_Descriptor *descriptor = _descriptor;
	
	IO_Event_List_immutable_each(&descriptor->list, IO_Event_Selector_KQueue_Waiting_compact);
}

static
void IO_Event_Selector_KQueue_Type_compact(void *_selector)
{
	struct IO_Event_Selector_KQueue *selector = _selector;
	IO_Event_Selector_compact(&selector->backend);
	IO_Event_Array_each(&selector->descriptors, IO_Event_Selector_KQueue_Descriptor_compact);
}

static
void close_internal(struct IO_Event_Selector_KQueue *selector)
{
	if (selector->descriptor >= 0) {
		close(selector->descriptor);
		selector->descriptor = -1;
	}
}

static
void IO_Event_Selector_KQueue_Type_free(void *_selector)
{
	struct IO_Event_Selector_KQueue *selector = _selector;
	
	close_internal(selector);
	
	IO_Event_Array_free(&selector->descriptors);
	
	free(selector);
}

static
size_t IO_Event_Selector_KQueue_Type_size(const void *_selector)
{
	const struct IO_Event_Selector_KQueue *selector = _selector;
	
	return sizeof(struct IO_Event_Selector_KQueue)
		+ IO_Event_Array_memory_size(&selector->descriptors)
	;
}

static const rb_data_type_t IO_Event_Selector_KQueue_Type = {
	.wrap_struct_name = "IO::Event::Backend::KQueue",
	.function = {
		.dmark = IO_Event_Selector_KQueue_Type_mark,
		.dcompact = IO_Event_Selector_KQueue_Type_compact,
		.dfree = IO_Event_Selector_KQueue_Type_free,
		.dsize = IO_Event_Selector_KQueue_Type_size,
	},
	.data = NULL,
	.flags = RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

inline static
struct IO_Event_Selector_KQueue_Descriptor * IO_Event_Selector_KQueue_Descriptor_lookup(struct IO_Event_Selector_KQueue *selector, uintptr_t descriptor)
{
	struct IO_Event_Selector_KQueue_Descriptor *kqueue_descriptor = IO_Event_Array_lookup(&selector->descriptors, descriptor);
	
	if (!kqueue_descriptor) {
		rb_sys_fail("IO_Event_Selector_KQueue_Descriptor_lookup:IO_Event_Array_lookup");
	}
	
	return kqueue_descriptor;
}

inline static
enum IO_Event events_from_kevent_filter(int filter)
{
	switch (filter) {
		case EVFILT_READ:
			return IO_EVENT_READABLE;
		case EVFILT_WRITE:
			return IO_EVENT_WRITABLE;
		case EVFILT_PROC:
			return IO_EVENT_EXIT;
		default:
			return 0;
	}
}

inline static
int IO_Event_Selector_KQueue_Descriptor_update(struct IO_Event_Selector_KQueue *selector, uintptr_t identifier, struct IO_Event_Selector_KQueue_Descriptor *kqueue_descriptor)
{
	int count = 0;
	struct kevent kevents[3] = {0};
	
	if (kqueue_descriptor->waiting_events & IO_EVENT_READABLE) {
		kevents[count].ident = identifier;
		kevents[count].filter = EVFILT_READ;
		kevents[count].flags = EV_ADD | EV_ONESHOT;
		kevents[count].udata = (void *)kqueue_descriptor;
// #ifdef EV_OOBAND
// 		if (events & IO_EVENT_PRIORITY) {
// 			kevents[count].flags |= EV_OOBAND;
// 		}
// #endif
		count++;
	}
	
	if (kqueue_descriptor->waiting_events & IO_EVENT_WRITABLE) {
		kevents[count].ident = identifier;
		kevents[count].filter = EVFILT_WRITE;
		kevents[count].flags = EV_ADD | EV_ONESHOT;
		kevents[count].udata = (void *)kqueue_descriptor;
		count++;
	}
	
	if (kqueue_descriptor->waiting_events & IO_EVENT_EXIT) {
		kevents[count].ident = identifier;
		kevents[count].filter = EVFILT_PROC;
		kevents[count].flags = EV_ADD | EV_ONESHOT;
		kevents[count].fflags = NOTE_EXIT;
		kevents[count].udata = (void *)kqueue_descriptor;
		count++;
	}
	
	if (count == 0) {
		return 0;
	}
	
	int result = kevent(selector->descriptor, kevents, count, NULL, 0, NULL);
	
	if (result == -1) {
		return result;
	}
	
	kqueue_descriptor->registered_events = kqueue_descriptor->waiting_events;
	
	return result;
}

inline static
int IO_Event_Selector_KQueue_Waiting_register(struct IO_Event_Selector_KQueue *selector, uintptr_t identifier, struct IO_Event_Selector_KQueue_Waiting *waiting)
{
	struct IO_Event_Selector_KQueue_Descriptor *kqueue_descriptor = IO_Event_Selector_KQueue_Descriptor_lookup(selector, identifier);
	
	// We are waiting for these events:
	kqueue_descriptor->waiting_events |= waiting->events;
	
	int result = IO_Event_Selector_KQueue_Descriptor_update(selector, identifier, kqueue_descriptor);
	if (result == -1) return -1;
	
	IO_Event_List_prepend(&kqueue_descriptor->list, &waiting->list);
	
	return result;
}

inline static
void IO_Event_Selector_KQueue_Waiting_cancel(struct IO_Event_Selector_KQueue_Waiting *waiting)
{
	IO_Event_List_pop(&waiting->list);
	waiting->fiber = 0;
}

void IO_Event_Selector_KQueue_Descriptor_initialize(void *element)
{
	struct IO_Event_Selector_KQueue_Descriptor *kqueue_descriptor = element;
	IO_Event_List_initialize(&kqueue_descriptor->list);
	kqueue_descriptor->waiting_events = 0;
	kqueue_descriptor->registered_events = 0;
	kqueue_descriptor->ready_events = 0;
}

void IO_Event_Selector_KQueue_Descriptor_free(void *element)
{
	struct IO_Event_Selector_KQueue_Descriptor *kqueue_descriptor = element;
	
	IO_Event_List_free(&kqueue_descriptor->list);
}

VALUE IO_Event_Selector_KQueue_allocate(VALUE self) {
	struct IO_Event_Selector_KQueue *selector = NULL;
	VALUE instance = TypedData_Make_Struct(self, struct IO_Event_Selector_KQueue, &IO_Event_Selector_KQueue_Type, selector);
	
	IO_Event_Selector_initialize(&selector->backend, self, Qnil);
	selector->descriptor = -1;
	selector->blocked = 0;
	
	selector->descriptors.element_initialize = IO_Event_Selector_KQueue_Descriptor_initialize;
	selector->descriptors.element_free = IO_Event_Selector_KQueue_Descriptor_free;
	
	int result = IO_Event_Array_initialize(&selector->descriptors, IO_EVENT_ARRAY_DEFAULT_COUNT, sizeof(struct IO_Event_Selector_KQueue_Descriptor));
	if (result < 0) {
		rb_sys_fail("IO_Event_Selector_KQueue_allocate:IO_Event_Array_initialize");
	}
	
	return instance;
}

#ifdef IO_EVENT_SELECTOR_KQUEUE_USE_INTERRUPT
void IO_Event_Interrupt_add(struct IO_Event_Interrupt *interrupt, struct IO_Event_Selector_KQueue *selector) {
	int descriptor = IO_Event_Interrupt_descriptor(interrupt);
	
	struct kevent kev = {
		.filter = EVFILT_READ,
		.ident = descriptor,
		.flags = EV_ADD | EV_CLEAR,
	};
	
	int result = kevent(selector->descriptor, &kev, 1, NULL, 0, NULL);
	
	if (result == -1) {
		rb_sys_fail("IO_Event_Interrupt_add:kevent");
	}
}
#endif

VALUE IO_Event_Selector_KQueue_initialize(VALUE self, VALUE loop) {
	struct IO_Event_Selector_KQueue *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_KQueue, &IO_Event_Selector_KQueue_Type, selector);
	
	IO_Event_Selector_initialize(&selector->backend, self, loop);
	int result = kqueue();
	
	if (result == -1) {
		rb_sys_fail("IO_Event_Selector_KQueue_initialize:kqueue");
	} else {
		// Make sure the descriptor is closed on exec.
		ioctl(result, FIOCLEX);
		
		selector->descriptor = result;
		
		rb_update_max_fd(selector->descriptor);
	}
	
#ifdef IO_EVENT_SELECTOR_KQUEUE_USE_INTERRUPT
	IO_Event_Interrupt_open(&selector->interrupt);
	IO_Event_Interrupt_add(&selector->interrupt, selector);
#endif
	
	return self;
}

VALUE IO_Event_Selector_KQueue_loop(VALUE self) {
	struct IO_Event_Selector_KQueue *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_KQueue, &IO_Event_Selector_KQueue_Type, selector);
	
	return selector->backend.loop;
}

VALUE IO_Event_Selector_KQueue_idle_duration(VALUE self) {
	struct IO_Event_Selector_KQueue *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_KQueue, &IO_Event_Selector_KQueue_Type, selector);
	
	double duration = selector->idle_duration.tv_sec + (selector->idle_duration.tv_nsec / 1000000000.0);
	
	return DBL2NUM(duration);
}

VALUE IO_Event_Selector_KQueue_close(VALUE self) {
	struct IO_Event_Selector_KQueue *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_KQueue, &IO_Event_Selector_KQueue_Type, selector);
	
	close_internal(selector);
	
#ifdef IO_EVENT_SELECTOR_KQUEUE_USE_INTERRUPT
	IO_Event_Interrupt_close(&selector->interrupt);
#endif
	
	return Qnil;
}

VALUE IO_Event_Selector_KQueue_transfer(VALUE self)
{
	struct IO_Event_Selector_KQueue *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_KQueue, &IO_Event_Selector_KQueue_Type, selector);
	
	return IO_Event_Selector_loop_yield(&selector->backend);
}

VALUE IO_Event_Selector_KQueue_resume(int argc, VALUE *argv, VALUE self)
{
	struct IO_Event_Selector_KQueue *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_KQueue, &IO_Event_Selector_KQueue_Type, selector);
	
	return IO_Event_Selector_resume(&selector->backend, argc, argv);
}

VALUE IO_Event_Selector_KQueue_yield(VALUE self)
{
	struct IO_Event_Selector_KQueue *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_KQueue, &IO_Event_Selector_KQueue_Type, selector);
	
	return IO_Event_Selector_yield(&selector->backend);
}

VALUE IO_Event_Selector_KQueue_push(VALUE self, VALUE fiber)
{
	struct IO_Event_Selector_KQueue *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_KQueue, &IO_Event_Selector_KQueue_Type, selector);
	
	IO_Event_Selector_ready_push(&selector->backend, fiber);
	
	return Qnil;
}

VALUE IO_Event_Selector_KQueue_raise(int argc, VALUE *argv, VALUE self)
{
	struct IO_Event_Selector_KQueue *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_KQueue, &IO_Event_Selector_KQueue_Type, selector);
	
	return IO_Event_Selector_raise(&selector->backend, argc, argv);
}

VALUE IO_Event_Selector_KQueue_ready_p(VALUE self) {
	struct IO_Event_Selector_KQueue *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_KQueue, &IO_Event_Selector_KQueue_Type, selector);
	
	return selector->backend.ready ? Qtrue : Qfalse;
}

struct process_wait_arguments {
	struct IO_Event_Selector_KQueue *selector;
	struct IO_Event_Selector_KQueue_Waiting *waiting;
	pid_t pid;
	int flags;
};

static
void process_prewait(pid_t pid) {
#if defined(WNOWAIT)
	// FreeBSD seems to have an issue where kevent() can return an EVFILT_PROC/NOTE_EXIT event for a process even though a wait with WNOHANG on it immediately after will not return it (but it does after a small delay). Similarly, OpenBSD/NetBSD seem to sometimes fail the kevent() call with ESRCH (indicating the process has already terminated) even though a WNOHANG may not return it immediately after.
	// To deal with this, do a hanging WNOWAIT wait on the process to make sure it is "terminated enough" for future WNOHANG waits to return it.
	// Using waitid() for this because OpenBSD only supports WNOWAIT with waitid().
	int result;
	do {
		siginfo_t info;
		result = waitid(P_PID, pid, &info, WEXITED | WNOWAIT);
		// This can sometimes get interrupted by SIGCHLD.
	} while (result == -1 && errno == EINTR);
	
	if (result == -1) {
		rb_sys_fail("process_prewait:waitid");
	}
#endif
}

static
VALUE process_wait_transfer(VALUE _arguments) {
	struct process_wait_arguments *arguments = (struct process_wait_arguments *)_arguments;
	
	IO_Event_Selector_loop_yield(&arguments->selector->backend);
	
	if (arguments->waiting->ready) {
		process_prewait(arguments->pid);
		return IO_Event_Selector_process_status_wait(arguments->pid, arguments->flags);
	} else {
		return Qfalse;
	}
}

static
VALUE process_wait_ensure(VALUE _arguments) {
	struct process_wait_arguments *arguments = (struct process_wait_arguments *)_arguments;
	
	IO_Event_Selector_KQueue_Waiting_cancel(arguments->waiting);
	
	return Qnil;
}

struct IO_Event_List_Type IO_Event_Selector_KQueue_process_wait_list_type = {};

VALUE IO_Event_Selector_KQueue_process_wait(VALUE self, VALUE fiber, VALUE _pid, VALUE _flags) {
	struct IO_Event_Selector_KQueue *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_KQueue, &IO_Event_Selector_KQueue_Type, selector);
	
	pid_t pid = NUM2PIDT(_pid);
	int flags = NUM2INT(_flags);
	
	struct IO_Event_Selector_KQueue_Waiting waiting = {
		.list = {.type = &IO_Event_Selector_KQueue_process_wait_list_type},
		.fiber = fiber,
		.events = IO_EVENT_EXIT,
	};
	
	RB_OBJ_WRITTEN(self, Qundef, fiber);
	
	struct process_wait_arguments process_wait_arguments = {
		.selector = selector,
		.waiting = &waiting,
		.pid = pid,
		.flags = flags,
	};
	
	int result = IO_Event_Selector_KQueue_Waiting_register(selector, pid, &waiting);
	if (result == -1) {
		// OpenBSD/NetBSD return ESRCH when attempting to register an EVFILT_PROC event for a zombie process.
		if (errno == ESRCH) {
			process_prewait(pid);
			
			return IO_Event_Selector_process_status_wait(pid, flags);
		}
		
		rb_sys_fail("IO_Event_Selector_KQueue_process_wait:IO_Event_Selector_KQueue_Waiting_register");
	}
	
	return rb_ensure(process_wait_transfer, (VALUE)&process_wait_arguments, process_wait_ensure, (VALUE)&process_wait_arguments);
}

struct io_wait_arguments {
	struct IO_Event_Selector_KQueue *selector;
	struct IO_Event_Selector_KQueue_Waiting *waiting;
};

static
VALUE io_wait_ensure(VALUE _arguments) {
	struct io_wait_arguments *arguments = (struct io_wait_arguments *)_arguments;
	
	IO_Event_Selector_KQueue_Waiting_cancel(arguments->waiting);
	
	return Qnil;
}

static
VALUE io_wait_transfer(VALUE _arguments) {
	struct io_wait_arguments *arguments = (struct io_wait_arguments *)_arguments;
	
	IO_Event_Selector_loop_yield(&arguments->selector->backend);
	
	if (arguments->waiting->ready) {
		return RB_INT2NUM(arguments->waiting->ready);
	} else {
		return Qfalse;
	}
}

struct IO_Event_List_Type IO_Event_Selector_KQueue_io_wait_list_type = {};

VALUE IO_Event_Selector_KQueue_io_wait(VALUE self, VALUE fiber, VALUE io, VALUE events) {
	struct IO_Event_Selector_KQueue *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_KQueue, &IO_Event_Selector_KQueue_Type, selector);
	
	int descriptor = IO_Event_Selector_io_descriptor(io);
	
	struct IO_Event_Selector_KQueue_Waiting waiting = {
		.list = {.type = &IO_Event_Selector_KQueue_io_wait_list_type},
		.fiber = fiber,
		.events = RB_NUM2INT(events),
	};
	
	RB_OBJ_WRITTEN(self, Qundef, fiber);
	
	int result = IO_Event_Selector_KQueue_Waiting_register(selector, descriptor, &waiting);
	if (result == -1) {
		rb_sys_fail("IO_Event_Selector_KQueue_io_wait:IO_Event_Selector_KQueue_Waiting_register");
	}
	
	struct io_wait_arguments io_wait_arguments = {
		.selector = selector,
		.waiting = &waiting,
	};
	
	if (DEBUG_IO_WAIT) fprintf(stderr, "IO_Event_Selector_KQueue_io_wait descriptor=%d\n", descriptor);
	
	return rb_ensure(io_wait_transfer, (VALUE)&io_wait_arguments, io_wait_ensure, (VALUE)&io_wait_arguments);
}

#ifdef HAVE_RUBY_IO_BUFFER_H

struct io_read_arguments {
	VALUE self;
	VALUE fiber;
	VALUE io;
	
	int flags;
	
	int descriptor;
	
	VALUE buffer;
	size_t length;
	size_t offset;
};

static
VALUE io_read_loop(VALUE _arguments) {
	struct io_read_arguments *arguments = (struct io_read_arguments *)_arguments;
	
	void *base;
	size_t size;
	rb_io_buffer_get_bytes_for_writing(arguments->buffer, &base, &size);
	
	size_t length = arguments->length;
	size_t offset = arguments->offset;
	size_t total = 0;
	
	if (DEBUG_IO_READ) fprintf(stderr, "io_read_loop(fd=%d, length=%zu)\n", arguments->descriptor, length);
	
	size_t maximum_size = size - offset;
	while (maximum_size) {
		if (DEBUG_IO_READ) fprintf(stderr, "read(%d, +%ld, %ld)\n", arguments->descriptor, offset, maximum_size);
		ssize_t result = read(arguments->descriptor, (char*)base+offset, maximum_size);
		if (DEBUG_IO_READ) fprintf(stderr, "read(%d, +%ld, %ld) -> %zd\n", arguments->descriptor, offset, maximum_size, result);
		
		if (result > 0) {
			total += result;
			offset += result;
			if ((size_t)result >= length) break;
			length -= result;
		} else if (result == 0) {
			break;
		} else if (length > 0 && IO_Event_try_again(errno)) {
			if (DEBUG_IO_READ) fprintf(stderr, "IO_Event_Selector_KQueue_io_wait(fd=%d, length=%zu)\n", arguments->descriptor, length);
			IO_Event_Selector_KQueue_io_wait(arguments->self, arguments->fiber, arguments->io, RB_INT2NUM(IO_EVENT_READABLE));
		} else {
			if (DEBUG_IO_READ) fprintf(stderr, "io_read_loop(fd=%d, length=%zu) -> errno=%d\n", arguments->descriptor, length, errno);
			return rb_fiber_scheduler_io_result(-1, errno);
		}
		
		maximum_size = size - offset;
	}
	
	if (DEBUG_IO_READ) fprintf(stderr, "io_read_loop(fd=%d, length=%zu) -> %zu\n", arguments->descriptor, length, offset);
	return rb_fiber_scheduler_io_result(total, 0);
}

static
VALUE io_read_ensure(VALUE _arguments) {
	struct io_read_arguments *arguments = (struct io_read_arguments *)_arguments;
	
	IO_Event_Selector_nonblock_restore(arguments->descriptor, arguments->flags);
	
	return Qnil;
}

VALUE IO_Event_Selector_KQueue_io_read(VALUE self, VALUE fiber, VALUE io, VALUE buffer, VALUE _length, VALUE _offset) {
	struct IO_Event_Selector_KQueue *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_KQueue, &IO_Event_Selector_KQueue_Type, selector);
	
	int descriptor = IO_Event_Selector_io_descriptor(io);
	
	size_t length = NUM2SIZET(_length);
	size_t offset = NUM2SIZET(_offset);
	
	struct io_read_arguments io_read_arguments = {
		.self = self,
		.fiber = fiber,
		.io = io,
		
		.flags = IO_Event_Selector_nonblock_set(descriptor),
		.descriptor = descriptor,
		.buffer = buffer,
		.length = length,
		.offset = offset,
	};
	
	RB_OBJ_WRITTEN(self, Qundef, fiber);
	
	return rb_ensure(io_read_loop, (VALUE)&io_read_arguments, io_read_ensure, (VALUE)&io_read_arguments);
}

static VALUE IO_Event_Selector_KQueue_io_read_compatible(int argc, VALUE *argv, VALUE self)
{
	rb_check_arity(argc, 4, 5);
	
	VALUE _offset = SIZET2NUM(0);
	
	if (argc == 5) {
		_offset = argv[4];
	}
	
	return IO_Event_Selector_KQueue_io_read(self, argv[0], argv[1], argv[2], argv[3], _offset);
}

struct io_write_arguments {
	VALUE self;
	VALUE fiber;
	VALUE io;
	
	int flags;
	
	int descriptor;
	
	VALUE buffer;
	size_t length;
	size_t offset;
};

static
VALUE io_write_loop(VALUE _arguments) {
	struct io_write_arguments *arguments = (struct io_write_arguments *)_arguments;
	
	const void *base;
	size_t size;
	rb_io_buffer_get_bytes_for_reading(arguments->buffer, &base, &size);
	
	size_t length = arguments->length;
	size_t offset = arguments->offset;
	size_t total = 0;
	
	if (length > size) {
		rb_raise(rb_eRuntimeError, "Length exceeds size of buffer!");
	}
	
	if (DEBUG_IO_WRITE) fprintf(stderr, "io_write_loop(fd=%d, length=%zu)\n", arguments->descriptor, length);
	
	size_t maximum_size = size - offset;
	while (maximum_size) {
		if (DEBUG_IO_WRITE) fprintf(stderr, "write(%d, +%ld, %ld, length=%zu)\n", arguments->descriptor, offset, maximum_size, length);
		ssize_t result = write(arguments->descriptor, (char*)base+offset, maximum_size);
		if (DEBUG_IO_WRITE) fprintf(stderr, "write(%d, +%ld, %ld) -> %zd\n", arguments->descriptor, offset, maximum_size, result);
		
		if (result > 0) {
			total += result;
			offset += result;
			if ((size_t)result >= length) break;
			length -= result;
		} else if (result == 0) {
			break;
		} else if (length > 0 && IO_Event_try_again(errno)) {
			if (DEBUG_IO_WRITE) fprintf(stderr, "IO_Event_Selector_KQueue_io_wait(fd=%d, length=%zu)\n", arguments->descriptor, length);
			IO_Event_Selector_KQueue_io_wait(arguments->self, arguments->fiber, arguments->io, RB_INT2NUM(IO_EVENT_READABLE));
		} else {
			if (DEBUG_IO_WRITE) fprintf(stderr, "io_write_loop(fd=%d, length=%zu) -> errno=%d\n", arguments->descriptor, length, errno);
			return rb_fiber_scheduler_io_result(-1, errno);
		}
		
		maximum_size = size - offset;
	}
	
	if (DEBUG_IO_READ) fprintf(stderr, "io_write_loop(fd=%d, length=%zu) -> %zu\n", arguments->descriptor, length, offset);
	return rb_fiber_scheduler_io_result(total, 0);
};

static
VALUE io_write_ensure(VALUE _arguments) {
	struct io_write_arguments *arguments = (struct io_write_arguments *)_arguments;
	
	IO_Event_Selector_nonblock_restore(arguments->descriptor, arguments->flags);
	
	return Qnil;
};

VALUE IO_Event_Selector_KQueue_io_write(VALUE self, VALUE fiber, VALUE io, VALUE buffer, VALUE _length, VALUE _offset) {
	struct IO_Event_Selector_KQueue *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_KQueue, &IO_Event_Selector_KQueue_Type, selector);
	
	int descriptor = IO_Event_Selector_io_descriptor(io);
	
	size_t length = NUM2SIZET(_length);
	size_t offset = NUM2SIZET(_offset);
	
	struct io_write_arguments io_write_arguments = {
		.self = self,
		.fiber = fiber,
		.io = io,
		
		.flags = IO_Event_Selector_nonblock_set(descriptor),
		.descriptor = descriptor,
		.buffer = buffer,
		.length = length,
		.offset = offset,
	};
	
	RB_OBJ_WRITTEN(self, Qundef, fiber);
	
	return rb_ensure(io_write_loop, (VALUE)&io_write_arguments, io_write_ensure, (VALUE)&io_write_arguments);
}

static VALUE IO_Event_Selector_KQueue_io_write_compatible(int argc, VALUE *argv, VALUE self)
{
	rb_check_arity(argc, 4, 5);
	
	VALUE _offset = SIZET2NUM(0);
	
	if (argc == 5) {
		_offset = argv[4];
	}
	
	return IO_Event_Selector_KQueue_io_write(self, argv[0], argv[1], argv[2], argv[3], _offset);
}

#endif

static
struct timespec * make_timeout(VALUE duration, struct timespec * storage) {
	if (duration == Qnil) {
		return NULL;
	}
	
	if (RB_INTEGER_TYPE_P(duration)) {
		storage->tv_sec = NUM2TIMET(duration);
		storage->tv_nsec = 0;
		
		return storage;
	}
	
	duration = rb_to_float(duration);
	double value = RFLOAT_VALUE(duration);
	time_t seconds = value;
	
	storage->tv_sec = seconds;
	storage->tv_nsec = (value - seconds) * 1000000000L;
	
	return storage;
}

static
int timeout_nonblocking(struct timespec * timespec) {
	return timespec && timespec->tv_sec == 0 && timespec->tv_nsec == 0;
}

struct select_arguments {
	struct IO_Event_Selector_KQueue *selector;
	
	int count;
	struct kevent events[KQUEUE_MAX_EVENTS];
	
	struct timespec storage;
	struct timespec *timeout;
	
	struct IO_Event_List saved;
};

static
void * select_internal(void *_arguments) {
	struct select_arguments * arguments = (struct select_arguments *)_arguments;
	
	arguments->count = kevent(arguments->selector->descriptor, NULL, 0, arguments->events, arguments->count, arguments->timeout);
	
	return NULL;
}

static
void select_internal_without_gvl(struct select_arguments *arguments) {
	arguments->selector->blocked = 1;
	
	rb_thread_call_without_gvl(select_internal, (void *)arguments, RUBY_UBF_IO, 0);
	arguments->selector->blocked = 0;
	
	if (arguments->count == -1) {
		if (errno != EINTR) {
			rb_sys_fail("select_internal_without_gvl:kevent");
		} else {
			arguments->count = 0;
		}
	}
}

static
void select_internal_with_gvl(struct select_arguments *arguments) {
	select_internal((void *)arguments);
	
	if (arguments->count == -1) {
		if (errno != EINTR) {
			rb_sys_fail("select_internal_with_gvl:kevent");
		} else {
			arguments->count = 0;
		}
	}
}

static
int IO_Event_Selector_KQueue_handle(struct IO_Event_Selector_KQueue *selector, uintptr_t identifier, struct IO_Event_Selector_KQueue_Descriptor *kqueue_descriptor, struct IO_Event_List *saved)
{
	// This is the mask of all events that occured for the given descriptor:
	enum IO_Event ready_events = kqueue_descriptor->ready_events;
	
	if (ready_events) {
		kqueue_descriptor->ready_events = 0;
		// Since we use one-shot semantics, we need to re-arm the events that are ready if needed:
		kqueue_descriptor->registered_events &= ~ready_events;
	} else {
		return 0;
	}
	
	struct IO_Event_List *list = &kqueue_descriptor->list;
	struct IO_Event_List *node = list->tail;
	
	// Reset the events back to 0 so that we can re-arm if necessary:
	kqueue_descriptor->waiting_events = 0;
	
	// It's possible (but unlikely) that the address of list will changing during iteration.
	while (node != list) {
		struct IO_Event_Selector_KQueue_Waiting *waiting = (struct IO_Event_Selector_KQueue_Waiting *)node;
		
		enum IO_Event matching_events = waiting->events & ready_events;
		
		if (DEBUG) fprintf(stderr, "IO_Event_Selector_KQueue_handle: identifier=%lu, ready_events=%d, matching_events=%d\n", identifier, ready_events, matching_events);
		
		if (matching_events) {
			IO_Event_List_append(node, saved);
			
			waiting->ready = matching_events;
			IO_Event_Selector_loop_resume(&selector->backend, waiting->fiber, 0, NULL);
			
			node = saved->tail;
			IO_Event_List_pop(saved);
		} else {
			kqueue_descriptor->waiting_events |= waiting->events;
			node = node->tail;
		}
	}
	
	return IO_Event_Selector_KQueue_Descriptor_update(selector, identifier, kqueue_descriptor);
}

static
VALUE select_handle_events(VALUE _arguments)
{
	struct select_arguments *arguments = (struct select_arguments *)_arguments;
	struct IO_Event_Selector_KQueue *selector = arguments->selector;
	
	for (int i = 0; i < arguments->count; i += 1) {
		if (arguments->events[i].udata) {
			struct IO_Event_Selector_KQueue_Descriptor *kqueue_descriptor = arguments->events[i].udata;
			kqueue_descriptor->ready_events |= events_from_kevent_filter(arguments->events[i].filter);
		}
	}
	
	for (int i = 0; i < arguments->count; i += 1) {
		if (arguments->events[i].udata) {
			struct IO_Event_Selector_KQueue_Descriptor *kqueue_descriptor = arguments->events[i].udata;
			IO_Event_Selector_KQueue_handle(selector, arguments->events[i].ident, kqueue_descriptor, &arguments->saved);
		} else {
#ifdef IO_EVENT_SELECTOR_KQUEUE_USE_INTERRUPT
			IO_Event_Interrupt_clear(&selector->interrupt);
#endif
		}
	}
	
	return RB_INT2NUM(arguments->count);
}

static
VALUE select_handle_events_ensure(VALUE _arguments)
{
	struct select_arguments *arguments = (struct select_arguments *)_arguments;
	
	IO_Event_List_free(&arguments->saved);
	
	return Qnil;
}

VALUE IO_Event_Selector_KQueue_select(VALUE self, VALUE duration) {
	struct IO_Event_Selector_KQueue *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_KQueue, &IO_Event_Selector_KQueue_Type, selector);
	
	selector->idle_duration.tv_sec = 0;
	selector->idle_duration.tv_nsec = 0;
	
	int ready = IO_Event_Selector_ready_flush(&selector->backend);
	
	struct select_arguments arguments = {
		.selector = selector,
		.count = KQUEUE_MAX_EVENTS,
		.storage = {
			.tv_sec = 0,
			.tv_nsec = 0
		},
		.saved = {},
	};
	
	arguments.timeout = &arguments.storage;
	
	// We break this implementation into two parts.
	// (1) count = kevent(..., timeout = 0)
	// (2) without gvl: kevent(..., timeout = 0) if count == 0 and timeout != 0
	// This allows us to avoid releasing and reacquiring the GVL.
	// Non-comprehensive testing shows this gives a 1.5x speedup.
	
	// First do the syscall with no timeout to get any immediately available events:
	if (DEBUG) fprintf(stderr, "\r\nselect_internal_with_gvl timeout=" IO_EVENT_TIME_PRINTF_TIMESPEC "\r\n", IO_EVENT_TIME_PRINTF_TIMESPEC_ARGUMENTS(arguments.storage));
	select_internal_with_gvl(&arguments);
	if (DEBUG) fprintf(stderr, "\r\nselect_internal_with_gvl done\r\n");
	
	// If we:
	// 1. Didn't process any ready fibers, and
	// 2. Didn't process any events from non-blocking select (above), and
	// 3. There are no items in the ready list,
	// then we can perform a blocking select.
	if (!ready && !arguments.count && !selector->backend.ready) {
		arguments.timeout = make_timeout(duration, &arguments.storage);
		
		if (!timeout_nonblocking(arguments.timeout)) {
			arguments.count = KQUEUE_MAX_EVENTS;
			
			struct timespec start_time;
			IO_Event_Time_current(&start_time);
			
			if (DEBUG) fprintf(stderr, "IO_Event_Selector_KQueue_select timeout=" IO_EVENT_TIME_PRINTF_TIMESPEC "\n", IO_EVENT_TIME_PRINTF_TIMESPEC_ARGUMENTS(arguments.storage));
			select_internal_without_gvl(&arguments);
			
			struct timespec end_time;
			IO_Event_Time_current(&end_time);
			IO_Event_Time_elapsed(&start_time, &end_time, &selector->idle_duration);
		}
	}
	
	if (arguments.count) {
		return rb_ensure(select_handle_events, (VALUE)&arguments, select_handle_events_ensure, (VALUE)&arguments);
	} else {
		return RB_INT2NUM(0);
	}
}

VALUE IO_Event_Selector_KQueue_wakeup(VALUE self) {
	struct IO_Event_Selector_KQueue *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_KQueue, &IO_Event_Selector_KQueue_Type, selector);
	
	if (selector->blocked) {
#ifdef IO_EVENT_SELECTOR_KQUEUE_USE_INTERRUPT
		IO_Event_Interrupt_signal(&selector->interrupt);
#else
		struct kevent trigger = {0};
		
		trigger.filter = EVFILT_USER;
		trigger.flags = EV_ADD | EV_CLEAR;
		
		int result = kevent(selector->descriptor, &trigger, 1, NULL, 0, NULL);
		
		if (result == -1) {
			rb_sys_fail("IO_Event_Selector_KQueue_wakeup:kevent");
		}
		
		// FreeBSD apparently only works if the NOTE_TRIGGER is done as a separate call.
		trigger.flags = 0;
		trigger.fflags = NOTE_TRIGGER;
		
		result = kevent(selector->descriptor, &trigger, 1, NULL, 0, NULL);
		
		if (result == -1) {
			rb_sys_fail("IO_Event_Selector_KQueue_wakeup:kevent");
		}
#endif
		
		return Qtrue;
	}
	
	return Qfalse;
}


static int IO_Event_Selector_KQueue_supported_p(void) {
	int fd = kqueue();
	
	if (fd < 0) {
		rb_warn("kqueue() was available at compile time but failed at run time: %s\n", strerror(errno));
		
		return 0;
	}
	
	close(fd);
	
	return 1;
}

void Init_IO_Event_Selector_KQueue(VALUE IO_Event_Selector) {
	if (!IO_Event_Selector_KQueue_supported_p()) {
		return;
	}
	
	VALUE IO_Event_Selector_KQueue = rb_define_class_under(IO_Event_Selector, "KQueue", rb_cObject);
	
	rb_define_alloc_func(IO_Event_Selector_KQueue, IO_Event_Selector_KQueue_allocate);
	rb_define_method(IO_Event_Selector_KQueue, "initialize", IO_Event_Selector_KQueue_initialize, 1);
	
	rb_define_method(IO_Event_Selector_KQueue, "loop", IO_Event_Selector_KQueue_loop, 0);
	rb_define_method(IO_Event_Selector_KQueue, "idle_duration", IO_Event_Selector_KQueue_idle_duration, 0);
	
	rb_define_method(IO_Event_Selector_KQueue, "transfer", IO_Event_Selector_KQueue_transfer, 0);
	rb_define_method(IO_Event_Selector_KQueue, "resume", IO_Event_Selector_KQueue_resume, -1);
	rb_define_method(IO_Event_Selector_KQueue, "yield", IO_Event_Selector_KQueue_yield, 0);
	rb_define_method(IO_Event_Selector_KQueue, "push", IO_Event_Selector_KQueue_push, 1);
	rb_define_method(IO_Event_Selector_KQueue, "raise", IO_Event_Selector_KQueue_raise, -1);
	
	rb_define_method(IO_Event_Selector_KQueue, "ready?", IO_Event_Selector_KQueue_ready_p, 0);
	
	rb_define_method(IO_Event_Selector_KQueue, "select", IO_Event_Selector_KQueue_select, 1);
	rb_define_method(IO_Event_Selector_KQueue, "wakeup", IO_Event_Selector_KQueue_wakeup, 0);
	rb_define_method(IO_Event_Selector_KQueue, "close", IO_Event_Selector_KQueue_close, 0);
	
	rb_define_method(IO_Event_Selector_KQueue, "io_wait", IO_Event_Selector_KQueue_io_wait, 3);
	
#ifdef HAVE_RUBY_IO_BUFFER_H
	rb_define_method(IO_Event_Selector_KQueue, "io_read", IO_Event_Selector_KQueue_io_read_compatible, -1);
	rb_define_method(IO_Event_Selector_KQueue, "io_write", IO_Event_Selector_KQueue_io_write_compatible, -1);
#endif
	
	rb_define_method(IO_Event_Selector_KQueue, "process_wait", IO_Event_Selector_KQueue_process_wait, 3);
}
