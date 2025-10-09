// Released under the MIT License.
// Copyright, 2021-2025, by Samuel Williams.

#include "uring.h"
#include "selector.h"
#include "../list.h"
#include "../array.h"

#include <liburing.h>
#include <poll.h>
#include <stdint.h>
#include <time.h>

#include "pidfd.c"

#include <linux/version.h>

enum {
	DEBUG = 0,
	DEBUG_COMPLETION = 0,
	DEBUG_CQE = 0,
};

enum {URING_ENTRIES = 64};

#pragma mark - Data Type

struct IO_Event_Selector_URing
{
	struct IO_Event_Selector backend;
	struct io_uring ring;
	size_t pending;
	
	// Flag indicating whether the selector is currently blocked in a system call.
	// Set to 1 when blocked in io_uring_wait_cqe_timeout() without GVL, 0 otherwise.
	// Used by wakeup() to determine if an interrupt signal is needed.
	int blocked;
	
	struct timespec idle_duration;
	
	struct IO_Event_Array completions;
	struct IO_Event_List free_list;
};

struct IO_Event_Selector_URing_Completion;

struct IO_Event_Selector_URing_Waiting
{
	struct IO_Event_Selector_URing_Completion *completion;
	
	VALUE fiber;
	
	// The result of the operation.
	int32_t	result;
	
	// Any associated flags.
	uint32_t flags;
};

struct IO_Event_Selector_URing_Completion
{
	struct IO_Event_List list;
	
	struct IO_Event_Selector_URing_Waiting *waiting;
};

static
void IO_Event_Selector_URing_Completion_mark(void *_completion)
{
	struct IO_Event_Selector_URing_Completion *completion = _completion;
	
	if (completion->waiting) {
		rb_gc_mark_movable(completion->waiting->fiber);
	}
}

void IO_Event_Selector_URing_Type_mark(void *_selector)
{
	struct IO_Event_Selector_URing *selector = _selector;
	IO_Event_Selector_mark(&selector->backend);
	IO_Event_Array_each(&selector->completions, IO_Event_Selector_URing_Completion_mark);
}

static
void IO_Event_Selector_URing_Completion_compact(void *_completion)
{
	struct IO_Event_Selector_URing_Completion *completion = _completion;
	
	if (completion->waiting) {
		completion->waiting->fiber = rb_gc_location(completion->waiting->fiber);
	}
}

void IO_Event_Selector_URing_Type_compact(void *_selector)
{
	struct IO_Event_Selector_URing *selector = _selector;
	IO_Event_Selector_compact(&selector->backend);
	IO_Event_Array_each(&selector->completions, IO_Event_Selector_URing_Completion_compact);
}

static
void close_internal(struct IO_Event_Selector_URing *selector)
{
	if (selector->ring.ring_fd >= 0) {
		io_uring_queue_exit(&selector->ring);
		selector->ring.ring_fd = -1;
	}
}

static
void IO_Event_Selector_URing_Type_free(void *_selector)
{
	struct IO_Event_Selector_URing *selector = _selector;
	
	close_internal(selector);
	
	IO_Event_Array_free(&selector->completions);
	
	free(selector);
}

static
size_t IO_Event_Selector_URing_Type_size(const void *_selector)
{
	const struct IO_Event_Selector_URing *selector = _selector;
	
	return sizeof(struct IO_Event_Selector_URing)
		+ IO_Event_Array_memory_size(&selector->completions)
		+ IO_Event_List_memory_size(&selector->free_list)
	;
}

static const rb_data_type_t IO_Event_Selector_URing_Type = {
	.wrap_struct_name = "IO::Event::Backend::URing",
	.function = {
		.dmark = IO_Event_Selector_URing_Type_mark,
		.dcompact = IO_Event_Selector_URing_Type_compact,
		.dfree = IO_Event_Selector_URing_Type_free,
		.dsize = IO_Event_Selector_URing_Type_size,
	},
	.data = NULL,
	.flags = RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED,
};

inline static
struct IO_Event_Selector_URing_Completion * IO_Event_Selector_URing_Completion_acquire(struct IO_Event_Selector_URing *selector, struct IO_Event_Selector_URing_Waiting *waiting)
{
	struct IO_Event_Selector_URing_Completion *completion = NULL;
	
	if (!IO_Event_List_empty(&selector->free_list)) {
		completion = (struct IO_Event_Selector_URing_Completion*)selector->free_list.tail;
		IO_Event_List_pop(&completion->list);
	} else {
		completion = IO_Event_Array_push(&selector->completions);
		IO_Event_List_clear(&completion->list);
	}
	
	if (DEBUG_COMPLETION) fprintf(stderr, "IO_Event_Selector_URing_Completion_acquire(%p, limit=%ld)\n", (void*)completion, selector->completions.limit);
	
	waiting->completion = completion;
	completion->waiting = waiting;
	
	return completion;
}

inline static
void IO_Event_Selector_URing_Completion_cancel(struct IO_Event_Selector_URing_Completion *completion)
{
	if (DEBUG_COMPLETION) fprintf(stderr, "IO_Event_Selector_URing_Completion_cancel(%p)\n", (void*)completion);
	
	if (completion->waiting) {
		completion->waiting->completion = NULL;
		completion->waiting = NULL;
	}
}

inline static
void IO_Event_Selector_URing_Completion_release(struct IO_Event_Selector_URing *selector, struct IO_Event_Selector_URing_Completion *completion)
{
	if (DEBUG_COMPLETION) fprintf(stderr, "IO_Event_Selector_URing_Completion_release(%p)\n", (void*)completion);
	
	IO_Event_Selector_URing_Completion_cancel(completion);
	IO_Event_List_prepend(&selector->free_list, &completion->list);
}

