# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

require_relative "../support"

module IO::Event
	# @namespace
	module Debug
		# Enforces the selector interface and delegates operations to a wrapped selector instance.
		#
		# You can enable this in the default selector by setting the `IO_EVENT_DEBUG_SELECTOR` environment variable. In addition, you can log all selector operations to a file by setting the `IO_EVENT_DEBUG_SELECTOR_LOG` environment variable. This is useful for debugging and understanding the behavior of the event loop.
		class Selector
			# Wrap the given selector with debugging.
			#
			# @parameter selector [Selector] The selector to wrap.
			# @parameter env [Hash] The environment to read configuration from.
			def self.wrap(selector, env = ENV)
				log = nil
				
				if log_path = env["IO_EVENT_DEBUG_SELECTOR_LOG"]
					log = File.open(log_path, "w")
				end
				
				return self.new(selector, log: log)
			end
			
			# Initialize the debug selector with the given selector and optional log.
			#
			# @parameter selector [Selector] The selector to wrap.
			# @parameter log [IO] The log to write debug messages to.
			def initialize(selector, log: nil)
				@selector = selector
				
				@readable = {}
				@writable = {}
				@priority = {}
				
				unless Fiber.current == selector.loop
					Kernel::raise "Selector must be initialized on event loop fiber!"
				end
				
				@log = log
			end
			
			# The idle duration of the underlying selector.
			#
			# @returns [Numeric] The idle duration.
			def idle_duration
				@selector.idle_duration
			end
			
			# The current time.
			#
			# @returns [Numeric] The current time.
			def now
				Process.clock_gettime(Process::CLOCK_MONOTONIC)
			end
			
			# Log the given message.
			#
			# @asynchronous Will block the calling fiber and the entire event loop.
			def log(message)
				return unless @log
				
				Fiber.blocking do
					@log.puts("T+%10.1f; %s" % [now, message])
				end
			end
			
			# Wakeup the the selector.
			def wakeup
				@selector.wakeup
			end
			
			# Close the selector.
			def close
				log("Closing selector")
				
				if @selector.nil?
					Kernel::raise "Selector already closed!"
				end
				
				@selector.close
				@selector = nil
			end
			
			# Transfer from the calling fiber to the selector.
			def transfer
				log("Transfering to event loop")
				@selector.transfer
			end
			
			# Resume the given fiber with the given arguments.
			def resume(*arguments)
				log("Resuming fiber with #{arguments.inspect}")
				@selector.resume(*arguments)
			end
			
			# Yield to the selector.
			def yield
				log("Yielding to event loop")
				@selector.yield
			end
			
			# Push the given fiber to the selector ready list, such that it will be resumed on the next call to {select}.
			#
			# @parameter fiber [Fiber] The fiber that is ready.
			def push(fiber)
				log("Pushing fiber #{fiber.inspect} to ready list")
				@selector.push(fiber)
			end
			
			# Raise the given exception on the given fiber.
			#
			# @parameter fiber [Fiber] The fiber to raise the exception on.
			# @parameter arguments [Array] The arguments to use when raising the exception.
			def raise(fiber, *arguments)
				log("Raising exception on fiber #{fiber.inspect} with #{arguments.inspect}")
				@selector.raise(fiber, *arguments)
			end
			
			# Check if the selector is ready.
			#
			# @returns [Boolean] Whether the selector is ready.
			def ready?
				@selector.ready?
			end
			
			# Wait for the given process, forwarded to the underlying selector.
			def process_wait(*arguments)
				log("Waiting for process with #{arguments.inspect}")
				@selector.process_wait(*arguments)
			end
			
			# Wait for the given IO, forwarded to the underlying selector.
			def io_wait(fiber, io, events)
				log("Waiting for IO #{io.inspect} for events #{events.inspect}")
				@selector.io_wait(fiber, io, events)
			end
			
			# Read from the given IO, forwarded to the underlying selector.
			def io_read(fiber, io, buffer, length, offset = 0)
				log("Reading from IO #{io.inspect} with buffer #{buffer}; length #{length} offset #{offset}")
				@selector.io_read(fiber, io, buffer, length, offset)
			end
			
			# Write to the given IO, forwarded to the underlying selector.
			def io_write(fiber, io, buffer, length, offset = 0)
				log("Writing to IO #{io.inspect} with buffer #{buffer}; length #{length} offset #{offset}")
				@selector.io_write(fiber, io, buffer, length, offset)
			end
			
			# Forward the given method to the underlying selector.
			def respond_to?(name, include_private = false)
				@selector.respond_to?(name, include_private)
			end
			
			# Select for the given duration, forwarded to the underlying selector.
			def select(duration = nil)
				log("Selecting for #{duration.inspect}")
				unless Fiber.current == @selector.loop
					Kernel::raise "Selector must be run on event loop fiber!"
				end
				
				@selector.select(duration)
			end
		end
	end
end
