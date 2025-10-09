# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2025, by Samuel Williams.

require "fiber"

# @namespace
class Fiber
	# Provides compatibility shims for fiber storage.
	module Storage
		# Initialize the fiber with the given storage.
		def initialize(*arguments, storage: true, **options, &block)
			case storage
			when true
				@storage = Fiber.current.storage
			else
				raise TypeError, "Storage must be a hash!" unless storage.is_a?(Hash)
				
				@storage = storage
			end
			
			super(*arguments, **options, &block)
		end

		# Set the storage associated with this fiber, clearing any previous storage.
		def storage=(hash)
			@storage = hash.dup
		end
		
		# The storage associated with this fiber.
		def storage
			@storage.dup
		end
		
		# @private
		def __storage__
			@storage ||= {}
		end
	end
	
	unless Fiber.current.respond_to?(:storage)
		prepend Storage
		
		# Get a value from the current fiber's storage.
		def self.[] key
			raise TypeError, "Key must be symbol!" unless key.is_a?(Symbol)
			
			self.current.__storage__[key]
		end
		
		# Set a value in the current fiber's storage.
		def self.[]= key, value
			raise TypeError, "Key must be symbol!" unless key.is_a?(Symbol)
			
			self.current.__storage__[key] = value
		end
	else
		# Whether the fiber storage has buggy keys. Unfortunately the original implementation of fiber storage was broken, this method detects the bug and is used to apply a fix.
		def self.__borked_keys__
			!Fiber.new do
				key = :"#{self.object_id}.key"
				Fiber[key] = true
				Fiber[key]
			end.resume
		end
		
		if __borked_keys__
			# This is a fix for the original implementation of fiber storage which incorrectly handled non-dynamic symbol keys.
			module FixBorkedKeys
				# Lookup the value for the key, ensuring the symbol is dynamic.
				def [](key)
					raise TypeError, "Key must be symbol!" unless key.is_a?(Symbol)
					
					super(eval(key.inspect))
				end
				
				# Assign the value to the key, ensuring the symbol is dynamic.
				def []=(key, value)
					raise TypeError, "Key must be symbol!" unless key.is_a?(Symbol)
					
					super(eval(key.inspect), value)
				end
			end
			
			singleton_class.prepend FixBorkedKeys
		end
	end
end
