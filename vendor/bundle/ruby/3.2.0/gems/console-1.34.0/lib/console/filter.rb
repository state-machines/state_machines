# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.
# Copyright, 2019, by Bryan Powell.
# Copyright, 2020, by Michael Adams.
# Copyright, 2021, by Robert Schulze.

module Console
	UNKNOWN = :unknown
	
	# A log filter which can be used to filter log messages based on severity, subject, and other criteria.
	class Filter
		if Object.const_defined?(:Ractor) and RUBY_VERSION >= "3.4"
			# Define a method which can be shared between ractors.
			def self.define_immutable_method(name, &block)
				block = Ractor.make_shareable(block)
				self.define_method(name, &block)
			end
		else
			# Define a method.
			def self.define_immutable_method(name, &block)
				define_method(name, &block)
			end
		end
		
		# Create a new log filter with specific log levels.
		#
		# ```ruby
		# class MyLogger < Console::Filter[debug: 0, okay: 1, bad: 2, terrible: 3]
		# ```
		#
		# @parameter levels [Hash(Symbol, Integer)] A hash of log levels.
		def self.[] **levels
			klass = Class.new(self)
			minimum_level, maximum_level = levels.values.minmax
			
			klass.instance_exec do
				const_set(:LEVELS, levels.freeze)
				const_set(:MINIMUM_LEVEL, minimum_level)
				const_set(:MAXIMUM_LEVEL, maximum_level)
				
				levels.each do |name, level|
					const_set(name.to_s.upcase, level)
					
					define_immutable_method(name) do |subject = nil, *arguments, **options, &block|
						if self.enabled?(subject, level)
							@output.call(subject, *arguments, severity: name, **@options, **options, &block)
						end
						
						return nil
					end
					
					define_immutable_method("#{name}!") do
						@level = level
					end
					
					define_immutable_method("#{name}?") do
						@level <= level
					end
				end
			end
			
			return klass
		end
		
		# Create a new log filter.
		#
		# @parameter output [Console::Output] The output destination.
		# @parameter verbose [Boolean] Enable verbose output.
		# @parameter level [Integer] The log level.
		# @parameter options [Hash] Additional options.
		def initialize(output, verbose: true, level: nil, **options)
			@output = output
			@verbose = verbose
			
			# Set the log level using the behaviour implemented in `level=`:
			if level
				self.level = level
			else
				@level = self.class::DEFAULT_LEVEL
			end
			
			@subjects = {}
			
			@options = options
		end
		
		# Create a new log filter with the given options, from an existing log filter.
		#
		# @parameter level [Integer] The log level.
		# @parameter verbose [Boolean] Enable verbose output.
		# @parameter options [Hash] Additional options.
		# @returns [Console::Filter] The new log filter.
		def with(level: @level, verbose: @verbose, **options)
			dup.tap do |logger|
				logger.level = level
				logger.verbose! if verbose
				logger.options = @options.merge(options)
			end
		end
		
		# @attribute [Console::Output] The output destination.
		attr_accessor :output
		
		# @attribute [Boolean] Whether to enable verbose output.
		attr :verbose
		
		# @attribute [Integer] The current log level.
		attr :level
		
		# @attribute [Hash(Module, Integer)] The log levels for specific subject (classes).
		attr :subjects
		
		# @attribute [Hash] Additional options.
		attr_accessor :options
		
		# Set the log level.
		#
		# @parameter level [Integer | Symbol] The log level.
		def level= level
			if level.is_a? Symbol
				@level = self.class::LEVELS[level]
			else
				@level = level
			end
		end
		
		# Set verbose output (enable by default with no arguments).
		#
		# @parameter value [Boolean] Enable or disable verbose output.
		def verbose!(value = true)
			@verbose = value
			@output.verbose!(value)
		end
		
		# Disable all logging.
		def off!
			@level = self.class::MAXIMUM_LEVEL + 1
		end
		
		# Enable all logging.
		def all!
			@level = self.class::MINIMUM_LEVEL - 1
		end
		
		# Filter log messages based on the subject and log level.
		#
		# You must provide the subject's class, not an instance of the class.
		#
		# @parameter subject [Module] The subject to filter.
		# @parameter level [Integer] The log level.
		def filter(subject, level)
			unless subject.is_a?(Module)
				raise ArgumentError, "Expected a class, got #{subject.inspect}"
			end
			
			@subjects[subject] = level
		end
		
		# Whether logging is enabled for the given subject and log level.
		#
		# You can enable and disable logging for classes. This function checks if logging for a given subject is enabled.
		#
		# @parameter subject [Module | Object] The subject to check.
		# @parameter level [Integer] The log level.
		# @returns [Boolean] Whether logging is enabled.
		def enabled?(subject, level = self.class::MINIMUM_LEVEL)
			subject = subject.class unless subject.is_a?(Module)
			
			if specific_level = @subjects[subject]
				return level >= specific_level
			end
			
			if level >= @level
				return true
			end
		end
		
		# Enable specific log level for the given class.
		#
		# @parameter name [Module] The class to enable.
		def enable(subject, level = self.class::MINIMUM_LEVEL)
			# Set the filter level of logging for a given subject which passes all log messages:
			filter(subject, level)
		end
		
		# Disable logging for the given class.
		#
		# @parameter name [Module] The class to disable.
		def disable(subject)
			# Set the filter level of the logging for a given subject which filters all log messages:
			filter(subject, self.class::MAXIMUM_LEVEL + 1)
		end
		
		# Clear any specific filters for the given class.
		#
		# @parameter subject [Module] The class to disable.
		def clear(subject)
			unless subject.is_a?(Module)
				raise ArgumentError, "Expected a class, got #{subject.inspect}"
			end
			
			@subjects.delete(subject)
		end
		
		# Log a message with the given severity.
		#
		# @parameter subject [Object] The subject of the log message.
		# @parameter arguments [Array] The arguments to log.
		# @parameter options [Hash] Additional options to pass to the output.
		# @parameter block [Proc] A block passed to the output.
		# @returns [Nil] Always returns nil.
		def call(subject, *arguments, **options, &block)
			severity = options[:severity] || UNKNOWN
			level = self.class::LEVELS[severity]
			
			if self.enabled?(subject, level)
				@output.call(subject, *arguments, **options, &block)
			end
			
			return nil
		end
	end
end
