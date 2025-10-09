# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2025, by Samuel Williams.

require_relative "backend"

module Metrics
	# @returns [Boolean] Whether there is an active backend.
	def self.enabled?
		Backend.const_defined?(:Interface)
	end
	
	module Provider
	end
	
	# A module which contains tracing specific wrappers.
	module Singleton
		def metrics_provider
			@metrics_provider ||= Module.new
		end
	end
	
	private_constant :Singleton
	
	# Bail out if there is no backend configured.
	if self.enabled?
		# Extend the specified class in order to emit traces.
		def self.Provider(klass, &block)
			klass.extend(Singleton)
			provider = klass.metrics_provider
			klass.prepend(provider)
			
			provider.module_exec(&block) if block_given?
			
			return provider
		end
	else
		def self.Provider(klass, &block)
			# Metrics disabled.
		end
	end
end
