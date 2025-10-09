# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.

require_relative "generic"
require_relative "../clock"

module Console
	module Event
		# Represents a child process spawn event.
		#
		# ```ruby
		# Console.info(self, **Console::Event::Spawn.for("ls", "-l"))
		#
		# event = Console::Event::Spawn.for("ls", "-l")
		# event.status = Process.wait
		# ```
		class Spawn < Generic
			# Create a new spawn event.
			#
			# @parameter arguments [Array] The arguments to the command, similar to how you would pass them to `Kernel.system` or `Process.spawn`.
			# @parameter options [Hash] The options to pass to the command, similar to how you would pass them to `Kernel.system` or `Process.spawn`.
			# @returns [Spawn] The new spawn event representing the command.
			def self.for(*arguments, **options)
				# Extract out the command environment:
				if arguments.first.is_a?(Hash)
					environment = arguments.shift
					self.new(environment, arguments, options)
				else
					self.new(nil, arguments, options)
				end
			end
			
			# Create a new spawn event.
			#
			# @parameter environment [Hash] The environment to use when running the command.
			# @parameter arguments [Array] The arguments used for command execution.
			# @parameter options [Hash] The options to pass to the command, similar to how you would pass them to `Kernel.system` or `Process.spawn`.
			def initialize(environment, arguments, options)
				@environment = environment
				@arguments = arguments
				@options = options
				
				@start_time = Clock.now
				
				@end_time = nil
				@status = nil
			end
			
			# @attribute [Numeric] The start time of the command.
			attr :start_time
			
			# @attribute [Numeric] The end time of the command.
			attr :end_time
			
			# @attribute [Process::Status] The status of the command, if it has completed.
			attr :status
			
			# Set the status of the command, and record the end time.
			#
			# @parameter status [Process::Status] The status of the command.
			def status=(status)
				@end_time = Time.now
				@status = status
			end
			
			# Calculate the duration of the command, if it has completed.
			#
			# @returns [Numeric] The duration of the command.
			def duration
				if @end_time
					@end_time - @start_time
				end
			end
			
			# Convert the spawn event to a hash suitable for JSON serialization.
			#
			# @returns [Hash] The hash representation of the spawn event.
			def to_hash
				Hash.new.tap do |hash|
					hash[:type] = :spawn
					hash[:environment] = @environment if @environment&.any?
					hash[:arguments] = @arguments if @arguments&.any?
					hash[:options] = @options if @options&.any?
					
					hash[:status] = @status.to_i if @status
					
					if duration = self.duration
						hash[:duration] = duration
					end
				end
			end
			
			# Log the spawn event.
			#
			# @parameter arguments [Array] The arguments to log.
			# @parameter options [Hash] Additional options to pass to the logger output.
			def emit(*arguments, **options)
				options[:severity] ||= :info
				super
			end
		end
	end
end
