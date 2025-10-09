# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2024, by Samuel Williams.

require "io/nonblock"

module IO::Event
	module Selector
		# Execute the given block in non-blocking mode.
		#
		# @parameter io [IO] The IO object to operate on.
		# @yields {...} The block to execute.
		def self.nonblock(io, &block)
			io.nonblock(&block)
		rescue Errno::EBADF
			# Windows.
			yield
		end
	end
end
