# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024-2025, by Samuel Williams.

module Metrics
	# Represents a configuration for the metrics library.
	class Config
		DEFAULT_PATH = ENV.fetch("METRICS_CONFIG_DEFAULT_PATH", "config/metrics.rb")
		
		# Load the configuration from the given path.
		# @parameter path [String] The path to the configuration file.
		# @returns [Config] The loaded configuration.
		def self.load(path)
			config = self.new
			
			if File.exist?(path)
				config.instance_eval(File.read(path), path)
			end
			
			return config
		end
		
		# Load the default configuration.
		# @returns [Config] The default configuration.
		def self.default
			@default ||= self.load(DEFAULT_PATH)
		end
		
		# Prepare the backend, e.g. by loading additional libraries or instrumentation.
		def prepare
		end
		
		# Require a specific metrics backend implementation.
		def require_backend(env = ENV)
			if backend = env["METRICS_BACKEND"]
				begin
					if require(backend)
						Metrics.singleton_class.prepend(Backend::Interface)
						
						return true
					end
				rescue LoadError => error
					warn "Unable to load metrics backend: #{backend.inspect}!"
				end
			end
			
			return false
		end
		
		# Load the default configuration.
		DEFAULT = self.default
	end
end
