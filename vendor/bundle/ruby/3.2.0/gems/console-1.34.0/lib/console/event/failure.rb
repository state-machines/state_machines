# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.
# Copyright, 2021, by Robert Schulze.
# Copyright, 2024, by Patrik Wenger.

require_relative "generic"

module Console
	module Event
		# Represents a failure of some kind, usually with an attached exception.
		#
		# ```ruby
		# begin
		# 	raise "Something went wrong!"
		# rescue => exception
		# 	Console::Event::Failure.log("Something went wrong!", exception)
		# end
		# ```
		#
		# Generally, you should use the {Console.error} method to log failures, as it will automatically create a failure event for you.
		class Failure < Generic
			# For the purpose of efficiently formatting backtraces, we need to know the root directory of the project.
			#
			# @returns [String | Nil] The root directory of the project, or nil if it could not be determined.
			def self.default_root
				Dir.getwd
			rescue # e.g. Errno::EMFILE
				nil
			end
			
			# Create a new failure event for the given exception.
			#
			# @parameter exception [Exception] The exception to log.
			def self.for(exception)
				self.new(exception, self.default_root)
			end
			
			# Log a failure event with the given exception.
			#
			# @parameter subject [String] The subject of the log message.
			# @parameter exception [Exception] The exception to log.
			# @parameter options [Hash] Additional options pass to the logger output.
			def self.log(subject, exception, **options)
				Console.error(subject, **self.for(exception).to_hash, **options)
			end
			
			# @attribute [Exception] The exception which caused the failure.
			attr_reader :exception
			
			# Create a new failure event for the given exception.
			#
			# @parameter exception [Exception] The exception to log.
			# @parameter root [String] The root directory of the project.
			def initialize(exception, root = self.class.default_root)
				@exception = exception
				@root = root
			end
			
			# Convert the failure event to a hash.
			#
			# @returns [Hash] The hash representation of the failure event.
			def to_hash
				Hash.new.tap do |hash|
					hash[:type] = :failure
					hash[:root] = @root if @root
					extract(@exception, hash)
				end
			end
			
			# Log the failure event.
			#
			# @parameter arguments [Array] The arguments to log.
			# @parameter options [Hash] Additional options to pass to the logger output.
			def emit(*arguments, **options)
				options[:severity] ||= :error
				
				super
			end
			
			private
			
			def extract(exception, hash)
				hash[:class] = exception.class.name
				
				if exception.respond_to?(:detailed_message)
					message = exception.detailed_message
					
					# We want to remove the trailling exception class as we format it differently:
					message.sub!(/\s*\(.*?\)$/, "")
					
					hash[:message] = message
				else
					hash[:message] = exception.message
				end
				
				hash[:backtrace] = exception.backtrace
				
				if cause = exception.cause
					hash[:cause] = Hash.new.tap do |cause_hash|
						extract(cause, cause_hash)
					end
				end
			end
		end
	end
end
