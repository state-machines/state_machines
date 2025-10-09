# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2025, by Samuel Williams.

module Console
	module Output
		# A null output that does nothing.
		class Null
			# Create a new null output.
			def initialize(...)
			end
			
			# The last output is always self.
			def last_output
				self
			end
			
			# Do nothing.
			def call(...)
			end
		end
	end
end
