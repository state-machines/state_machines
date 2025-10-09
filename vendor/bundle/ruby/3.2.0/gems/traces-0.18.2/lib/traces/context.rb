# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2025, by Samuel Williams.

require "securerandom"

module Traces
	# A generic representation of the current tracing context.
	class Context
		# Parse a string representation of a distributed trace.
		# @parameter parent [String] The parent trace context.
		# @parameter state [Array(String)] Any attached trace state.
		def self.parse(parent, state = nil, baggage = nil, **options)
			version, trace_id, parent_id, flags = parent.split("-")
			
			if version == "00" && trace_id && parent_id && flags
				flags = Integer(flags, 16)
				
				if state.is_a?(String)
					state = state.split(",")
				end
				
				if state
					state = state.map{|item| item.split("=")}.to_h
				end
				
				if baggage.is_a?(String)
					baggage = baggage.split(",")
				end
				
				if baggage
					baggage = baggage.map{|item| item.split("=")}.to_h
				end
				
				self.new(trace_id, parent_id, flags, state, baggage, **options)
			end
		end
		
		# Create a local trace context which is likely to be globally unique.
		# @parameter flags [Integer] Any trace context flags.
		def self.local(flags = 0, **options)
			self.new(SecureRandom.hex(16), SecureRandom.hex(8), flags, **options)
		end
		
		# Nest a local trace context in an optional parent context.
		# @parameter parent [Context] An optional parent context.
		def self.nested(parent, flags = 0)
			if parent
				parent.nested(flags)
			else
				self.local(flags)
			end
		end
		
		SAMPLED = 0x01
		
		# Initialize the trace context.
		# @parameter trace_id [String] The ID of the whole trace forest.
		# @parameter parent_id [String] The ID of this operation as known by the caller (sometimes referred to as the span ID).
		# @parameter flags [Integer] An 8-bit field that controls tracing flags such as sampling, trace level, etc.
		# @parameter state [Hash] Additional vendor-specific trace identification information.
		# @parameter remote [Boolean] Whether this context was created from a distributed trace header.
		def initialize(trace_id, parent_id, flags, state = nil, baggage = nil, remote: false)
			@trace_id = trace_id
			@parent_id = parent_id
			@flags = flags
			@state = state
			@baggage = baggage
			@remote = remote
		end
		
		# Create a new nested trace context in which spans can be recorded.
		def nested(flags = @flags)
			Context.new(@trace_id, SecureRandom.hex(8), flags, @state, @baggage, remote: @remote)
		end
		
		# The ID of the whole trace forest and is used to uniquely identify a distributed trace through a system. It is represented as a 16-byte array, for example, 4bf92f3577b34da6a3ce929d0e0e4736. All bytes as zero (00000000000000000000000000000000) is considered an invalid value.
		attr :trace_id
		
		# The ID of this operation as known by the caller (in some tracing systems, this is known as the span-id, where a span is the execution of a client operation). It is represented as an 8-byte array, for example, 00f067aa0ba902b7. All bytes as zero (0000000000000000) is considered an invalid value.
		attr :parent_id
		
		# An 8-bit field that controls tracing flags such as sampling, trace level, etc. These flags are recommendations given by the caller rather than strict rules.
		attr :flags
		
		# Provides additional vendor-specific trace identification information across different distributed tracing systems.
		attr :state
		
		# Provides additional application-specific trace identification information across different distributed tracing systems.
		attr :baggage
		
		# Denotes that the caller may have recorded trace data. When unset, the caller did not record trace data out-of-band.
		def sampled?
			(@flags & SAMPLED) != 0
		end
		
		# Whether this context was created from a distributed trace header.
		def remote?
			@remote
		end
		
		# A string representation of the trace context (excluding trace state).
		def to_s
			"00-#{@trace_id}-#{@parent_id}-#{@flags.to_s(16)}"
		end
		
		# Convert the trace context to a JSON representation, including trace state.
		def as_json
			{
				trace_id: @trace_id,
				parent_id: @parent_id,
				flags: @flags,
				state: @state,
				baggage: @baggage,
				remote: @remote
			}
		end
		
		# Convert the trace context to a JSON string.
		def to_json(...)
			as_json.to_json(...)
		end
		
		# Inject the trace context into the headers, including the `"traceparent"`, `"tracestate"`, and `"baggage"` headers.
		#
		# @parameter headers [Hash] The headers hash to inject the trace context into.
		#
		# @returns [Hash] The modified headers hash.
		def inject(headers)
			headers["traceparent"] = self.to_s
			
			if @state and !@state.empty?
				headers["tracestate"] = self.state.map{|key, value| "#{key}=#{value}"}.join(",")
			end
			
			if @baggage and !@baggage.empty?
				headers["baggage"] = self.baggage.map{|key, value| "#{key}=#{value}"}.join(",")
			end
			
			return headers
		end
		
		# Extract the trace context from the headers.
		#
		# The `"traceparent"` header is a string representation of the trace context. If it is an Array, the first element is used, otherwise it is used as is.
		# The `"tracestate"` header is a string representation of the trace state. If it is a String, it is split on commas before being processed.
		# The `"baggage"` header is a string representation of the baggage. If it is a String, it is split on commas before being processed.
		#
		# @parameter headers [Hash] The headers hash containing trace context.
		# @returns [Context | Nil] The extracted trace context, or nil if no valid context found.
		# @raises [ArgumentError] If headers is not a Hash or contains malformed trace data.
		def self.extract(headers)
			if traceparent = headers["traceparent"]
				if traceparent.is_a?(Array)
					traceparent = traceparent.first
				end
				
				if traceparent.empty?
					return nil
				end
				
				tracestate = headers["tracestate"]
				baggage = headers["baggage"]
				
				return self.parse(traceparent, tracestate, baggage, remote: true)
			end
		end
	end
end
