# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

module IO::Event
	# A thread safe synchronisation primative.
	class Interrupt
		def self.attach(selector)
			self.new(selector)
		end
		
		def initialize(selector)
			@selector = selector
			@input, @output = ::IO.pipe
			
			@fiber = Fiber.new do
				while true
					if @selector.io_wait(@fiber, @input, IO::READABLE)
						@input.read_nonblock(1)
					end
				end
			end
			
			@fiber.transfer
		end
		
		# Send a sigle byte interrupt.
		def signal
			@output.write(".")
			@output.flush
		rescue IOError
			# Ignore.
		end
		
		def close
			@input.close
			@output.close
			# @fiber.raise(::Interrupt)
		end
	end
	
	private_constant :Interrupt
end
