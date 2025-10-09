# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.
# Copyright, 2021, by Robert Schulze.

require_relative "filter"

module Console
	# Represents a class resolver that can be used to set log levels for different classes as they become available.
	class Resolver
		# You can change the log level for different classes using CONSOLE_$LEVEL env vars.
		#
		# e.g. `CONSOLE_WARN=Acorn,Banana CONSOLE_DEBUG=Cat` will set the log level for the classes Acorn and Banana to `warn` and Cat to `debug`. This overrides the default log level.
		#
		# You can enable all log levels for a given class by using `CONSOLE_ON=MyClass`. Similarly you can disable all logging using `CONSOLE_OFF=MyClass`.
		#
		# @parameter logger [Logger] A logger instance to set the logging levels on.
		# @parameter env [Hash] The environment to read levels from.
		# @returns [Nil] If there were no custom logging levels specified in the environment.
		# @returns [Resolver] If there were custom logging levels, then the created resolver is returned.
		def self.default_resolver(logger, env = ENV)
			# Find all CONSOLE_$LEVEL variables from environment:
			levels = logger.class::LEVELS
				.map{|label, level| [level, env["CONSOLE_#{label.upcase}"]&.split(",")]}
				.to_h
				.compact
			
			off_klasses = env["CONSOLE_OFF"]&.split(",")
			on_klasses = env["CONSOLE_ON"]&.split(",")
			
			resolver = nil
			
			# If we have any levels, then create a class resolver, and each time a class is resolved, set the log level for that class to the specified level:
			if on_klasses&.any?
				resolver ||= Resolver.new
				
				resolver.bind(on_klasses) do |klass|
					logger.enable(klass, logger.class::MINIMUM_LEVEL - 1)
				end
			end
			
			if off_klasses&.any?
				resolver ||= Resolver.new
				
				resolver.bind(off_klasses) do |klass|
					logger.disable(klass)
				end
			end
			
			levels.each do |level, names|
				resolver ||= Resolver.new
				
				resolver.bind(names) do |klass|
					logger.enable(klass, level)
				end
			end
			
			return resolver
		end
		
		# Create a new class resolver.
		def initialize
			@names = {}
			
			@trace_point = TracePoint.new(:class, &self.method(:resolve))
		end
		
		# Bind the given class names to the given block. When the class name is resolved into an actual class, the block will be called with the class as an argument.
		#
		# If the class is already defined, the block will be called immediately.
		#
		# If the class is not defined, the block will be called when the class is defined, using a trace point.
		#
		# @parameter names [Array(String)] The class names to bind.
		# @parameter block [Proc] The block to call when the class is resolved.
		def bind(names, &block)
			names.each do |name|
				if klass = Object.const_get(name) rescue nil
					yield klass
				else
					@names[name] = block
				end
			end
			
			if @names.any?
				@trace_point.enable
			else
				@trace_point.disable
			end
		end
		
		# @returns [Boolean] True if the resolver is waiting for classes to be defined.
		def waiting?
			@trace_point.enabled?
		end
		
		# Invoked by the trace point when a class is defined.
		#
		# This will call the block associated with the class name, if any, and remove it from the list of names to resolve.
		#
		# If the list of names is empty, the trace point will be disabled.
		#
		# @parameter trace_point [TracePoint] The trace point that triggered the event.
		def resolve(trace_point)
			if block = @names.delete(trace_point.self.to_s)
				block.call(trace_point.self)
			end
			
			if @names.empty?
				@trace_point.disable
			end
		end
	end
end
