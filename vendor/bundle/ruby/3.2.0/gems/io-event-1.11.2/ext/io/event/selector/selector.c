// Released under the MIT License.
// Copyright, 2021-2025, by Samuel Williams.

#include "selector.h"

#include <fcntl.h>
#include <stdlib.h>

static const int DEBUG = 0;

#ifndef HAVE_RB_IO_DESCRIPTOR
static ID id_fileno;

int IO_Event_Selector_io_descriptor(VALUE io) {
	return RB_NUM2INT(rb_funcall(io, id_fileno, 0));
}
#endif

#ifndef HAVE_RB_PROCESS_STATUS_WAIT
static ID id_wait;
static VALUE rb_Process_Status = Qnil;

VALUE IO_Event_Selector_process_status_wait(rb_pid_t pid, int flags)
{
	return rb_funcall(rb_Process_Status, id_wait, 2, PIDT2NUM(pid), INT2NUM(flags | WNOHANG));
}
#endif

int IO_Event_Selector_nonblock_set(int file_descriptor)
{
#ifdef _WIN32
	u_long nonblock = 1;
	ioctlsocket(file_descriptor, FIONBIO, &nonblock);
	// Windows does not provide any way to know this, so we always restore it back to unset:
	return 0;
#else
	// Get the current mode:
	int flags = fcntl(file_descriptor, F_GETFL, 0);
	
	// Set the non-blocking flag if it isn't already:
	if (!(flags & O_NONBLOCK)) {
		fcntl(file_descriptor, F_SETFL, flags | O_NONBLOCK);
	}
	
	return flags;
#endif
}

void IO_Event_Selector_nonblock_restore(int file_descriptor, int flags)
{
#ifdef _WIN32
	// Yolo...
	u_long nonblock = flags;
	ioctlsocket(file_descriptor, FIONBIO, &nonblock);
#else
	// The flags didn't have O_NONBLOCK set, so it would have been set, so we need to restore it:
	if (!(flags & O_NONBLOCK)) {
		fcntl(file_descriptor, F_SETFL, flags);
	}
#endif
}

struct IO_Event_Selector_nonblock_arguments {
	int file_descriptor;
	int flags;
};

static VALUE IO_Event_Selector_nonblock_ensure(VALUE _arguments) {
	struct IO_Event_Selector_nonblock_arguments *arguments = (struct IO_Event_Selector_nonblock_arguments *)_arguments;
	
	IO_Event_Selector_nonblock_restore(arguments->file_descriptor, arguments->flags);
	
	return Qnil;
}

static VALUE IO_Event_Selector_nonblock(VALUE class, VALUE io)
{
	struct IO_Event_Selector_nonblock_arguments arguments = {
		.file_descriptor = IO_Event_Selector_io_descriptor(io),
		.flags = IO_Event_Selector_nonblock_set(arguments.file_descriptor)
	};
	
	return rb_ensure(rb_yield, io, IO_Event_Selector_nonblock_ensure, (VALUE)&arguments);
}

void Init_IO_Event_Selector(VALUE IO_Event_Selector) {
#ifndef HAVE_RB_IO_DESCRIPTOR
	id_fileno = rb_intern("fileno");
#endif
	
#ifndef HAVE_RB_PROCESS_STATUS_WAIT
	id_wait = rb_intern("wait");
	rb_Process_Status = rb_const_get_at(rb_mProcess, rb_intern("Status"));
	rb_gc_register_mark_object(rb_Process_Status);
#endif
	
	rb_define_singleton_method(IO_Event_Selector, "nonblock", IO_Event_Selector_nonblock, 1);
}

void IO_Event_Selector_initialize(struct IO_Event_Selector *backend, VALUE self, VALUE loop) {
	RB_OBJ_WRITE(self, &backend->self, self);
	RB_OBJ_WRITE(self, &backend->loop, loop);
	
	backend->waiting = NULL;
	backend->ready = NULL;
}

VALUE IO_Event_Selector_loop_resume(struct IO_Event_Selector *backend, VALUE fiber, int argc, VALUE *argv) {
	return IO_Event_Fiber_transfer(fiber, argc, argv);
}

VALUE IO_Event_Selector_loop_yield(struct IO_Event_Selector *backend)
{
	// TODO Why is this assertion failing in async?
	// RUBY_ASSERT(backend->loop != IO_Event_Fiber_current());
	return IO_Event_Fiber_transfer(backend->loop, 0, NULL);
}

struct wait_and_transfer_arguments {
	int argc;
	VALUE *argv;
	
	struct IO_Event_Selector *backend;
	struct IO_Event_Selector_Queue *waiting;
};

static void queue_pop(struct IO_Event_Selector *backend, struct IO_Event_Selector_Queue *waiting) {
	if (waiting->head) {
		waiting->head->tail = waiting->tail;
	} else {
		// We must have been at the head of the queue:
		backend->waiting = waiting->tail;
	}
	
	if (waiting->tail) {
		waiting->tail->head = waiting->head;
	} else {
		// We must have been at the tail of the queue:
		backend->ready = waiting->head;
	}
	
	waiting->head = NULL;
	waiting->tail = NULL;
}

static void queue_push(struct IO_Event_Selector *backend, struct IO_Event_Selector_Queue *waiting) {
	assert(waiting->head == NULL);
	assert(waiting->tail == NULL);
	
	if (backend->waiting) {
		// If there was an item in the queue already, we shift it along:
		backend->waiting->head = waiting;
		waiting->tail = backend->waiting;
	} else {
		// If the queue was empty, we update the tail too:
		backend->ready = waiting;
	}
	
	// We always push to the front/head:
	backend->waiting = waiting;
}

