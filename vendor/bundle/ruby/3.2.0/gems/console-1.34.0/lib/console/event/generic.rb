# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.

module Console
	module Event
		# A generic event which can be used to represent structured data.
		class Generic
			# Convert the event to a hash suitable for JSON serialization.
			#
			# @returns [Hash] The hash representation of the event.
			def to_hash
				{}
			end
			
			# Convert the event to a hash suitable for JSON serialization.
			#
			# @returns [Hash] The hash representation of the event.
			def as_json(...)
				to_hash
			end
			
			# Serialize the event to JSON.
			#
			# @returns [String] The JSON representation of the event.
			def to_json(...)
				JSON.generate(as_json, ...)
			end
			
			# Convert the event to a string (JSON).
			#
			# @returns [String] The string representation of the event.
			def to_s
				to_json
			end
			
			# Log the event using the given output interface.
			#
			# @parameter arguments [Array] The arguments to log.
			# @parameter options [Hash] Additional options to pass to the logger output.
			def emit(*arguments, **options)
				Console.call(*arguments, event: self, **options)
			end
		end
	end
end
