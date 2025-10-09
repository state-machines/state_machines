# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require_relative "filter"
require_relative "event"
require_relative "resolver"
require_relative "output"
require_relative "logger"

module Console
	# Represents a configuration for the traces library.
	class Config
		PATH = ENV.fetch("CONSOLE_CONFIG_PATH", "config/console.rb")
		
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
			@default ||= self.load(PATH).freeze
		end
		
		# Set the default log level based on `$DEBUG` and `$VERBOSE`.
		# You can also specify CONSOLE_LEVEL=debug or CONSOLE_LEVEL=info in environment.
		# https://mislav.net/2011/06/ruby-verbose-mode/ has more details about how it all fits together.
		#
		# @parameter env [Hash] The environment to read the log level from.
		# @returns [Integer | Symbol] The default log level.
		def log_level(env = ENV)
			Logger.default_log_level(env)
		end
		
		# Controls verbose output using `$VERBOSE`.
		def verbose?(env = ENV)
			!$VERBOSE.nil? || env["CONSOLE_VERBOSE"]
		end
		
		# Create an output with the given output and options.
		#
		# @parameter output [IO] The output to write log messages to.
		# @parameter env [Hash] The environment to read configuration from.
		# @parameter options [Hash] Additional options to pass to the output.
		# @returns [Output] The created output.
		def make_output(io = nil, env = ENV, **options)
			Output.new(io, env, **options)
		end
		
		# Create a resolver with the given logger.
		#
		# @parameter logger [Logger] The logger to set the log levels on.
		# @returns [Resolver | Nil] The created resolver.
		def make_resolver(logger)
			Resolver.default_resolver(logger)
		end
		
		# Create a logger with the given output and options.
		#
		# @parameter output [IO] The output to write log messages to.
		# @parameter env [Hash] The environment to read configuration from.
		# @parameter options [Hash] Additional options to pass to the logger.
		# @returns [Logger] The created logger.
		def make_logger(io = $stderr, env = ENV, **options)
			if options[:verbose].nil?
				options[:verbose] = self.verbose?(env)
			end
			
			if options[:level].nil?
				options[:level] = self.log_level(env)
			end
			
			output = self.make_output(io, env, **options)
			
			logger = Logger.new(output, **options)
			
			make_resolver(logger)
			
			return logger
		end
		
		# Load the default configuration.
		DEFAULT = self.default
	end
end
