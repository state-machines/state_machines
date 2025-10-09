# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.

require_relative "filter"
require_relative "output/failure"

module Console
	# A buffer which captures all logged messages into a buffer.
	class Capture
		# Create a new log capture buffer.
		def initialize
			@records = []
			@verbose = false
		end
		
		# @attribute [Array(Hash)] All records captured by this buffer.
		attr :records
		
		# @deprecated Use {records} instead of {buffer}.
		alias buffer records
		
		# @deprecated Use {records} instead of {to_a}.
		alias to_a records
		
		# @attribute [Boolean] If true, the buffer will capture verbose messages.
		attr :verbose
		
		# Whether the buffer includes any records with the given subject or message pattern.
		#
		# @returns [Boolean] True if the buffer includes any records with the given pattern.
		def include?(pattern)
			@records.any? do |record|
				record[:subject].to_s&.match?(pattern) or record[:message].to_s&.match?(pattern)
			end
		end
		
		# Iterate over all records in the buffer.
		#
		# @yields {|record| ...} each record in the buffer.
		# 	@parameter record [Hash] The record itself.
		def each(&block)
			@records.each(&block)
		end
		
		include Enumerable
		
		# @returns [Hash] The first record in the buffer.
		def first
			@records.first
		end
		
		# @returns [Hash] The last record in the buffer.
		def last
			@records.last
		end
		
		# Clear all records from the buffer.
		def clear
			@records.clear
		end
		
		# @returns [Boolean] True if the buffer is empty.
		def empty?
			@records.empty?
		end
		
		# Sets the verbose flag which controls whether verbose messages are captured.
		def verbose!(value = true)
			@verbose = value
		end
		
		# @returns [Boolean] True if the buffer is capturing verbose messages.
		def verbose?
			@verbose
		end
		
		# Record a log message in the buffer.
		#
		# @parameter subject [Object] The subject of the log message.
		# @parameter arguments [Array] The arguments to the log message.
		# @parameter severity [Symbol] The severity of the log message.
		# @parameter event [Event] The event associated with the log message.
		# @parameter options [Hash] Additional options to pass to the log message.
		# @yields {|buffer| ...} A block which can be used to write additional information to the log message.
		# 	@parameter buffer [IO] The (optional) buffer to write to.
		def call(subject = nil, *arguments, severity: UNKNOWN, event: nil, **options, &block)
			record = {
				time: ::Time.now.iso8601,
				severity: severity,
				**options,
			}
			
			if subject
				record[:subject] = subject
			end
			
			if event
				record[:event] = event.to_hash
			end
			
			if arguments.any?
				record[:arguments] = arguments
			end
			
			if annotation = Fiber.current.annotation
				record[:annotation] = annotation
			end
			
			if block_given?
				if block.arity.zero?
					record[:message] = yield
				else
					buffer = StringIO.new
					yield buffer
					record[:message] = buffer.string
				end
			else
				record[:message] = arguments.join(" ")
			end
			
			@records << record
		end
	end
end
