// Released under the MIT License.
// Copyright, 2025, by Samuel Williams.

#include "worker_pool.h"
#include "worker_pool_test.h"
#include "fiber.h"

#include <ruby/thread.h>
#include <ruby/fiber/scheduler.h>

#include <pthread.h>
#include <stdbool.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>

enum {
	DEBUG = 0,
};

static VALUE IO_Event_WorkerPool;
static ID id_maximum_worker_count;

// Thread pool structure
struct IO_Event_WorkerPool_Worker {
	VALUE thread;
	
	// Flag to indicate this specific worker should exit:
	bool interrupted;

	// Currently executing operation:
	rb_fiber_scheduler_blocking_operation_t *current_blocking_operation;

	struct IO_Event_WorkerPool *pool;
	struct IO_Event_WorkerPool_Worker *next;
};

// Work item structure
struct IO_Event_WorkerPool_Work {
	rb_fiber_scheduler_blocking_operation_t *blocking_operation;
	
	bool completed;
	
	VALUE scheduler;
	VALUE blocker;
	VALUE fiber;
	
	struct IO_Event_WorkerPool_Work *next;
};

// Worker pool structure
struct IO_Event_WorkerPool {
	pthread_mutex_t mutex;
	pthread_cond_t work_available;
	
	struct IO_Event_WorkerPool_Work *work_queue;
	struct IO_Event_WorkerPool_Work *work_queue_tail;
	
	struct IO_Event_WorkerPool_Worker *workers;
	size_t current_worker_count;
	size_t maximum_worker_count;
	
	size_t call_count;
	size_t completed_count;
	size_t cancelled_count;
	
	bool shutdown;
};

// Free functions for Ruby GC
static void worker_pool_free(void *ptr) {
	struct IO_Event_WorkerPool *pool = (struct IO_Event_WorkerPool *)ptr;
	
	if (pool) {
		// Signal shutdown to all workers
		if (!pool->shutdown) {
			pthread_mutex_lock(&pool->mutex);
			pool->shutdown = true;
			pthread_cond_broadcast(&pool->work_available);
			pthread_mutex_unlock(&pool->mutex);
		}
		
		// Note: We don't free worker structures or wait for threads during GC
		// as this can cause deadlocks. The Ruby GC will handle the thread objects.
		// Workers will see the shutdown flag and exit cleanly.
	}
}

// Size functions for Ruby GC
static size_t worker_pool_size(const void *ptr) {
	return sizeof(struct IO_Event_WorkerPool);
}

// Ruby TypedData structures
static const rb_data_type_t IO_Event_WorkerPool_type = {
	"IO::Event::WorkerPool",
	{0, worker_pool_free, worker_pool_size,},
	0, 0, RUBY_TYPED_FREE_IMMEDIATELY
};

// Helper function to enqueue work (must be called with mutex held)
static void enqueue_work(struct IO_Event_WorkerPool *pool, struct IO_Event_WorkerPool_Work *work) {
	if (pool->work_queue_tail) {
		pool->work_queue_tail->next = work;
	} else {
		pool->work_queue = work;
	}
	pool->work_queue_tail = work;
}

// Helper function to dequeue work (must be called with mutex held)
static struct IO_Event_WorkerPool_Work *dequeue_work(struct IO_Event_WorkerPool *pool) {
	struct IO_Event_WorkerPool_Work *work = pool->work_queue;
	if (work) {
		pool->work_queue = work->next;
		if (!pool->work_queue) {
			pool->work_queue_tail = NULL;
		}
		work->next = NULL; // Clear the next pointer for safety
	}
	return work;
}

// Unblock function to interrupt a specific worker.
static void worker_unblock_func(void *_worker) {
	struct IO_Event_WorkerPool_Worker *worker = (struct IO_Event_WorkerPool_Worker *)_worker;
	struct IO_Event_WorkerPool *pool = worker->pool;
	
	// Mark this specific worker as interrupted
	pthread_mutex_lock(&pool->mutex);
	worker->interrupted = true;
	pthread_cond_broadcast(&pool->work_available);
	pthread_mutex_unlock(&pool->mutex);
	
	// If there's a currently executing blocking operation, cancel it
	if (worker->current_blocking_operation) {
		rb_fiber_scheduler_blocking_operation_cancel(worker->current_blocking_operation);
	}
}

