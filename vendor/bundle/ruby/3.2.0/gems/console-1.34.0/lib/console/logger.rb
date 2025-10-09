# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.
# Copyright, 2021, by Bryan Powell.
# Copyright, 2021, by Robert Schulze.
# Copyright, 2025, by Shigeru Nakajima.

require_relative "filter"

require_relative "output"
require_relative "output/failure"

require_relative "progress"

module Console
	# The standard logger interface with support for log levels and verbosity.
	#
	# The log levels are: `debug`, `info`, `warn`, `error`, and `fatal`.
	class Logger < Filter[debug: 0, info: 1, warn: 2, error: 3, fatal: 4]
		# Set the default log level based on `$DEBUG` and `$VERBOSE`.
		# You can also specify CONSOLE_LEVEL=debug or CONSOLE_LEVEL=info in environment.
		# https://mislav.net/2011/06/ruby-verbose-mode/ has more details about how it all fits together.
		#
		# @parameter env [Hash] The environment to read the log level from.
		# @parameter verbose [Boolean] The verbose flag.
		# @parameter debug [Boolean] The debug flag.
		# @returns [Integer] The default log level.
		def self.default_log_level(env = ENV, verbose: $VERBOSE, debug: $DEBUG)
			if level = env["CONSOLE_LEVEL"]
				LEVELS[level.to_sym] || level.to_i
			elsif debug
				DEBUG
			elsif verbose.nil?
				WARN
			else
				INFO
			end
		end
		
		DEFAULT_LEVEL = 1
		
		# Create a new logger.
		#
		# @parameter output [Console::Output] The output destination.
		# @parameter options [Hash] Additional options.
		def initialize(output, **options)
			# This is the expected default behaviour, but it may be nice to have a way to override it.
			output = Output::Failure.new(output, **options)
			
			super(output, **options)
		end
		
		# Create a progress indicator for the given subject.
		#
		# @parameter subject [String] The subject of the progress indicator.
		# @parameter total [Integer] The total number of items to process.
		# @parameter options [Hash] Additional options passed to {Progress}.
		# @returns [Progress] The progress indicator.
		def progress(subject, total, **options)
			options[:severity] ||= :info
			
			Progress.new(subject, total, **options)
		end
	end
end
