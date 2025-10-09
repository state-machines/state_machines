# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2025, by Samuel Williams.

module Console
	module Output
		# A generic wrapper for output handling.
		class Wrapper
			# Create a new wrapper output.
			#
			# @parameter delegate [Console::Output] The output to delegate to.
			# @parameter options [Hash] Additional options to customize the output.
			def initialize(delegate, **options)
				@delegate = delegate
			end
			
			# @attribute [Console::Output] The output to delegate to.
			attr :delegate
			
			# The last output is the last output of the delegate.
			def last_output
				@delegate.last_output
			end
			
			# Set the verbose flag for the delegate.
			#
			# @parameter value [Boolean] The new value.
			def verbose!(value = true)
				@delegate.verbose!(value)
			end
			
			# Invoke the delegate.
			def call(...)
				@delegate.call(...)
			end
		end
	end
end
