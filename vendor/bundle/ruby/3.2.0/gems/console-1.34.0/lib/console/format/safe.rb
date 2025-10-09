# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2025, by Samuel Williams.

require "json"

module Console
	# @namespace
	module Format
		# A safe format for converting objects to strings.
		# 
		# Handles issues like circular references and encoding errors.
		class Safe
			# Create a new safe format.
			#
			# @parameter format [JSON] The format to use for serialization.
			# @parameter limit [Integer] The maximum depth to recurse into objects.
			# @parameter encoding [Encoding] The encoding to use for strings.
			def initialize(format: ::JSON, limit: 8, encoding: ::Encoding::UTF_8)
				@format = format
				@limit = limit
				@encoding = encoding
			end
			
			# Dump the given object to a string.
			#
			# @parameter object [Object] The object to dump.
			# @returns [String] The dumped object.
			def dump(object)
				@format.dump(object, @limit)
			rescue SystemStackError, StandardError => error
				@format.dump(safe_dump(object, error))
			end
			
			private
			
			# Filter the backtrace to remove duplicate frames and reduce verbosity.
			#
			# @parameter error [Exception] The exception to filter.
			# @returns [Array(String)] The filtered backtrace.
			def filter_backtrace(error)
				frames = error.backtrace
				filtered = {}
				filtered_count = nil
				skipped = nil
				
				frames = frames.filter_map do |frame|
					if filtered[frame]
						if filtered_count == nil
							filtered_count = 1
							skipped = frame.dup
						else
							filtered_count += 1
							nil
						end
					else
						if skipped
							if filtered_count > 1
								skipped.replace("[... #{filtered_count} frames skipped ...]")
							end
							
							filtered_count = nil
							skipped = nil
						end
						
						filtered[frame] = true
						frame
					end
				end
				
				if skipped && filtered_count > 1
					skipped.replace("[... #{filtered_count} frames skipped ...]")
				end
				
				return frames
			end
			
			# Dump the given object to a string, replacing it with a safe representation if there is an error.
			#
			# This is a slow path so we try to avoid it.
			#
			# @parameter object [Object] The object to dump.
			# @parameter error [Exception] The error that occurred while dumping the object.
			# @returns [Hash] The dumped (truncated) object including error details.
			def safe_dump(object, error)
				object = safe_dump_recurse(object)
				
				object[:truncated] = true
				object[:error] = {
					class: safe_dump_recurse(error.class.name),
					message: safe_dump_recurse(error.message),
					backtrace: safe_dump_recurse(filter_backtrace(error)),
				}
				
				return object
			end
			
			# Replace the given object with a safe truncated representation.
			#
			# @parameter object [Object] The object to replace.
			# @returns [String] The replacement string.
			def replacement_for(object)
				case object
				when Array
					"[...]"
				when Hash
					"{...}"
				else
					"..."
				end
			end
			
			# Create a new hash with identity comparison.
			def default_objects
				Hash.new.compare_by_identity
			end
			
			# This will recursively generate a safe version of the object. Nested hashes and arrays will be transformed recursively. Strings will be encoded with the given encoding. Primitive values will be returned as-is. Other values will be converted using `as_json` if available, otherwise `to_s`.
			#
			# @parameter object [Object] The object to dump.
			# @parameter limit [Integer] The maximum depth to recurse into objects.
			# @parameter objects [Hash] The objects that have already been visited.
			# @returns [Object] The dumped object as a primitive representation.
			def safe_dump_recurse(object, limit = @limit, objects = default_objects)
				if limit <= 0 || objects[object]
					return replacement_for(object)
				end
				
				case object
				when Hash
					objects[object] = true
					
					object.to_h do |key, value|
						[
							String(key).encode(@encoding, invalid: :replace, undef: :replace),
							safe_dump_recurse(value, limit - 1, objects)
						]
					end
				when Array
					objects[object] = true
					
					object.map do |value|
						safe_dump_recurse(value, limit - 1, objects)
					end
				when String
					object.encode(@encoding, invalid: :replace, undef: :replace)
				when Numeric, TrueClass, FalseClass, NilClass
					object
				else
					objects[object] = true
					
					# We could do something like this but the chance `as_json` will blow up.
					# We'd need to be extremely careful about it.
					# if object.respond_to?(:as_json)
					# 	safe_dump_recurse(object.as_json, limit - 1, objects)
					# else
					
					safe_dump_recurse(object.to_s, limit - 1, objects)
				end
			end
		end
	end
end