inline static
void IO_Event_Selector_URing_Waiting_cancel(struct IO_Event_Selector_URing_Waiting *waiting)
{
	if (DEBUG_COMPLETION) fprintf(stderr, "IO_Event_Selector_URing_Waiting_cancel(%p, %p)\n", (void*)waiting, (void*)waiting->completion);
	
	if (waiting->completion) {
		waiting->completion->waiting = NULL;
		waiting->completion = NULL;
	}
	
	waiting->fiber = 0;
}

struct IO_Event_List_Type IO_Event_Selector_URing_Completion_Type = {};

void IO_Event_Selector_URing_Completion_initialize(void *element)
{
	struct IO_Event_Selector_URing_Completion *completion = element;
	IO_Event_List_initialize(&completion->list);
	completion->list.type = &IO_Event_Selector_URing_Completion_Type;
}

void IO_Event_Selector_URing_Completion_free(void *element)
{
	struct IO_Event_Selector_URing_Completion *completion = element;
	IO_Event_Selector_URing_Completion_cancel(completion);
}

VALUE IO_Event_Selector_URing_allocate(VALUE self) {
	struct IO_Event_Selector_URing *selector = NULL;
	VALUE instance = TypedData_Make_Struct(self, struct IO_Event_Selector_URing, &IO_Event_Selector_URing_Type, selector);
	
	IO_Event_Selector_initialize(&selector->backend, self, Qnil);
	selector->ring.ring_fd = -1;
	
	selector->pending = 0;
	selector->blocked = 0;
	
	IO_Event_List_initialize(&selector->free_list);
	
	selector->completions.element_initialize = IO_Event_Selector_URing_Completion_initialize;
	selector->completions.element_free = IO_Event_Selector_URing_Completion_free;
	int result = IO_Event_Array_initialize(&selector->completions, IO_EVENT_ARRAY_DEFAULT_COUNT, sizeof(struct IO_Event_Selector_URing_Completion));
	if (result < 0) {
		rb_sys_fail("IO_Event_Selector_URing_allocate:IO_Event_Array_initialize");
	}
	
	return instance;
}

#pragma mark - Methods

VALUE IO_Event_Selector_URing_initialize(VALUE self, VALUE loop) {
	struct IO_Event_Selector_URing *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_URing, &IO_Event_Selector_URing_Type, selector);
	
	IO_Event_Selector_initialize(&selector->backend, self, loop);
	int result = io_uring_queue_init(URING_ENTRIES, &selector->ring, 0);
	
	if (result < 0) {
		rb_syserr_fail(-result, "IO_Event_Selector_URing_initialize:io_uring_queue_init");
	}
	
	rb_update_max_fd(selector->ring.ring_fd);
	
	return self;
}

VALUE IO_Event_Selector_URing_loop(VALUE self) {
	struct IO_Event_Selector_URing *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_URing, &IO_Event_Selector_URing_Type, selector);
	
	return selector->backend.loop;
}

VALUE IO_Event_Selector_URing_idle_duration(VALUE self) {
	struct IO_Event_Selector_URing *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_URing, &IO_Event_Selector_URing_Type, selector);
	
	double duration = selector->idle_duration.tv_sec + (selector->idle_duration.tv_nsec / 1000000000.0);
	
	return DBL2NUM(duration);
}

VALUE IO_Event_Selector_URing_close(VALUE self) {
	struct IO_Event_Selector_URing *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_URing, &IO_Event_Selector_URing_Type, selector);
	
	close_internal(selector);
	
	return Qnil;
}

VALUE IO_Event_Selector_URing_transfer(VALUE self)
{
	struct IO_Event_Selector_URing *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_URing, &IO_Event_Selector_URing_Type, selector);
	
	return IO_Event_Selector_loop_yield(&selector->backend);
}

VALUE IO_Event_Selector_URing_resume(int argc, VALUE *argv, VALUE self)
{
	struct IO_Event_Selector_URing *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_URing, &IO_Event_Selector_URing_Type, selector);
	
	return IO_Event_Selector_resume(&selector->backend, argc, argv);
}

VALUE IO_Event_Selector_URing_yield(VALUE self)
{
	struct IO_Event_Selector_URing *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_URing, &IO_Event_Selector_URing_Type, selector);
	
	return IO_Event_Selector_yield(&selector->backend);
}

VALUE IO_Event_Selector_URing_push(VALUE self, VALUE fiber)
{
	struct IO_Event_Selector_URing *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_URing, &IO_Event_Selector_URing_Type, selector);
	
	IO_Event_Selector_ready_push(&selector->backend, fiber);
	
	return Qnil;
}

VALUE IO_Event_Selector_URing_raise(int argc, VALUE *argv, VALUE self)
{
	struct IO_Event_Selector_URing *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_URing, &IO_Event_Selector_URing_Type, selector);
	
	return IO_Event_Selector_raise(&selector->backend, argc, argv);
}
	
VALUE IO_Event_Selector_URing_ready_p(VALUE self) {
	struct IO_Event_Selector_URing *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_URing, &IO_Event_Selector_URing_Type, selector);
	
	return selector->backend.ready ? Qtrue : Qfalse;
}

#pragma mark - Submission Queue

