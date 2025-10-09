# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2024, by Samuel Williams.

class IO
	module Event
		# Helper methods for detecting support for various features.
		module Support
			# Some features are only availble if the IO::Buffer class is available.
			#
			# @returns [Boolean] Whether the IO::Buffer class is available.
			def self.buffer?
				IO.const_defined?(:Buffer)
			end
			
			# The basic fiber scheduler was introduced along side the IO::Buffer class.
			#
			# @returns [Boolean] Whether the IO::Buffer class is available.
			#
			# To be removed on 31 Mar 2025.
			def self.fiber_scheduler_v1?
				IO.const_defined?(:Buffer)
			end
			
			# More advanced read/write methods and blocking controls were introduced in Ruby 3.2.
			#
			# To be removed on 31 Mar 2026.
			def self.fiber_scheduler_v2?
				# Some interface changes were back-ported incorrectly:
				# https://github.com/ruby/ruby/pull/10778
				# Specifically "Improvements to IO::Buffer read/write/pread/pwrite."
				# Missing correct size calculation.
				return false if RUBY_VERSION >= "3.2.5"
				
				IO.const_defined?(:Buffer) and Fiber.respond_to?(:blocking) and IO::Buffer.instance_method(:read).arity == -1
			end
			
			# Updated inferfaces for read/write and IO::Buffer were introduced in Ruby 3.3, including pread/pwrite.
			#
			# To become the default 31 Mar 2026.
			def self.fiber_scheduler_v3?
				if fiber_scheduler_v2?
					return true if RUBY_VERSION >= "3.3"
					
					# Feature detection if required:
					begin
						IO::Buffer.new.slice(0, 0).write(STDOUT)
						return true
					rescue
						return false
					end
				end
			end
		end
	end
end
