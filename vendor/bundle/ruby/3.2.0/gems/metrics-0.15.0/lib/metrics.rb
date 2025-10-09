# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2025, by Samuel Williams.

require_relative "metrics/version"
require_relative "metrics/provider"
require_relative "metrics/tags"

# @namespace
module Metrics
	if self.enabled?
		Config::DEFAULT.prepare
	end
end
