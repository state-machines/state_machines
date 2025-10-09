# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024-2025, by Samuel Williams.

require_relative "wrapper"
require_relative "../event/failure"

module Console
	module Output
		# A wrapper for outputting failure messages, which can include exceptions.
		class Failure < Wrapper
			# Create a new failure output wrapper.
			def initialize(output, **options)
				super(output, **options)
			end
			
			# The exception must be either the last argument or passed as an option.
			#
			# @parameter subject [String] The subject of the message.
			# @parameter arguments [Array] The arguments to output.
			# @parameter exception [Exception] The exception to output.
			# @parameter options [Hash] Additional options to pass to the output.
			# @parameter block [Proc] An optional block to pass to the output.
			def call(subject = nil, *arguments, exception: nil, **options, &block)
				if exception.nil?
					last = arguments.last
					if last.is_a?(Exception)
						options[:event] = Event::Failure.for(last)
					end
				elsif exception.is_a?(Exception)
					options[:event] = Event::Failure.for(exception)
				else
					# We don't know what this is, so we just pass it through:
					options[:exception] = exception
				end
				
				super(subject, *arguments, **options, &block)
			end
		end
	end
end
