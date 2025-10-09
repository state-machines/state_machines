# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024-2025, by Samuel Williams.

require_relative "priority_heap"

class IO
	module Event
		# An efficient sorted set of timers.
		class Timers
			# A handle to a scheduled timer.
			class Handle
				# Initialize the handle with the given time and block.
				#
				# @parameter time [Float] The time at which the block should be called.
				# @parameter block [Proc] The block to call.
				def initialize(time, block)
					@time = time
					@block = block
				end
				
				# @attribute [Float] The time at which the block should be called.
				attr :time
				
				# @attribute [Proc | Nil] The block to call when the timer fires.
				attr :block
				
				# Compare the handle with another handle.
				#
				# @parameter other [Handle] The other handle to compare with.
				# @returns [Boolean] Whether the handle is less than the other handle.
				def < other
					@time < other.time
				end
				
				# Compare the handle with another handle.
				#
				# @parameter other [Handle] The other handle to compare with.
				# @returns [Boolean] Whether the handle is greater than the other handle.
				def > other
					@time > other.time
				end
				
				# Invoke the block.
				def call(...)
					@block.call(...)
				end
				
				# Cancel the timer.
				def cancel!
					@block = nil
				end
				
				# @returns [Boolean] Whether the timer has been cancelled.
				def cancelled?
					@block.nil?
				end
			end
			
			# Initialize the timers.
			def initialize
				@heap = PriorityHeap.new
				@scheduled = []
			end
			
			# @returns [Integer] The number of timers in the heap.
			def size
				flush!
				
				return @heap.size
			end
			
			# Schedule a block to be called at a specific time in the future.
			#
			# @parameter time [Float] The time at which the block should be called, relative to {#now}.
			# @parameter block [Proc] The block to call.
			def schedule(time, block)
				handle = Handle.new(time, block)
				
				@scheduled << handle
				
				return handle
			end
			
			# Schedule a block to be called after a specific time offset, relative to the current time as returned by {#now}.
			#
			# @parameter offset [#to_f] The time offset from the current time at which the block should be called.
			# @yields {|now| ...} When the timer fires.
			def after(offset, &block)
				schedule(self.now + offset.to_f, block)
			end
			
			# Compute the time interval until the next timer fires.
			#
			# @parameter now [Float] The current time.
			# @returns [Float | Nil] The time interval until the next timer fires, if any.
			def wait_interval(now = self.now)
				flush!
				
				while handle = @heap.peek
					if handle.cancelled?
						@heap.pop
					else
						return handle.time - now
					end
				end
			end
			
			# @returns [Float] The current time.
			def now
				::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
			end
			
			# Fire all timers that are ready to fire.
			#
			# @parameter now [Float] The current time.
			def fire(now = self.now)
				# Flush scheduled timers into the heap:
				flush!
				
				# Get the earliest timer:
				while handle = @heap.peek
					if handle.cancelled?
						@heap.pop
					elsif handle.time <= now
						# Remove the earliest timer from the heap:
						@heap.pop
						
						# Call the block:
						handle.call(now)
					else
						break
					end
				end
			end
			
			# Flush all scheduled timers into the heap.
			#
			# This is a small optimization which assumes that most timers (timeouts) will be cancelled.
			protected def flush!
				while handle = @scheduled.pop
					@heap.push(handle) unless handle.cancelled?
				end
			end
		end
	end
end