static VALUE wait_and_transfer(VALUE _arguments) {
	struct wait_and_transfer_arguments *arguments = (struct wait_and_transfer_arguments *)_arguments;
	
	VALUE fiber = arguments->argv[0];
	int argc = arguments->argc - 1;
	VALUE *argv = arguments->argv + 1;
	
	return IO_Event_Selector_loop_resume(arguments->backend, fiber, argc, argv);
}

static VALUE wait_and_transfer_ensure(VALUE _arguments) {
	struct wait_and_transfer_arguments *arguments = (struct wait_and_transfer_arguments *)_arguments;
	
	queue_pop(arguments->backend, arguments->waiting);
	
	return Qnil;
}

VALUE IO_Event_Selector_resume(struct IO_Event_Selector *backend, int argc, VALUE *argv)
{
	rb_check_arity(argc, 1, UNLIMITED_ARGUMENTS);
	
	struct IO_Event_Selector_Queue waiting = {
		.head = NULL,
		.tail = NULL,
		.flags = IO_EVENT_SELECTOR_QUEUE_FIBER,
		.fiber = IO_Event_Fiber_current()
	};
	
	RB_OBJ_WRITTEN(backend->self, Qundef, waiting.fiber);
	
	queue_push(backend, &waiting);
	
	struct wait_and_transfer_arguments arguments = {
		.argc = argc,
		.argv = argv,
		.backend = backend,
		.waiting = &waiting,
	};
	
	return rb_ensure(wait_and_transfer, (VALUE)&arguments, wait_and_transfer_ensure, (VALUE)&arguments);
}

static VALUE wait_and_raise(VALUE _arguments) {
	struct wait_and_transfer_arguments *arguments = (struct wait_and_transfer_arguments *)_arguments;
	
	VALUE fiber = arguments->argv[0];
	int argc = arguments->argc - 1;
	VALUE *argv = arguments->argv + 1;
	
	return IO_Event_Fiber_raise(fiber, argc, argv);
}

VALUE IO_Event_Selector_raise(struct IO_Event_Selector *backend, int argc, VALUE *argv)
{
	rb_check_arity(argc, 2, UNLIMITED_ARGUMENTS);
	
	struct IO_Event_Selector_Queue waiting = {
		.head = NULL,
		.tail = NULL,
		.flags = IO_EVENT_SELECTOR_QUEUE_FIBER,
		.fiber = IO_Event_Fiber_current()
	};
	
	RB_OBJ_WRITTEN(backend->self, Qundef, waiting.fiber);
	
	queue_push(backend, &waiting);
	
	struct wait_and_transfer_arguments arguments = {
		.argc = argc,
		.argv = argv,
		.backend = backend,
		.waiting = &waiting,
	};
	
	return rb_ensure(wait_and_raise, (VALUE)&arguments, wait_and_transfer_ensure, (VALUE)&arguments);
}

void IO_Event_Selector_ready_push(struct IO_Event_Selector *backend, VALUE fiber)
{
	struct IO_Event_Selector_Queue *waiting = malloc(sizeof(struct IO_Event_Selector_Queue));
	assert(waiting);
	
	waiting->head = NULL;
	waiting->tail = NULL;
	waiting->flags = IO_EVENT_SELECTOR_QUEUE_INTERNAL;
	
	RB_OBJ_WRITE(backend->self, &waiting->fiber, fiber);
	
	queue_push(backend, waiting);
}

static inline
void IO_Event_Selector_ready_pop(struct IO_Event_Selector *backend, struct IO_Event_Selector_Queue *ready)
{
	if (DEBUG) fprintf(stderr, "IO_Event_Selector_ready_pop -> %p\n", (void*)ready->fiber);
	
	VALUE fiber = ready->fiber;
	
	if (ready->flags & IO_EVENT_SELECTOR_QUEUE_INTERNAL) {
		// This means that the fiber was added to the ready queue by the selector itself, and we need to transfer control to it, but before we do that, we need to remove it from the queue, as there is no expectation that returning from `transfer` will remove it.
		queue_pop(backend, ready);
		free(ready);
	} else if (ready->flags & IO_EVENT_SELECTOR_QUEUE_FIBER) {
		// This means the fiber added itself to the ready queue, and we need to transfer control back to it. Transferring control back to the fiber will call `queue_pop` and remove it from the queue.
	} else {
		rb_raise(rb_eRuntimeError, "Unknown queue type!");
	}
	
	IO_Event_Selector_loop_resume(backend, fiber, 0, NULL);
}

int IO_Event_Selector_ready_flush(struct IO_Event_Selector *backend)
{
	int count = 0;
	
	// During iteration of the queue, the same item may be re-queued. If we don't handle this correctly, we may end up in an infinite loop. So, to avoid this situation, we keep note of the current head of the queue and break the loop if we reach the same item again.
	
	// Get the current tail and head of the queue:
	struct IO_Event_Selector_Queue *waiting = backend->waiting;
	if (DEBUG) fprintf(stderr, "IO_Event_Selector_ready_flush waiting = %p\n", waiting);
	
	// Process from head to tail in order:
	// During this, more items may be appended to tail.
	while (backend->ready) {
		if (DEBUG) fprintf(stderr, "backend->ready = %p\n", backend->ready);
		struct IO_Event_Selector_Queue *ready = backend->ready;
		
		count += 1;
		IO_Event_Selector_ready_pop(backend, ready);
		
		if (ready == waiting) break;
	}
	
	return count;
}
