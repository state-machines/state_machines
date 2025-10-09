# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2025, by Samuel Williams.

require_relative "../context"

require "fiber"

Fiber.attr_accessor :traces_backend_context

module Traces
	module Backend
		# A backend which logs all spans to the Capture logger output.
		module Capture
			# A span which validates tag assignment.
			class Span
				# Initialize a new span.
				# @parameter context [Context] The context in which the span is recorded.
				# @parameter name [String] A useful name/annotation for the recorded span.
				# @parameter resource [String] The "resource" that the span is associated with.
				# @parameter attributes [Hash] Metadata for the recorded span.
				def initialize(context, name, attributes)
					@context = context
					@name = name
					@attributes = attributes
				end
				
				attr :context
				attr :name
				attr :attributes
				
				# Assign some metadata to the span.
				# @parameter key [String] The metadata key.
				# @parameter value [Object] The metadata value. Should be coercable to a string.
				def []= key, value
					@attributes[key] = value
				end
				
				# Convert the span to a JSON representation.
				def as_json
					{
						name: @name,
						attributes: @attributes,
						context: @context.as_json
					}
				end
				
				# Convert the span to a JSON string.
				def to_json(...)
					as_json.to_json(...)
				end
			end
			
			# All captured spans.
			def self.spans
				@spans ||= []
			end
			
			# The capture backend interface.
			module Interface
				# Trace the given block of code and log the execution.
				# @parameter name [String] A useful name/annotation for the recorded span.
				# @parameter attributes [Hash] Metadata for the recorded span.
				def trace(name, attributes: {}, &block)
					context = Context.nested(Fiber.current.traces_backend_context)
					Fiber.current.traces_backend_context = context
					
					span = Span.new(context, name, attributes)
					Capture.spans << span
					
					yield span
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
		
		Interface = Capture::Interface
	end
end