// Function to wait for work and execute it without GVL.
static void *worker_wait_and_execute(void *_worker) {
	struct IO_Event_WorkerPool_Worker *worker = (struct IO_Event_WorkerPool_Worker *)_worker;
	struct IO_Event_WorkerPool *pool = worker->pool;
	
	while (true) {
		struct IO_Event_WorkerPool_Work *work = NULL;
		
		pthread_mutex_lock(&pool->mutex);
		
		// Wait for work, shutdown, or interruption
		while (!pool->work_queue && !pool->shutdown && !worker->interrupted) {
			pthread_cond_wait(&pool->work_available, &pool->mutex);
		}
		
		if (pool->shutdown || worker->interrupted) {
			pthread_mutex_unlock(&pool->mutex);
			break;
		}
		
		work = dequeue_work(pool);
		
		pthread_mutex_unlock(&pool->mutex);
		
		// Execute work WITHOUT GVL (this is the whole point!)
		if (work) {
			worker->current_blocking_operation = work->blocking_operation;
			rb_fiber_scheduler_blocking_operation_execute(work->blocking_operation);
			worker->current_blocking_operation = NULL;
		}

		return work;
	}
	
	return NULL; // Shutdown signal
}

static VALUE worker_thread_func(void *_worker) {
	struct IO_Event_WorkerPool_Worker *worker = (struct IO_Event_WorkerPool_Worker *)_worker;
	
	while (true) {
		// Wait for work and execute it without holding GVL
		struct IO_Event_WorkerPool_Work *work = (struct IO_Event_WorkerPool_Work *)rb_thread_call_without_gvl(worker_wait_and_execute, worker, worker_unblock_func, worker);
		
		if (!work) {
			// Shutdown signal received
			break;
		}

		// Protected by GVL:
		work->completed = true;
		worker->pool->completed_count++;
		
		// Work was executed without GVL, now unblock the waiting fiber (we have GVL here)
		rb_fiber_scheduler_unblock(work->scheduler, work->blocker, work->fiber);
	}
	
	return Qnil;
}

// Create a new worker thread
static int create_worker_thread(struct IO_Event_WorkerPool *pool) {
	if (pool->current_worker_count >= pool->maximum_worker_count) {
		return -1;
	}
	
		struct IO_Event_WorkerPool_Worker *worker = malloc(sizeof(struct IO_Event_WorkerPool_Worker));
	if (!worker) {
		return -1;
	}
	
	worker->pool = pool;
	worker->interrupted = false;
	worker->current_blocking_operation = NULL;
	worker->next = pool->workers;
	
	worker->thread = rb_thread_create(worker_thread_func, worker);
	if (NIL_P(worker->thread)) {
		free(worker);
		return -1;
	}
	
	pool->workers = worker;
	pool->current_worker_count++;
	
	return 0;
}

// Ruby constructor for WorkerPool
static VALUE worker_pool_initialize(int argc, VALUE *argv, VALUE self) {
	size_t maximum_worker_count = 1; // Default
	
	// Extract keyword arguments
	VALUE kwargs = Qnil;
	VALUE rb_maximum_worker_count = Qnil;
	
	rb_scan_args(argc, argv, "0:", &kwargs);
	
	if (!NIL_P(kwargs)) {
		VALUE kwvals[1];
		ID kwkeys[1] = {id_maximum_worker_count};
		rb_get_kwargs(kwargs, kwkeys, 0, 1, kwvals);
		rb_maximum_worker_count = kwvals[0];
	}
	
	if (!NIL_P(rb_maximum_worker_count)) {
		maximum_worker_count = NUM2SIZET(rb_maximum_worker_count);
		if (maximum_worker_count == 0) {
			rb_raise(rb_eArgError, "maximum_worker_count must be greater than 0!");
		}
	}
	
	// Get the pool that was allocated by worker_pool_allocate
	struct IO_Event_WorkerPool *pool;
	TypedData_Get_Struct(self, struct IO_Event_WorkerPool, &IO_Event_WorkerPool_type, pool);
	
	if (!pool) {
		rb_raise(rb_eRuntimeError, "WorkerPool allocation failed!");
	}
	
	pthread_mutex_init(&pool->mutex, NULL);
	pthread_cond_init(&pool->work_available, NULL);
	
	pool->work_queue = NULL;
	pool->work_queue_tail = NULL;
	pool->workers = NULL;
	pool->current_worker_count = 0;
	pool->maximum_worker_count = maximum_worker_count;
	pool->call_count = 0;
	pool->completed_count = 0;
	pool->cancelled_count = 0;
	pool->shutdown = false;
	
	// Create initial workers
	for (size_t i = 0; i < maximum_worker_count; i++) {
		if (create_worker_thread(pool) != 0) {
			// Just set the maximum_worker_count for debugging, don't fail completely
			// worker_pool_free(pool);
			// rb_raise(rb_eRuntimeError, "Failed to create workers");
			break;
		}
	}
	
	return self;
}

