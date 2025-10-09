# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.
# Copyright, 2022, by Anton Sozontov.

require_relative "clock"

module Console
	# A simple progress indicator
	class Progress
		# @deprecated Use {Clock.now} instead.
		def self.now
			Clock.now
		end
		
		# Create a new progress indicator.
		#
		# @parameter subject [Object] The subject of the progress indicator.
		# @parameter total [Integer] The total number of steps.
		# @parameter minimum_output_duration [Numeric] The minimum duration between outputs.
		# @parameter options [Hash] Additional options to customize the output.
		def initialize(subject, total = 0, minimum_output_duration: 0.1, **options)
			@subject = subject
			@options = options
			
			@start_time = Clock.now
			
			@last_output_time = nil
			@minimum_output_duration = minimum_output_duration
			
			@current = 0
			@total = total
		end
		
		# @attribute [Object] The subject of the progress indicator.
		attr :subject
		
		# @attribute [Numeric] The minimum duration between outputs.
		attr :minimum_output_duration
		
		# @attribute [Time] The time the progress indicator was started.
		attr :start_time
		
		# @attribute [Numeric] The current number of steps completed.
		attr :current
		
		# @attribute [Numeric] The total number of steps.
		attr :total
		
		# @returns [Numeric] The duration since the progress indicator was started.
		def duration
			Clock.now - @start_time
		end
		
		# @returns [Rational] The ratio of steps completed to total steps.
		def ratio
			Rational(@current.to_f, @total.to_f)
		end
		
		# @returns [Numeric] The number of steps remaining.
		def remaining
			@total - @current
		end
		
		# @returns [Numeric | Nil] The average duration per step, or `nil` if no steps have been completed.
		def average_duration
			if @current > 0
				duration / @current
			end
		end
		
		# @returns [Numeric | Nil] The estimated remaining time, or `nil` if no steps have been completed.
		def estimated_remaining_time
			if average_duration = self.average_duration
				average_duration * remaining
			end
		end
		
		# Generate an appropriate event for the progress indicator.
		#
		# @returns [Hash] The progress indicator as a hash.
		def to_hash
			Hash.new.tap do |hash|
				hash[:type] = :progress
				hash[:current] = @current
				hash[:total] = @total
				
				hash[:duration] = self.duration
				hash[:estimated_remaining_time] = self.estimated_remaining_time
			end
		end
		
		# Increment the progress indicator by the given amount.
		#
		# @parameter amount [Numeric] The amount to increment by.
		# @returns [Progress] The progress indicator itself.
		def increment(amount = 1)
			@current += amount
			
			if output?
				Console.call(@subject, self.to_s, event: self.to_hash, **@options)
				@last_output_time = Clock.now
			end
			
			return self
		end
		
		# Resize the progress indicator to the given total.
		#
		# @parameter total [Numeric] The new total number of steps.
		# @returns [Progress] The progress indicator itself.
		def resize(total)
			@total = total
			
			Console.call(@subject, self.to_s, event: self.to_hash, **@options)
			@last_output_time = Clock.now
			
			return self
		end
		
		# Augment the progress indicator with additional information.
		#
		# @parameter *arguments [Array] The arguments to log.
		# @parameter **options [Hash] Additional options to log.
		# @parameter &block [Proc] An optional block used to generate the log message.
		def mark(*arguments, **options, &block)
			Console.call(@subject, *arguments, **options, **@options, &block)
		end
		
		# @returns [String] A human-readable representation of the progress indicator.
		def to_s
			if estimated_remaining_time = self.estimated_remaining_time
				"#{@current}/#{@total} completed in #{Clock.formatted_duration(self.duration)}, #{Clock.formatted_duration(estimated_remaining_time)} remaining."
			else
				"#{@current}/#{@total} completed, waiting for estimate..."
			end
		end
		
		private
		
		# Compute a time delta since the last output, used for rate limiting the output.
		#
		# @returns [Numeric | Nil] The duration since the last output.
		def duration_since_last_output
			if @last_output_time
				Clock.now - @last_output_time
			end
		end
		
		# Whether an output should be generated at this time, taking into account the remaining steps, and the duration since the last output.
		#
		# @returns [Boolean] Whether an output should be generated.
		def output?
			if remaining.zero?
				return true
			elsif duration = duration_since_last_output
				return duration > @minimum_output_duration
			else
				return true
			end
		end
	end
end
