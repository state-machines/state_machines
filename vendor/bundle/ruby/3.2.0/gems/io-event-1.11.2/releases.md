# Releases

## v1.11.2

  - Fix Windows build.

## v1.11.1

  - Fix `read_nonblock` when using the `URing` selector, which was not handling zero-length reads correctly. This allows reading available data without blocking.

## v1.11.0

### Introduce `IO::Event::WorkerPool` for off-loading blocking operations.

The {ruby IO::Event::WorkerPool} provides a mechanism for executing blocking operations on separate OS threads while properly integrating with Ruby's fiber scheduler and GVL (Global VM Lock) management. This enables true parallelism for CPU-intensive or blocking operations that would otherwise block the event loop.

``` ruby
# Fiber scheduler integration via blocking_operation_wait hook
class MyScheduler
	def initialize
		@worker_pool = IO::Event::WorkerPool.new
	end

  def blocking_operation_wait(operation)
    @worker_pool.call(operation)
  end
end

# Usage with automatic offloading
Fiber.set_scheduler(MyScheduler.new)
# Automatically offload `rb_nogvl(..., RB_NOGVL_OFFLOAD_SAFE)` to a background thread:
result = some_blocking_operation()
```

The implementation uses one or more background threads and a list of pending blocking operations. Those operations either execute through to completion or may be cancelled, which executes the "unblock function" provided to `rb_nogvl`.

## v1.10.2

  - Improved consistency of handling closed IO when invoking `#select`.

## v1.10.0

  - `IO::Event::Profiler` is moved to dedicated gem: [fiber-profiler](https://github.com/socketry/fiber-profiler).
  - Perform runtime checks for native selectors to ensure they are supported in the current environment. While compile-time checks determine availability, restrictions like seccomp and SELinux may still prevent them from working.

## v1.9.0

  - Improved `IO::Event::Profiler` for detecting stalls.

## v1.8.0

  - Detecting fibers that are stalling the event loop.

## v1.7.5

  - Fix `process_wait` race condition on EPoll that could cause a hang.