static
void IO_Event_Selector_URing_dump_completion_queue(struct IO_Event_Selector_URing *selector)
{
	struct io_uring *ring = &selector->ring;
	unsigned head;
	struct io_uring_cqe *cqe;
	
	if (DEBUG) {
		int first = 1;
		io_uring_for_each_cqe(ring, head, cqe) {
			if (!first) {
				fprintf(stderr, ", ");
			}
			else {
				fprintf(stderr, "CQ: [");
				first = 0;
			}
			
			fprintf(stderr, "%d:%p", (int)cqe->res, (void*)cqe->user_data);
		}
		if (!first) {
			fprintf(stderr, "]\n");
		}
	}
}

// Flush the submission queue if pending operations are present.
static
int io_uring_submit_flush(struct IO_Event_Selector_URing *selector) {
	if (selector->pending) {
		if (DEBUG) fprintf(stderr, "io_uring_submit_flush(pending=%ld)\n", selector->pending);
		
		// Try to submit:
		int result = io_uring_submit(&selector->ring);
		
		if (result >= 0) {
			// If it was submitted, reset pending count:
			selector->pending = 0;
		} else if (result != -EBUSY && result != -EAGAIN) {
			rb_syserr_fail(-result, "io_uring_submit_flush:io_uring_submit");
		}
		
		return result;
	}
	
	if (DEBUG) {
		IO_Event_Selector_URing_dump_completion_queue(selector);
	}
	
	return 0;
}

// Immediately flush the submission queue, yielding to the event loop if it was not successful.
static
int io_uring_submit_now(struct IO_Event_Selector_URing *selector) {
	if (DEBUG) fprintf(stderr, "io_uring_submit_now(pending=%ld)\n", selector->pending);
	
	while (true) {
		int result = io_uring_submit(&selector->ring);
		
		if (result >= 0) {
			selector->pending = 0;
			if (DEBUG) IO_Event_Selector_URing_dump_completion_queue(selector);
			return result;
		}
		
		if (result == -EBUSY || result == -EAGAIN) {
			IO_Event_Selector_yield(&selector->backend);
		} else {
			rb_syserr_fail(-result, "io_uring_submit_now:io_uring_submit");
		}
	}
}

// Submit a pending operation. This does not submit the operation immediately, but instead defers it to the next call to `io_uring_submit_flush` or `io_uring_submit_now`. This is useful for operations that are not urgent, but should be used with care as it can lead to a deadlock if the submission queue is not flushed.
static
void io_uring_submit_pending(struct IO_Event_Selector_URing *selector) {
	selector->pending += 1;
	
	if (DEBUG) fprintf(stderr, "io_uring_submit_pending(ring=%p, pending=%ld)\n", &selector->ring, selector->pending);
}

struct io_uring_sqe * io_get_sqe(struct IO_Event_Selector_URing *selector) {
	struct io_uring_sqe *sqe = io_uring_get_sqe(&selector->ring);
	
	while (sqe == NULL) {
		// The submit queue is full, we need to drain it:	
		io_uring_submit_now(selector);
		
		sqe = io_uring_get_sqe(&selector->ring);
	}
	
	return sqe;
}

#pragma mark - Process.wait

struct process_wait_arguments {
	struct IO_Event_Selector_URing *selector;
	struct IO_Event_Selector_URing_Waiting *waiting;
	
	pid_t pid;
	int flags;
	int descriptor;
};

static
VALUE process_wait_transfer(VALUE _arguments) {
	struct process_wait_arguments *arguments = (struct process_wait_arguments *)_arguments;
	
	IO_Event_Selector_loop_yield(&arguments->selector->backend);
	
	if (arguments->waiting->result) {
		return IO_Event_Selector_process_status_wait(arguments->pid, arguments->flags);
	} else {
		return Qfalse;
	}
}

static
VALUE process_wait_ensure(VALUE _arguments) {
	struct process_wait_arguments *arguments = (struct process_wait_arguments *)_arguments;
	
	close(arguments->descriptor);
	
	IO_Event_Selector_URing_Waiting_cancel(arguments->waiting);
	
	return Qnil;
}

VALUE IO_Event_Selector_URing_process_wait(VALUE self, VALUE fiber, VALUE _pid, VALUE _flags) {
	struct IO_Event_Selector_URing *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_URing, &IO_Event_Selector_URing_Type, selector);
	
	pid_t pid = NUM2PIDT(_pid);
	int flags = NUM2INT(_flags);
	
	int descriptor = pidfd_open(pid, 0);
	if (descriptor < 0) {
		rb_syserr_fail(errno, "IO_Event_Selector_URing_process_wait:pidfd_open");
	}
	rb_update_max_fd(descriptor);
	
	struct IO_Event_Selector_URing_Waiting waiting = {
		.fiber = fiber,
	};
	
	RB_OBJ_WRITTEN(self, Qundef, fiber);
	
	struct IO_Event_Selector_URing_Completion *completion = IO_Event_Selector_URing_Completion_acquire(selector, &waiting);
	
	struct process_wait_arguments process_wait_arguments = {
		.selector = selector,
		.waiting = &waiting,
		.pid = pid,
		.flags = flags,
		.descriptor = descriptor,
	};
	
	if (DEBUG) fprintf(stderr, "IO_Event_Selector_URing_process_wait:io_uring_prep_poll_add(%p)\n", (void*)fiber);
	struct io_uring_sqe *sqe = io_get_sqe(selector);
	io_uring_prep_poll_add(sqe, descriptor, POLLIN|POLLHUP|POLLERR);
	io_uring_sqe_set_data(sqe, completion);
	io_uring_submit_pending(selector);
	
	return rb_ensure(process_wait_transfer, (VALUE)&process_wait_arguments, process_wait_ensure, (VALUE)&process_wait_arguments);
}

