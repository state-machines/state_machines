# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2025, by Samuel Williams.

require "logger"

module Console
	# @namespace
	module Compatible
		# A compatible interface for {::Logger} which can be used with {Console}.
		class Logger < ::Logger
			# A compatible log device which can be used with {Console}. Suitable for use with code which (incorrectly) assumes that the log device a public interface and has certain methods/behaviours.
			class LogDevice
				# Create a new log device.
				#
				# @parameter subject [String] The subject of the log messages.
				# @parameter output [Console::Interface] The output interface.
				def initialize(subject, output)
					@subject = subject
					@output = output
				end
				
				# Write a message to the log device.
				#
				# @parameter message [String] The message to write.
				def write(message)
					@output.call(@subject, message)
				end
				
				# Log a message with the given severity.
				#
				# @paraemter arguments [Array] The arguments to log.
				# @parameter options [Hash] Additional options.
				def call(*arguments, **options)
					@output.call(*arguments, **options)
				end
				
				# Reopen the log device. This is a no-op.
				def reopen
				end
				
				# Close the log device. This is a no-op.
				def close
				end
			end
			
			# Create a new (compatible) logger.
			#
			# @parameter subject [String] The subject of the log messages.
			# @parameter output [Console::Interface] The output interface.
			def initialize(subject, output = Console)
				super(nil)
				
				@progname = subject
				@logdev = LogDevice.new(subject, output)
			end
			
			# Log a message with the given severity.
			#
			# @parameter severity [Integer] The severity of the message.
			# @parameter message [String] The message to log.
			# @parameter progname [String] The program name.
			# @returns [Boolean] True if the message was logged.
			def add(severity, message = nil, progname = nil, **options)
				severity ||= UNKNOWN
				
				if @logdev.nil? or severity < level
					return true
				end
				
				if progname.nil?
					progname = @progname
				end
				
				if message.nil?
					if block_given?
						message = yield
					else
						message = progname
						progname = @progname
					end
				end
				
				@logdev.call(
					progname, message,
					**options,
					severity: format_severity(severity)
				)
				
				return true
			end
			
			# Format the severity.
			#
			# @parameter value [Integer] The severity value.
			# @returns [Symbol] The formatted severity.
			def format_severity(value)
				super.downcase.to_sym
			end
		end
	end
end
