# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2025, by Samuel Williams.

module Console
	module Output
		# Split output into multiple outputs.
		class Split
			# Create a new split output.
			#
			# @parameter outputs [Array(Console::Output)] The outputs to split into.
			def self.[](*outputs)
				self.new(outputs)
			end
			
			# Create a new split output.
			#
			# @parameter outputs [Array(Console::Output)] The outputs to split into.
			def initialize(outputs)
				@outputs = outputs
			end
			
			# Set the verbose flag for all outputs.
			#
			# @parameter value [Boolean] The new value.
			def verbose!(value = true)
				@outputs.each{|output| output.verbose!(value)}
			end
			
			# Invoke the outputs. If a block is used, it may be invoked multiple times.
			def call(...)
				@outputs.each do |output|
					output.call(...)
				end
			end
		end
	end
end
