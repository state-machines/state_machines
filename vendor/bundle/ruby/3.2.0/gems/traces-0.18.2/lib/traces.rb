# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2025, by Samuel Williams.

require_relative "traces/version"
require_relative "traces/provider"

# @namespace
module Traces
	if self.enabled?
		Config::DEFAULT.prepare
	end
end
