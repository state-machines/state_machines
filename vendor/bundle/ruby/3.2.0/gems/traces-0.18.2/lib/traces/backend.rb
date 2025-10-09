# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2025, by Samuel Williams.

require_relative "config"
require_relative "context"

module Traces
	# The backend implementation is responsible for recording and reporting traces.
	module Backend
	end
	
	# Capture the current trace context for remote propagation.
	#
	# This is a default implementation, which can be replaced by the backend.
	#
	# You should prefer to use the new `Traces.current_context` family of methods.
	#
	# @returns [Object] The current trace context.
	def self.trace_context
		nil
	end
	
	# Whether there is an active trace context.
	#
	# This is a default implementation, which can be replaced by the backend.
	#
	# @returns [Boolean] Whether there is an active trace.
	def self.active?
		!!self.trace_context
	end
	
	# Capture the current trace context for local propagation between execution contexts.
	#
	# This method returns the current trace context that can be safely passed between threads, fibers, or other execution contexts within the same process.
	#
	# The returned object is opaque, in other words, you should not make assumptions about its structure.
	#
	# This is a default implementation, which can be replaced by the backend.
	#
	# @returns [Context | Nil] The current trace context, or nil if no active trace.
	def self.current_context
		trace_context
	end
	
	# Execute a block within a specific trace context for local execution.
	#
	# This method is designed for propagating trace context between execution contexts within the same process (threads, fibers, etc.). It temporarily switches to the specified trace context for the duration of the block execution, then restores the previous context.
	#
	# When called without a block, permanently switches to the specified context. This enables manual context management for scenarios where automatic restoration isn't desired.
	#
	# This is a default implementation, which can be replaced by the backend.
	#
	# @parameter context [Context] A trace context obtained from `Traces.current_context`.
	# @yields {...} If a block is given, the block is executed within the specified trace context.
	def self.with_context(context)
		if block_given?
			# This implementation is not ideal but the best we can do with the current interface.
			previous_context = self.trace_context
			begin
				self.trace_context = context
				yield
			ensure
				self.trace_context = previous_context
			end
		else
			self.trace_context = context
		end
	end
	
	# Inject trace context into a headers hash for distributed propagation.
	#
	# This method adds W3C Trace Context headers (traceparent, tracestate) and W3C Baggage headers to the provided headers hash, enabling distributed tracing across service boundaries. The headers hash is mutated in place.
	#
	# This is a default implementation, which can be replaced by the backend.
	#
	# @parameter headers [Hash] The headers object to mutate with trace context headers.
	# @parameter context [Context] A trace context, or nil to use current context.
	# @returns [Hash | Nil] The headers hash, or nil if no context is available.
	def self.inject(headers = nil, context = nil)
		context ||= self.trace_context
		
		if context
			headers ||= Hash.new
			context.inject(headers)
		else
			headers = nil
		end
		
		return headers
	end
	
	# Extract trace context from headers for distributed propagation.
	#
	# The returned object is opaque, in other words, you should not make assumptions about its structure.
	#
	# This is a default implementation, which can be replaced by the backend.
	#
	# @parameter headers [Hash] The headers object containing trace context.
	# @returns [Context, nil] The extracted trace context, or nil if no valid context found.
	def self.extract(headers)
		Context.extract(headers)
	end
	
	Config::DEFAULT.require_backend
end