#pragma mark - IO#wait

static inline
short poll_flags_from_events(int events) {
	short flags = 0;
	
	if (events & IO_EVENT_READABLE) flags |= POLLIN;
	if (events & IO_EVENT_PRIORITY) flags |= POLLPRI;
	if (events & IO_EVENT_WRITABLE) flags |= POLLOUT;
	
	flags |= POLLHUP;
	flags |= POLLERR;
	
	return flags;
}

static inline
int events_from_poll_flags(short flags) {
	int events = 0;
	
	// See `epoll.c` for details regarding POLLHUP:
	if (flags & (POLLIN|POLLHUP|POLLERR)) events |= IO_EVENT_READABLE;
	if (flags & POLLPRI) events |= IO_EVENT_PRIORITY;
	if (flags & POLLOUT) events |= IO_EVENT_WRITABLE;
	
	return events;
}

struct io_wait_arguments {
	struct IO_Event_Selector_URing *selector;
	struct IO_Event_Selector_URing_Waiting *waiting;
	short flags;
};

static
VALUE io_wait_ensure(VALUE _arguments) {
	struct io_wait_arguments *arguments = (struct io_wait_arguments *)_arguments;
	
	// If the operation is still in progress, cancel it:
	if (arguments->waiting->completion) {
		if (DEBUG) fprintf(stderr, "io_wait_ensure:io_uring_prep_cancel(waiting=%p, completion=%p)\n", (void*)arguments->waiting, (void*)arguments->waiting->completion);
		struct io_uring_sqe *sqe = io_get_sqe(arguments->selector);
		io_uring_prep_cancel(sqe, (void*)arguments->waiting->completion, 0);
		io_uring_sqe_set_data(sqe, NULL);
		io_uring_submit_now(arguments->selector);
	}
	
	IO_Event_Selector_URing_Waiting_cancel(arguments->waiting);
	
	return Qnil;
};

static
VALUE io_wait_transfer(VALUE _arguments) {
	struct io_wait_arguments *arguments = (struct io_wait_arguments *)_arguments;
	struct IO_Event_Selector_URing *selector = arguments->selector;
	
	IO_Event_Selector_loop_yield(&selector->backend);
	
	if (DEBUG) fprintf(stderr, "io_wait_transfer:waiting=%p, result=%d\n", (void*)arguments->waiting, arguments->waiting->result);
	
	int32_t result = arguments->waiting->result;
	if (result < 0) {
		rb_syserr_fail(-result, "io_wait_transfer:io_uring_poll_add");
	} else if (result > 0) {
		// We explicitly filter the resulting events based on the requested events.
		// In some cases, poll will report events we didn't ask for.
		return RB_INT2NUM(events_from_poll_flags(arguments->waiting->result & arguments->flags));
	} else {
		return Qfalse;
	}
};

VALUE IO_Event_Selector_URing_io_wait(VALUE self, VALUE fiber, VALUE io, VALUE events) {
	struct IO_Event_Selector_URing *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_URing, &IO_Event_Selector_URing_Type, selector);
	
	int descriptor = IO_Event_Selector_io_descriptor(io);
	
	short flags = poll_flags_from_events(NUM2INT(events));
	
	if (DEBUG) fprintf(stderr, "IO_Event_Selector_URing_io_wait:io_uring_prep_poll_add(descriptor=%d, flags=%d, fiber=%p)\n", descriptor, flags, (void*)fiber);
	
	struct IO_Event_Selector_URing_Waiting waiting = {
		.fiber = fiber,
	};
	
	RB_OBJ_WRITTEN(self, Qundef, fiber);
	
	struct IO_Event_Selector_URing_Completion *completion = IO_Event_Selector_URing_Completion_acquire(selector, &waiting);
	
	struct io_uring_sqe *sqe = io_get_sqe(selector);
	io_uring_prep_poll_add(sqe, descriptor, flags);
	io_uring_sqe_set_data(sqe, completion);
	// If we are going to wait, we assume that we are waiting for a while:
	io_uring_submit_pending(selector);
	
	struct io_wait_arguments io_wait_arguments = {
		.selector = selector,
		.waiting = &waiting,
		.flags = flags
	};
	
	return rb_ensure(io_wait_transfer, (VALUE)&io_wait_arguments, io_wait_ensure, (VALUE)&io_wait_arguments);
}

#ifdef HAVE_RUBY_IO_BUFFER_H

#pragma mark - IO#read

#if LINUX_VERSION_CODE >= KERNEL_VERSION(5,16,0)
static inline off_t io_seekable(int descriptor) {
	return -1;
}
#else
#warning Upgrade your kernel to 5.16+! io_uring bugs prevent efficient io_read/io_write hooks.
static inline off_t io_seekable(int descriptor)
{
	if (lseek(descriptor, 0, SEEK_CUR) == -1) {
		return 0;
	} else {
		return -1;
	}
}
#endif

#pragma mark - IO#read

struct io_read_arguments {
	struct IO_Event_Selector_URing *selector;
	struct IO_Event_Selector_URing_Waiting *waiting;
	int descriptor;
	off_t offset;
	char *buffer;
	size_t length;
};

