# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.

require_relative "local/version"
require 'fiber/storage'

class Fiber
	module Local
		def self.extended(klass)
			attribute_name = klass.name.gsub('::', '_').gsub(/\W/, '').downcase.to_sym
			
			# This is used for the general interface and fiber storage key:
			klass.instance_variable_set(:@fiber_local_attribute_name, attribute_name)
			klass.singleton_class.attr :fiber_local_attribute_name
			
			# This is used for reading and writing directly to the thread instance variables:
			klass.instance_variable_set(:@fiber_local_variable_name, :"@#{attribute_name}")
			
			Thread.attr_accessor(attribute_name)
		end
		
		# Instantiate a new thread-local object.
		# By default, invokes {new} to generate the instance.
		# @returns [Object]
		def local
			self.new
		end
		
		# Get the current thread-local instance. Create it if required.
		# @returns [Object] The thread-local instance.
		def instance
			# This is considered a local "override" in the dynamic scope of the fiber:
			if instance = Fiber[@fiber_local_attribute_name]
				return instance
			end
			
			# This is generally the fast path:
			thread = Thread.current
			unless instance = thread.instance_variable_get(@fiber_local_variable_name)
				if instance = self.local
					thread.instance_variable_set(@fiber_local_variable_name, instance)
				end
			end
			
			return instance
		end
		
		# Assigns to the fiber-local instance.
		# @parameter instance [Object] The object that will become the thread-local instance.
		def instance= instance
			Fiber[@fiber_local_attribute_name] = instance
		end
	end
end
