# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2025, by Samuel Williams.

module Console
	# A simple clock utility for tracking and formatting time.
	module Clock
		# Format a duration in seconds as a human readable string.
		#
		# @parameter duration [Numeric] The duration in seconds.
		# @returns [String] The formatted duration.
		def self.formatted_duration(duration)
			if duration < 60.0
				return "#{duration.round(2)}s"
			end
			
			duration /= 60.0
			
			if duration < 60.0
				return "#{duration.floor}m"
			end
			
			duration /= 60.0
			
			if duration < 24.0
				return "#{duration.floor}h"
			end
			
			duration /= 24.0
			
			return "#{duration.floor}d"
		end
		
		# @returns [Time] The current monotonic time.
		def self.now
			::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
		end
	end
end