static VALUE worker_pool_work_begin(VALUE _work) {
	struct IO_Event_WorkerPool_Work *work = (void*)_work;

	if (DEBUG) fprintf(stderr, "worker_pool_work_begin:rb_fiber_scheduler_block work=%p\n", work);
	rb_fiber_scheduler_block(work->scheduler, work->blocker, Qnil);

	return Qnil;
}

// Ruby method to submit work and wait for completion
static VALUE worker_pool_call(VALUE self, VALUE _blocking_operation) {
	struct IO_Event_WorkerPool *pool;
	TypedData_Get_Struct(self, struct IO_Event_WorkerPool, &IO_Event_WorkerPool_type, pool);
	
	if (pool->shutdown) {
		rb_raise(rb_eRuntimeError, "Worker pool is shut down!");
	}
	
	// Increment call count (protected by GVL)
	pool->call_count++;
	
	// Get current fiber and scheduler
	VALUE fiber = rb_fiber_current();
	VALUE scheduler = rb_fiber_scheduler_current();
	if (NIL_P(scheduler)) {
		rb_raise(rb_eRuntimeError, "WorkerPool requires a fiber scheduler!");
	}
	
	// Extract blocking operation handle
	rb_fiber_scheduler_blocking_operation_t *blocking_operation = rb_fiber_scheduler_blocking_operation_extract(_blocking_operation);
	
	if (!blocking_operation) {
		rb_raise(rb_eArgError, "Invalid blocking operation!");
	}
	
	// Create work item
	struct IO_Event_WorkerPool_Work work = {
		.blocking_operation = blocking_operation,
		.completed = false,
		.scheduler = scheduler,
		.blocker = self,
		.fiber = fiber,
		.next = NULL
	};
		
	// Enqueue work:
	pthread_mutex_lock(&pool->mutex);
	enqueue_work(pool, &work);
	pthread_cond_signal(&pool->work_available);
	pthread_mutex_unlock(&pool->mutex);
	
	// Block the current fiber until work is completed:
	int state;
	while (true) {
		rb_protect(worker_pool_work_begin, (VALUE)&work, &state);

		if (work.completed) {
			break;
		} else {
			if (DEBUG) fprintf(stderr, "worker_pool_call:rb_fiber_scheduler_blocking_operation_cancel\n");
			rb_fiber_scheduler_blocking_operation_cancel(blocking_operation);
			// The work was not completed, we need to wait for it to be completed.
		}
	}
	
	if (state) {
		rb_jump_tag(state);
	} else {
		return Qtrue;
	}
}

static VALUE worker_pool_allocate(VALUE klass) {
	struct IO_Event_WorkerPool *pool;
	VALUE self = TypedData_Make_Struct(klass, struct IO_Event_WorkerPool, &IO_Event_WorkerPool_type, pool);
	
	// Initialize to NULL/zero so we can detect uninitialized pools
	memset(pool, 0, sizeof(struct IO_Event_WorkerPool));
	
	return self;
}

