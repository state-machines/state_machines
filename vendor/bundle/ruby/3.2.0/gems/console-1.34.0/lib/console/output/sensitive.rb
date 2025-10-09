# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2025, by Samuel Williams.

require_relative "wrapper"

module Console
	module Output
		# Redact sensitive information from output.
		class Sensitive < Wrapper
			# Default redaction pattern.
			REDACT = /
				phone
				| email
				| full_?name
				| first_?name
				| last_?name
				
				| device_name
				| user_agent
				
				| zip
				| address
				| location
				| latitude
				| longitude
				
				| ip
				| gps
				
				| sex
				| gender
				
				| token
				| password
			/xi
			
			# Create a new sensitive output wrapper.
			#
			# @parameter output [Console::Output] The output to wrap.
			# @parameter redact [Regexp] The pattern to redact.
			# @parameter options [Hash] Additional options to pass to the output.
			def initialize(output, redact: REDACT, **options)
				super(output, **options)
				
				@redact = redact
			end
			
			# Check if the given text should be redacted.
			#
			# @parameter text [String] The text to check.
			# @returns [Boolean] Whether the text should be redacted.
			def redact?(text)
				text.match?(@redact)
			end
			
			# Redact sensitive information from a hash.
			#
			# @parameter arguments [Hash] The hash to redact.
			# @parameter filter [Proc] An optional filter to apply to redacted text.
			# @returns [Hash] The redacted hash.
			def redact_hash(arguments, filter)
				arguments.transform_values do |value|
					redact(value, filter)
				end
			end
			
			# Redact sensitive information from an array.
			#
			# @parameter array [Array] The array to redact.
			# @parameter filter [Proc] An optional filter to apply to redacted text.
			# @returns [Array] The redacted array.
			def redact_array(array, filter)
				array.map do |value|
					redact(value, filter)
				end
			end
			
			# Redact sensitive information from the given argument.
			#
			# @parameter argument [String | Array | Hash] The argument to redact.
			# @parameter filter [Proc] An optional filter to apply to redacted text.
			# @returns [String | Array | Hash] The redacted argument.
			def redact(argument, filter)
				case argument
				when String
					if filter
						filter.call(argument)
					elsif redact?(argument)
						"[REDACTED]"
					else
						argument
					end
				when Array
					redact_array(argument, filter)
				when Hash
					redact_hash(argument, filter)
				else
					redact(argument.to_s, filter)
				end
			end
			
			# A simple filter for redacting sensitive information.
			class Filter
				# Create a new filter.
				#
				# @parameter substitutions [Hash] The substitutions to apply.
				def initialize(substitutions)
					@substitutions = substitutions
					@pattern = Regexp.union(substitutions.keys)
				end
				
				# Apply the filter to the given text. This will replace all occurrences of the pattern with the corresponding substitution.
				#
				# @parameter text [String] The text to filter.
				# @returns [String] The filtered text.
				def call(text)
					text.gsub(@pattern, @substitutions)
				end
			end
			
			# Write a message to the output, filtering sensitive information if necessary.
			#
			# @parameter subject [String] The subject of the message.
			# @parameter arguments [Array] The arguments to output.
			# @parameter sensitive [Boolean | Filter | Hash] Whether to filter sensitive information.
			# @parameter options [Hash] Additional options to pass to the output.
			# @parameter block [Proc] An optional block to pass to the output.
			def call(subject = nil, *arguments, sensitive: true, **options, &block)
				if sensitive
					if sensitive.respond_to?(:call)
						filter = sensitive
					elsif sensitive.is_a?(Hash)
						filter = Filter.new(sensitive)
					end
					
					subject = redact(subject, filter)
					arguments = redact_array(arguments, filter)
				end
				
				super(subject, *arguments, **options)
			end
		end
	end
end
