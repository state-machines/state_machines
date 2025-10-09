# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

begin
	require "IO_Event"
rescue LoadError => error
	warn "Could not load native event selector: #{error}"
	require_relative "selector/nonblock"
end
