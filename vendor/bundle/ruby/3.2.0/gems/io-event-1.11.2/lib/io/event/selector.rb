# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

require_relative "selector/select"
require_relative "debug/selector"
require_relative "support"

module IO::Event
	# @namespace
	module Selector
		# The default selector implementation, which is chosen based on the environment and available implementations.
		#
		# @parameter env [Hash] The environment to read configuration from.
		# @returns [Class] The default selector implementation.
		def self.default(env = ENV)
			if name = env["IO_EVENT_SELECTOR"]&.to_sym
				return const_get(name)
			end
			
			if self.const_defined?(:URing)
				URing
			elsif self.const_defined?(:EPoll)
				EPoll
			elsif self.const_defined?(:KQueue)
				KQueue
			else
				Select
			end
		end
		
		# Create a new selector instance, according to the best available implementation.
		#
		# @parameter loop [Fiber] The event loop fiber.
		# @parameter env [Hash] The environment to read configuration from.
		# @returns [Selector] The new selector instance.
		def self.new(loop, env = ENV)
			selector = default(env).new(loop)
			
			if debug = env["IO_EVENT_DEBUG_SELECTOR"]
				selector = Debug::Selector.wrap(selector, env)
			end
			
			return selector
		end
	end
end