static VALUE
io_read_submit(VALUE _arguments)
{
	struct io_read_arguments *arguments = (struct io_read_arguments *)_arguments;
	struct IO_Event_Selector_URing *selector = arguments->selector;
	
	if (DEBUG) fprintf(stderr, "io_read_submit:io_uring_prep_read(waiting=%p, completion=%p, descriptor=%d, buffer=%p, length=%ld)\n", (void*)arguments->waiting, (void*)arguments->waiting->completion, arguments->descriptor, arguments->buffer, arguments->length);
	
	struct io_uring_sqe *sqe = io_get_sqe(selector);
	io_uring_prep_read(sqe, arguments->descriptor, arguments->buffer, arguments->length, arguments->offset);
	io_uring_sqe_set_data(sqe, arguments->waiting->completion);
	io_uring_submit_now(selector);
	
	IO_Event_Selector_loop_yield(&selector->backend);
	
	return RB_INT2NUM(arguments->waiting->result);
}

static VALUE
io_read_ensure(VALUE _arguments)
{
	struct io_read_arguments *arguments = (struct io_read_arguments *)_arguments;
	struct IO_Event_Selector_URing *selector = arguments->selector;
	
	// If the operation is still in progress, cancel it:
	if (arguments->waiting->completion) {
		if (DEBUG) fprintf(stderr, "io_read_ensure:io_uring_prep_cancel(waiting=%p, completion=%p)\n", (void*)arguments->waiting, (void*)arguments->waiting->completion);
		struct io_uring_sqe *sqe = io_get_sqe(selector);
		io_uring_prep_cancel(sqe, (void*)arguments->waiting->completion, 0);
		io_uring_sqe_set_data(sqe, NULL);
		io_uring_submit_now(selector);
	}
	
	IO_Event_Selector_URing_Waiting_cancel(arguments->waiting);
	
	return Qnil;
}

static int
io_read(struct IO_Event_Selector_URing *selector, VALUE fiber, int descriptor, char *buffer, size_t length, off_t offset)
{
	struct IO_Event_Selector_URing_Waiting waiting = {
		.fiber = fiber,
	};
	
	RB_OBJ_WRITTEN(selector->backend.self, Qundef, fiber);
	
	IO_Event_Selector_URing_Completion_acquire(selector, &waiting);
	
	struct io_read_arguments io_read_arguments = {
		.selector = selector,
		.waiting = &waiting,
		.descriptor = descriptor,
		.offset = offset,
		.buffer = buffer,
		.length = length
	};
	
	return RB_NUM2INT(
		rb_ensure(io_read_submit, (VALUE)&io_read_arguments, io_read_ensure, (VALUE)&io_read_arguments)
	);
}

VALUE IO_Event_Selector_URing_io_read(VALUE self, VALUE fiber, VALUE io, VALUE buffer, VALUE _length, VALUE _offset) {
	struct IO_Event_Selector_URing *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_URing, &IO_Event_Selector_URing_Type, selector);
	
	int descriptor = IO_Event_Selector_io_descriptor(io);
	
	void *base;
	size_t size;
	rb_io_buffer_get_bytes_for_writing(buffer, &base, &size);
	
	size_t length = NUM2SIZET(_length);
	size_t offset = NUM2SIZET(_offset);
	size_t total = 0;
	off_t from = io_seekable(descriptor);
	
	size_t maximum_size = size - offset;
	
	// Are we performing a non-blocking read?
	if (!length) {
		// If the (maximum) length is zero, that indicates we just want to read whatever is available without blocking.
		// If we schedule this read into the URing, it will block until data is available, rather than returning immediately.
		int state = IO_Event_Selector_nonblock_set(descriptor);
		
		int result = read(descriptor, (char*)base+offset, maximum_size);
		int error = errno;
		
		IO_Event_Selector_nonblock_restore(descriptor, state);
		return rb_fiber_scheduler_io_result(result, error);
	}
	
	while (maximum_size) {
		int result = io_read(selector, fiber, descriptor, (char*)base+offset, maximum_size, from);
		
		if (result > 0) {
			total += result;
			offset += result;
			if ((size_t)result >= length) break;
			length -= result;
		} else if (result == 0) {
			break;
		} else if (length > 0 && IO_Event_try_again(-result)) {
			IO_Event_Selector_URing_io_wait(self, fiber, io, RB_INT2NUM(IO_EVENT_READABLE));
		} else {
			return rb_fiber_scheduler_io_result(-1, -result);
		}
		
		maximum_size = size - offset;
	}
	
	return rb_fiber_scheduler_io_result(total, 0);
}

static VALUE IO_Event_Selector_URing_io_read_compatible(int argc, VALUE *argv, VALUE self)
{
	rb_check_arity(argc, 4, 5);
	
	VALUE _offset = SIZET2NUM(0);
	
	if (argc == 5) {
		_offset = argv[4];
	}
	
	return IO_Event_Selector_URing_io_read(self, argv[0], argv[1], argv[2], argv[3], _offset);
}

VALUE IO_Event_Selector_URing_io_pread(VALUE self, VALUE fiber, VALUE io, VALUE buffer, VALUE _from, VALUE _length, VALUE _offset) {
	struct IO_Event_Selector_URing *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_URing, &IO_Event_Selector_URing_Type, selector);
	
	int descriptor = IO_Event_Selector_io_descriptor(io);
	
	void *base;
	size_t size;
	rb_io_buffer_get_bytes_for_writing(buffer, &base, &size);
	
	size_t length = NUM2SIZET(_length);
	size_t offset = NUM2SIZET(_offset);
	size_t total = 0;
	off_t from = NUM2OFFT(_from);
	
	size_t maximum_size = size - offset;
	while (maximum_size) {
		int result = io_read(selector, fiber, descriptor, (char*)base+offset, maximum_size, from);
		
		if (result > 0) {
			total += result;
			offset += result;
			from += result;
			if ((size_t)result >= length) break;
			length -= result;
		} else if (result == 0) {
			break;
		} else if (length > 0 && IO_Event_try_again(-result)) {
			IO_Event_Selector_URing_io_wait(self, fiber, io, RB_INT2NUM(IO_EVENT_READABLE));
		} else {
			return rb_fiber_scheduler_io_result(-1, -result);
		}
		
		maximum_size = size - offset;
	}
	
	return rb_fiber_scheduler_io_result(total, 0);
}

