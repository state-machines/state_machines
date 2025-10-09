# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.

require_relative "../format"
require "time"
require "fiber/annotation"

module Console
	module Output
		# Serialize log messages in a structured format.
		class Serialized
			# Create a new serialized output.
			#
			# @parameter io [IO] The output stream.
			# @parameter format [Console::Format] The format to use for serializing log messages.
			# @parameter options [Hash] Additional options to customize the output.
			def initialize(stream, format: Format.default, **options)
				@stream = stream
				@format = format
			end
			
			# This a final output that then writes to an IO object.
			def last_output
				self
			end
			
			# @attribute [IO] The output stream.
			attr :stream
			
			# @attribute [Console::Format] The format to use for serializing log messages.
			attr :format
			
			# Serialize the given record.
			#
			# @parameter record [Hash] The record to serialize.
			# @returns [String] The serialized record.
			def dump(record)
				@format.dump(record)
			end
			
			# Output the given log message.
			#
			# @parameter subject [String] The subject of the log message.
			# @parameter arguments [Array] The arguments to log.
			# @parameter severity [Symbol] The severity of the log message.
			# @parameter options [Hash] Additional options.
			# @parameter block [Proc] An optional block used to generate the log message.
			def call(subject = nil, *arguments, severity: UNKNOWN, **options, &block)
				record = {
					time: Time.now.iso8601,
					severity: severity,
					pid: Process.pid,
					oid: subject.object_id,
					fiber_id: Fiber.current.object_id,
				}
				
				# We want to log just a brief subject:
				if subject.is_a?(String)
					record[:subject] = subject
				elsif subject.is_a?(Module)
					record[:subject] = subject.name
				else
					record[:subject] = subject.class.name
				end
				
				if annotation = Fiber.current.annotation
					record[:annotation] = annotation
				end
				
				message = arguments
				
				if block_given?
					if block.arity.zero?
						message << yield
					else
						buffer = StringIO.new
						yield buffer
						message << buffer.string
					end
				end
				
				if message.size == 1
					record[:message] = message.first
				elsif message.any?
					record[:message] = message
				end
				
				record.update(options)
				
				@stream.write(self.dump(record) << "\n")
			end
		end
		
		# @deprecated This is a legacy constant, please use `Serialized` instead.
		JSON = Serialized
	end
end
