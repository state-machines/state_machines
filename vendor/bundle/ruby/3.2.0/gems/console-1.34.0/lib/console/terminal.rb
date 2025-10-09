# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.

require_relative "terminal/text"
require_relative "terminal/xterm"
require_relative "terminal/formatter"

module Console
	module Terminal
		# Create a new terminal output for the given stream.
		def self.for(stream)
			if stream.tty?
				XTerm.new(stream)
			else
				Text.new(stream)
			end
		end
	end
end
