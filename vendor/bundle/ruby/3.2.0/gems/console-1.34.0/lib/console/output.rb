# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2025, by Samuel Williams.

require_relative "output/default"
require_relative "output/serialized"
require_relative "output/terminal"
require_relative "output/null"

module Console
	# Output handling.
	module Output
		# Create a new output based on the environment.
		#
		# The environment variable `CONSOLE_OUTPUT` can be used to specify a list of output classes to wrap around the output. If not specified the {Default} output is used.
		#
		# The output argument is deliberately unders-specified but can be an IO object or an instance of {Output}.
		#
		# @parameter output [Console::Output] The output to wrap OR an IO object.
		# @parameter env [Hash] The environment to read configuration from.
		# @parameter options [Hash] Additional options to customize the output.
		# @returns [Console::Output] The output instance.
		def self.new(output = nil, env = ENV, **options)
			if names = env["CONSOLE_OUTPUT"]
				names = names.split(",").reverse
				
				names.inject(output) do |output, name|
					Output.const_get(name).new(output, env: env, **options)
				end
			else
				return Output::Default.new(output, env: env, **options)
			end
		end
	end
end
