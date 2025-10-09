# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

require_relative "config"

module Metrics
	module Backend
	end
	
	Config::DEFAULT.require_backend
end
