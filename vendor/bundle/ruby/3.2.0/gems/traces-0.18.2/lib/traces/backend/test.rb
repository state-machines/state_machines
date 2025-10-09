# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2025, by Samuel Williams.

require_relative "../context"

require "fiber"

Fiber.attr_accessor :traces_backend_context

module Traces
	module Backend
		# A backend which validates interface usage.
		module Test
			# A span which validates tag assignment.
			class Span
				# Initialize a new span.
				# @parameter context [Context] The context in which the span is recorded.
				def initialize(context)
					@context = context
				end
				
				# @attribute [Context] The context in which the span is recorded.
				attr :context
				
				# Assign some metadata to the span.
				# @parameter key [String] The metadata key.
				# @parameter value [Object] The metadata value. Should be coercable to a string.
				def []= key, value
					unless key.is_a?(String) || key.is_a?(Symbol)
						raise ArgumentError, "Invalid attribute key (must be String or Symbol): #{key.inspect}!"
					end
					
					begin
						String(value)
					rescue
						raise ArgumentError, "Invalid attribute value (must be convertible to String): #{value.inspect}!"
					end
				end
			end
			
			# The test backend interface.
			module Interface
				# Trace the given block of code and validate the interface usage.
				# @parameter name [String] A useful name/annotation for the recorded span.
				# @parameter resource [String] The context in which the trace operation is occuring.
				# @parameter attributes [Hash] Metadata for the recorded span.
				def trace(name, attributes: nil, &block)
					unless block_given?
						raise ArgumentError, "No block given!"
					end
					
					unless name.is_a?(String)
						raise ArgumentError, "Invalid name (must be String): #{name.inspect}!"
					end
					
					context = Context.nested(Fiber.current.traces_backend_context)
					
					span = Span.new(context)
					
					# Ensure the attributes are valid and follow the requirements:
					attributes&.each do |key, value|
						span[key] = value
					end
					
					Fiber.current.traces_backend_context = context
					
					if block.arity.zero?
						yield
					else
						yield span
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
		
		Interface = Test::Interface
	end
end