#pragma mark - IO#write

struct io_write_arguments {
	struct IO_Event_Selector_URing *selector;
	struct IO_Event_Selector_URing_Waiting *waiting;
	int descriptor;
	off_t offset;
	char *buffer;
	size_t length;
};

static VALUE
io_write_submit(VALUE _argument)
{
	struct io_write_arguments *arguments = (struct io_write_arguments*)_argument;
	struct IO_Event_Selector_URing *selector = arguments->selector;
	
	if (DEBUG) fprintf(stderr, "io_write_submit:io_uring_prep_write(waiting=%p, completion=%p, descriptor=%d, buffer=%p, length=%ld)\n", (void*)arguments->waiting, (void*)arguments->waiting->completion, arguments->descriptor, arguments->buffer, arguments->length);
	
	struct io_uring_sqe *sqe = io_get_sqe(selector);
	io_uring_prep_write(sqe, arguments->descriptor, arguments->buffer, arguments->length, arguments->offset);
	io_uring_sqe_set_data(sqe, arguments->waiting->completion);
	io_uring_submit_pending(selector);
	
	IO_Event_Selector_loop_yield(&selector->backend);
	
	return RB_INT2NUM(arguments->waiting->result);
}

static VALUE
io_write_ensure(VALUE _argument)
{
	struct io_write_arguments *arguments = (struct io_write_arguments*)_argument;
	struct IO_Event_Selector_URing *selector = arguments->selector;
	
	// If the operation is still in progress, cancel it:
	if (arguments->waiting->completion) {
		if (DEBUG) fprintf(stderr, "io_write_ensure:io_uring_prep_cancel(waiting=%p, completion=%p)\n", (void*)arguments->waiting, (void*)arguments->waiting->completion);
		struct io_uring_sqe *sqe = io_get_sqe(selector);
		io_uring_prep_cancel(sqe, (void*)arguments->waiting->completion, 0);
		io_uring_sqe_set_data(sqe, NULL);
		io_uring_submit_now(selector);
	}
	
	IO_Event_Selector_URing_Waiting_cancel(arguments->waiting);
	
	return Qnil;
}

static int
io_write(struct IO_Event_Selector_URing *selector, VALUE fiber, int descriptor, char *buffer, size_t length, off_t offset)
{
	struct IO_Event_Selector_URing_Waiting waiting = {
		.fiber = fiber,
	};
	
	RB_OBJ_WRITTEN(selector->backend.self, Qundef, fiber);
	
	IO_Event_Selector_URing_Completion_acquire(selector, &waiting);
	
	struct io_write_arguments arguments = {
		.selector = selector,
		.waiting = &waiting,
		.descriptor = descriptor,
		.offset = offset,
		.buffer = buffer,
		.length = length,
	};
	
	return RB_NUM2INT(
		rb_ensure(io_write_submit, (VALUE)&arguments, io_write_ensure, (VALUE)&arguments)
	);
}

VALUE IO_Event_Selector_URing_io_write(VALUE self, VALUE fiber, VALUE io, VALUE buffer, VALUE _length, VALUE _offset) {
	struct IO_Event_Selector_URing *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_URing, &IO_Event_Selector_URing_Type, selector);
	
	int descriptor = IO_Event_Selector_io_descriptor(io);
	
	const void *base;
	size_t size;
	rb_io_buffer_get_bytes_for_reading(buffer, &base, &size);
	
	size_t length = NUM2SIZET(_length);
	size_t offset = NUM2SIZET(_offset);
	size_t total = 0;
	off_t from = io_seekable(descriptor);
	
	if (length > size) {
		rb_raise(rb_eRuntimeError, "Length exceeds size of buffer!");
	}

	size_t maximum_size = size - offset;
	while (maximum_size) {
		int result = io_write(selector, fiber, descriptor, (char*)base+offset, maximum_size, from);
		
		if (result > 0) {
			total += result;
			offset += result;
			if ((size_t)result >= length) break;
			length -= result;
		} else if (result == 0) {
			break;
		} else if (length > 0 && IO_Event_try_again(-result)) {
			IO_Event_Selector_URing_io_wait(self, fiber, io, RB_INT2NUM(IO_EVENT_WRITABLE));
		} else {
			return rb_fiber_scheduler_io_result(-1, -result);
		}
		
		maximum_size = size - offset;
	}
	
	return rb_fiber_scheduler_io_result(total, 0);
}

static VALUE IO_Event_Selector_URing_io_write_compatible(int argc, VALUE *argv, VALUE self)
{
	rb_check_arity(argc, 4, 5);
	
	VALUE _offset = SIZET2NUM(0);
	
	if (argc == 5) {
		_offset = argv[4];
	}
	
	return IO_Event_Selector_URing_io_write(self, argv[0], argv[1], argv[2], argv[3], _offset);
}

