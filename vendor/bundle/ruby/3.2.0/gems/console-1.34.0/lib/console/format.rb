# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2025, by Samuel Williams.

require_relative "format/safe"

module Console
	module Format
		# A safe format for converting objects to strings.
		#
		# @returns [Console::Format::Safe]
		def self.default
			Safe.new(format: ::JSON)
		end
	end
end
