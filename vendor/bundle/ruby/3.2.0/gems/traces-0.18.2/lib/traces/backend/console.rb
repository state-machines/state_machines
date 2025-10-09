# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2025, by Samuel Williams.

require_relative "../context"

require "console"
require "fiber"

Fiber.attr_accessor :traces_backend_context

module Traces
	module Backend
		# A backend which logs all spans to the console logger output.
		module Console
			# A span which validates tag assignment.
			class Span
				# Initialize a new span.
				# @parameter context [Context] The context in which the span is recorded.
				# @parameter name [String] A useful name/annotation for the recorded span.
				def initialize(context, name)
					@context = context
					@name = name
				end
				
				# @attribute [Context] The context in which the span is recorded.
				attr :context
				
				# Assign some metadata to the span.
				# @parameter key [String] The metadata key.
				# @parameter value [Object] The metadata value. Should be coercable to a string.
				def []= key, value
					::Console.logger.info(@context, @name, "#{key} = #{value}")
				end
			end
			
			# The console backend interface.
			module Interface
				# Trace the given block of code and log the execution.
				# @parameter name [String] A useful name/annotation for the recorded span.
				# @parameter attributes [Hash] Metadata for the recorded span.
				def trace(name, attributes: {}, &block)
					context = Context.nested(Fiber.current.traces_backend_context)
					Fiber.current.traces_backend_context = context
					
					::Console.logger.info(self, name, attributes)
					
					if block.arity.zero?
						yield
					else
						yield Span.new(context, name)
					end
				end
				
				# Assign a trace context to the current execution scope.
				def trace_context= context
					Fiber.current.traces_backend_context = context
				end
				
				# Get a trace context from the current execution scope.
				def trace_context
					Fiber.current.traces_backend_context
				end
				
				# @returns [Boolean] Whether there is an active trace.
				def active?
					!!Fiber.current.traces_backend_context
				end
			end
		end
		
		Interface = Console::Interface
	end
end