VALUE IO_Event_Selector_URing_io_pwrite(VALUE self, VALUE fiber, VALUE io, VALUE buffer, VALUE _from, VALUE _length, VALUE _offset) {
	struct IO_Event_Selector_URing *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_URing, &IO_Event_Selector_URing_Type, selector);
	
	int descriptor = IO_Event_Selector_io_descriptor(io);
	
	const void *base;
	size_t size;
	rb_io_buffer_get_bytes_for_reading(buffer, &base, &size);
	
	size_t length = NUM2SIZET(_length);
	size_t offset = NUM2SIZET(_offset);
	size_t total = 0;
	off_t from = NUM2OFFT(_from);
	
	if (length > size) {
		rb_raise(rb_eRuntimeError, "Length exceeds size of buffer!");
	}

	size_t maximum_size = size - offset;
	while (maximum_size) {
		int result = io_write(selector, fiber, descriptor, (char*)base+offset, maximum_size, from);
		
		if (result > 0) {
			total += result;
			offset += result;
			from += result;
			if ((size_t)result >= length) break;
			length -= result;
		} else if (result == 0) {
			break;
		} else if (length > 0 && IO_Event_try_again(-result)) {
			IO_Event_Selector_URing_io_wait(self, fiber, io, RB_INT2NUM(IO_EVENT_WRITABLE));
		} else {
			return rb_fiber_scheduler_io_result(-1, -result);
		}
		
		maximum_size = size - offset;
	}
	
	return rb_fiber_scheduler_io_result(total, 0);
}

#endif

#pragma mark - IO#close

static const int ASYNC_CLOSE = 1;

VALUE IO_Event_Selector_URing_io_close(VALUE self, VALUE io) {
	struct IO_Event_Selector_URing *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_URing, &IO_Event_Selector_URing_Type, selector);
	
	int descriptor = IO_Event_Selector_io_descriptor(io);

	if (ASYNC_CLOSE) {
		struct io_uring_sqe *sqe = io_get_sqe(selector);
		io_uring_prep_close(sqe, descriptor);
		io_uring_sqe_set_data(sqe, NULL);
		io_uring_submit_now(selector);
	} else {
		close(descriptor);
	}

	// We don't wait for the result of close since it has no use in pratice:
	return Qtrue;
}

#pragma mark - Event Loop

static
struct __kernel_timespec * make_timeout(VALUE duration, struct __kernel_timespec *storage) {
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
int timeout_nonblocking(struct __kernel_timespec *timespec) {
	return timespec && timespec->tv_sec == 0 && timespec->tv_nsec == 0;
}

struct select_arguments {
	struct IO_Event_Selector_URing *selector;
	
	int result;
	
	struct __kernel_timespec storage;
	struct __kernel_timespec *timeout;
};

static
void * select_internal(void *_arguments) {
	struct select_arguments * arguments = (struct select_arguments *)_arguments;
	struct io_uring_cqe *cqe = NULL;
	
	arguments->result = io_uring_wait_cqe_timeout(&arguments->selector->ring, &cqe, arguments->timeout);
	
	return NULL;
}

static
int select_internal_without_gvl(struct select_arguments *arguments) {
	io_uring_submit_flush(arguments->selector);
	
	arguments->selector->blocked = 1;
	rb_thread_call_without_gvl(select_internal, (void *)arguments, RUBY_UBF_IO, 0);
	arguments->selector->blocked = 0;
	
	if (arguments->result == -ETIME) {
		arguments->result = 0;
	} else if (arguments->result == -EINTR) {
		arguments->result = 0;
	} else if (arguments->result < 0) {
		rb_syserr_fail(-arguments->result, "select_internal_without_gvl:io_uring_wait_cqe_timeout");
	} else {
		// At least 1 event is waiting:
		arguments->result = 1;
	}
	
	return arguments->result;
}

static inline
unsigned select_process_completions(struct IO_Event_Selector_URing *selector) {
	struct io_uring *ring = &selector->ring;
	unsigned completed = 0;
	unsigned head;
	struct io_uring_cqe *cqe;
	
	if (DEBUG) {
		fprintf(stderr, "select_process_completions: selector=%p\n", (void*)selector);
		IO_Event_Selector_URing_dump_completion_queue(selector);
	}
	
	io_uring_for_each_cqe(ring, head, cqe) {
		if (DEBUG_CQE) fprintf(stderr, "select_process_completions: cqe res=%d user_data=%p\n", cqe->res, (void*)cqe->user_data);
		
		++completed;
		
		// If the operation was cancelled, or the operation has no user data:
		if (cqe->user_data == 0 || cqe->user_data == LIBURING_UDATA_TIMEOUT) {
			io_uring_cq_advance(ring, 1);
			continue;
		}
		
		struct IO_Event_Selector_URing_Completion *completion = (void*)cqe->user_data;
		struct IO_Event_Selector_URing_Waiting *waiting = completion->waiting;
		
		if (DEBUG) fprintf(stderr, "select_process_completions: completion=%p waiting=%p\n", (void*)completion, (void*)waiting);
		
		if (waiting) {
			waiting->result = cqe->res;
			waiting->flags = cqe->flags;
		}
		
		io_uring_cq_advance(ring, 1);
		// This marks the waiting operation as "complete":
		IO_Event_Selector_URing_Completion_release(selector, completion);
		
		if (waiting && waiting->fiber) {
			assert(waiting->result != -ECANCELED);
			
			IO_Event_Selector_loop_resume(&selector->backend, waiting->fiber, 0, NULL);
		}
	}
	
	if (DEBUG && completed > 0) fprintf(stderr, "select_process_completions: completed=%d\n", completed);
	
	return completed;
}

VALUE IO_Event_Selector_URing_select(VALUE self, VALUE duration) {
	struct IO_Event_Selector_URing *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_URing, &IO_Event_Selector_URing_Type, selector);
	