// Ruby method to close the worker pool
static VALUE worker_pool_close(VALUE self) {
	struct IO_Event_WorkerPool *pool;
	TypedData_Get_Struct(self, struct IO_Event_WorkerPool, &IO_Event_WorkerPool_type, pool);
	
	if (!pool) {
		rb_raise(rb_eRuntimeError, "WorkerPool not initialized!");
	}
	
	if (pool->shutdown) {
		return Qnil; // Already closed
	}
	
	// Signal shutdown to all workers
	pthread_mutex_lock(&pool->mutex);
	pool->shutdown = true;
	pthread_cond_broadcast(&pool->work_available);
	pthread_mutex_unlock(&pool->mutex);
	
	// Wait for all worker threads to finish
	struct IO_Event_WorkerPool_Worker *worker = pool->workers;
	while (worker) {
		if (!NIL_P(worker->thread)) {
			rb_funcall(worker->thread, rb_intern("join"), 0);
		}
		worker = worker->next;
	}
	
	// Clean up worker structures
	worker = pool->workers;
	while (worker) {
		struct IO_Event_WorkerPool_Worker *next = worker->next;
		free(worker);
		worker = next;
	}
	pool->workers = NULL;
	pool->current_worker_count = 0;
	
	// Clean up mutex and condition variable
	pthread_mutex_destroy(&pool->mutex);
	pthread_cond_destroy(&pool->work_available);
	
	return Qnil;
}

// Test helper: get pool statistics for debugging/testing
static VALUE worker_pool_statistics(VALUE self) {
	struct IO_Event_WorkerPool *pool;
	TypedData_Get_Struct(self, struct IO_Event_WorkerPool, &IO_Event_WorkerPool_type, pool);
	
	if (!pool) {
		rb_raise(rb_eRuntimeError, "WorkerPool not initialized!");
	}
	
	VALUE stats = rb_hash_new();
	rb_hash_aset(stats, ID2SYM(rb_intern("current_worker_count")), SIZET2NUM(pool->current_worker_count));
	rb_hash_aset(stats, ID2SYM(rb_intern("maximum_worker_count")), SIZET2NUM(pool->maximum_worker_count));
	rb_hash_aset(stats, ID2SYM(rb_intern("call_count")), SIZET2NUM(pool->call_count));
	rb_hash_aset(stats, ID2SYM(rb_intern("completed_count")), SIZET2NUM(pool->completed_count));
	rb_hash_aset(stats, ID2SYM(rb_intern("cancelled_count")), SIZET2NUM(pool->cancelled_count));
	rb_hash_aset(stats, ID2SYM(rb_intern("shutdown")), pool->shutdown ? Qtrue : Qfalse);
	
	// Count work items in queue (only if properly initialized)
	if (pool->maximum_worker_count > 0) {
		pthread_mutex_lock(&pool->mutex);
		size_t current_queue_size = 0;
		struct IO_Event_WorkerPool_Work *work = pool->work_queue;
		while (work) {
			current_queue_size++;
			work = work->next;
		}
		pthread_mutex_unlock(&pool->mutex);
		rb_hash_aset(stats, ID2SYM(rb_intern("current_queue_size")), SIZET2NUM(current_queue_size));
	} else {
		rb_hash_aset(stats, ID2SYM(rb_intern("current_queue_size")), SIZET2NUM(0));
	}
	
	return stats;
}

void Init_IO_Event_WorkerPool(VALUE IO_Event) {
	// Initialize symbols
	id_maximum_worker_count = rb_intern("maximum_worker_count");
	
	IO_Event_WorkerPool = rb_define_class_under(IO_Event, "WorkerPool", rb_cObject);
	rb_define_alloc_func(IO_Event_WorkerPool, worker_pool_allocate);

	rb_define_method(IO_Event_WorkerPool, "initialize", worker_pool_initialize, -1);
	rb_define_method(IO_Event_WorkerPool, "call", worker_pool_call, 1);
	rb_define_method(IO_Event_WorkerPool, "close", worker_pool_close, 0);
	
	rb_define_method(IO_Event_WorkerPool, "statistics", worker_pool_statistics, 0);
	
	// Initialize test functions
	Init_IO_Event_WorkerPool_Test(IO_Event_WorkerPool);
}
