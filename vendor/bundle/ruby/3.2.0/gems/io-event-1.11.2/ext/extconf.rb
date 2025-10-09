#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2025, by Samuel Williams.
# Copyright, 2023, by Math Ieu.
# Copyright, 2025, by Stanislav (Stas) Katkov.

return if RUBY_DESCRIPTION =~ /jruby/

require "mkmf"

gem_name = File.basename(__dir__)
extension_name = "IO_Event"

# dir_config(extension_name)

append_cflags(["-Wall", "-Wno-unknown-pragmas", "-std=c99"])

if ENV.key?("RUBY_DEBUG")
	$stderr.puts "Enabling debug mode..."

	append_cflags(["-DRUBY_DEBUG", "-O0"])
end

$srcs = ["io/event/event.c", "io/event/time.c", "io/event/fiber.c", "io/event/selector/selector.c"]
$VPATH << "$(srcdir)/io/event"
$VPATH << "$(srcdir)/io/event/selector"

have_func("rb_ext_ractor_safe")
have_func("&rb_fiber_transfer")

if have_library("uring") and have_header("liburing.h")
	# We might want to consider using this in the future:
	# have_func("io_uring_submit_and_wait_timeout", "liburing.h")

	$srcs << "io/event/selector/uring.c"
end

if have_header("sys/epoll.h")
	$srcs << "io/event/selector/epoll.c"
end

if have_header("sys/event.h")
	$srcs << "io/event/selector/kqueue.c"
end

have_header("sys/wait.h")

have_header("sys/eventfd.h")
$srcs << "io/event/interrupt.c"

have_func("rb_io_descriptor")
have_func("&rb_process_status_wait")
have_func("rb_fiber_current")
have_func("&rb_fiber_raise")
have_func("epoll_pwait2")

have_header("ruby/io/buffer.h")

# Feature detection for blocking operation support
if have_func("rb_fiber_scheduler_blocking_operation_extract")
	# Feature detection for pthread support (needed for WorkerPool)
	if have_header("pthread.h")
		append_cflags(["-DHAVE_IO_EVENT_WORKER_POOL"])
		$srcs << "io/event/worker_pool.c"
		$srcs << "io/event/worker_pool_test.c"
	end
end

if ENV.key?("RUBY_SANITIZE")
	$stderr.puts "Enabling sanitizers..."

	# Add address and undefined behaviour sanitizers:
	append_cflags(["-fsanitize=address", "-fsanitize=undefined", "-fno-omit-frame-pointer"])
	$LDFLAGS << " -fsanitize=address -fsanitize=undefined"
end

create_header

# Generate the makefile to compile the native binary into `lib`:
create_makefile(extension_name)