	selector->idle_duration.tv_sec = 0;
	selector->idle_duration.tv_nsec = 0;
	
	// Flush any pending events:
	io_uring_submit_flush(selector);
	
	int ready = IO_Event_Selector_ready_flush(&selector->backend);
	
	int result = select_process_completions(selector);
	
	// If we:
	// 1. Didn't process any ready fibers, and
	// 2. Didn't process any events from non-blocking select (above), and
	// 3. There are no items in the ready list,
	// then we can perform a blocking select.
	if (!ready && !result && !selector->backend.ready) {
		// We might need to wait for events:
		struct select_arguments arguments = {
			.selector = selector,
			.timeout = NULL,
		};
		
		arguments.timeout = make_timeout(duration, &arguments.storage);
		
		if (!selector->backend.ready && !timeout_nonblocking(arguments.timeout)) {
			struct timespec start_time;
			IO_Event_Time_current(&start_time);
			
			// This is a blocking operation, we wait for events:
			result = select_internal_without_gvl(&arguments);
			
			struct timespec end_time;
			IO_Event_Time_current(&end_time);
			IO_Event_Time_elapsed(&start_time, &end_time, &selector->idle_duration);
			
			// After waiting/flushing the SQ, check if there are any completions:
			if (result > 0) {
				result = select_process_completions(selector);
			}
		}
	}
	
	return RB_INT2NUM(result);
}

VALUE IO_Event_Selector_URing_wakeup(VALUE self) {
	struct IO_Event_Selector_URing *selector = NULL;
	TypedData_Get_Struct(self, struct IO_Event_Selector_URing, &IO_Event_Selector_URing_Type, selector);
	
	// If we are blocking, we can schedule a nop event to wake up the selector:
	if (selector->blocked) {
		struct io_uring_sqe *sqe = NULL;
		
		while (true) {
			sqe = io_uring_get_sqe(&selector->ring);
			if (sqe) break;
			
			rb_thread_schedule();
			
			// It's possible we became unblocked already, so we can assume the selector has already cycled at least once:
			if (!selector->blocked) return Qfalse;
		}
		
		io_uring_prep_nop(sqe);
		// If you don't set this line, the SQE will eventually be recycled and have valid user selector which can cause odd behaviour:
		io_uring_sqe_set_data(sqe, NULL);
		io_uring_submit(&selector->ring);
		
		return Qtrue;
	}
	
	return Qfalse;
}

#pragma mark - Native Methods

static int IO_Event_Selector_URing_supported_p(void) {
	struct io_uring ring;
	int result = io_uring_queue_init(32, &ring, 0);
	
	if (result < 0) {
		rb_warn("io_uring_queue_init() was available at compile time but failed at run time: %s\n", strerror(-result));
		
		return 0;
	}
	
	io_uring_queue_exit(&ring);
	
	return 1;
}

void Init_IO_Event_Selector_URing(VALUE IO_Event_Selector) {
	if (!IO_Event_Selector_URing_supported_p()) {
		return;
	}
	
	VALUE IO_Event_Selector_URing = rb_define_class_under(IO_Event_Selector, "URing", rb_cObject);
	
	rb_define_alloc_func(IO_Event_Selector_URing, IO_Event_Selector_URing_allocate);
	rb_define_method(IO_Event_Selector_URing, "initialize", IO_Event_Selector_URing_initialize, 1);
	
	rb_define_method(IO_Event_Selector_URing, "loop", IO_Event_Selector_URing_loop, 0);
	rb_define_method(IO_Event_Selector_URing, "idle_duration", IO_Event_Selector_URing_idle_duration, 0);
	
	rb_define_method(IO_Event_Selector_URing, "transfer", IO_Event_Selector_URing_transfer, 0);
	rb_define_method(IO_Event_Selector_URing, "resume", IO_Event_Selector_URing_resume, -1);
	rb_define_method(IO_Event_Selector_URing, "yield", IO_Event_Selector_URing_yield, 0);
	rb_define_method(IO_Event_Selector_URing, "push", IO_Event_Selector_URing_push, 1);
	rb_define_method(IO_Event_Selector_URing, "raise", IO_Event_Selector_URing_raise, -1);
	
	rb_define_method(IO_Event_Selector_URing, "ready?", IO_Event_Selector_URing_ready_p, 0);
	
	rb_define_method(IO_Event_Selector_URing, "select", IO_Event_Selector_URing_select, 1);
	rb_define_method(IO_Event_Selector_URing, "wakeup", IO_Event_Selector_URing_wakeup, 0);
	rb_define_method(IO_Event_Selector_URing, "close", IO_Event_Selector_URing_close, 0);
	
	rb_define_method(IO_Event_Selector_URing, "io_wait", IO_Event_Selector_URing_io_wait, 3);
	
#ifdef HAVE_RUBY_IO_BUFFER_H
	rb_define_method(IO_Event_Selector_URing, "io_read", IO_Event_Selector_URing_io_read_compatible, -1);
	rb_define_method(IO_Event_Selector_URing, "io_write", IO_Event_Selector_URing_io_write_compatible, -1);
	rb_define_method(IO_Event_Selector_URing, "io_pread", IO_Event_Selector_URing_io_pread, 6);
	rb_define_method(IO_Event_Selector_URing, "io_pwrite", IO_Event_Selector_URing_io_pwrite, 6);
#endif
	
	rb_define_method(IO_Event_Selector_URing, "io_close", IO_Event_Selector_URing_io_close, 1);
	
	rb_define_method(IO_Event_Selector_URing, "process_wait", IO_Event_Selector_URing_process_wait, 3);
}
