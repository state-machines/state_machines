# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024-2025, by Samuel Williams.

module Traces
	# Represents a configuration for the traces library.
	class Config
		DEFAULT_PATH = ENV.fetch("TRACES_CONFIG_DEFAULT_PATH", "config/traces.rb")
		
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
		
		# Require a specific traces backend implementation.
		def require_backend(env = ENV)
			if backend = env["TRACES_BACKEND"]
				begin
					require(backend)
					
					# We ensure that the interface methods replace any existing methods by prepending the module:
					Traces.singleton_class.prepend(Backend::Interface)
					
					return true
				rescue LoadError => error
					warn "Unable to load traces backend: #{backend.inspect}!"
				end
			end
			
			return false
		end
		
		# Load the default configuration.
		DEFAULT = self.default
	end
end
