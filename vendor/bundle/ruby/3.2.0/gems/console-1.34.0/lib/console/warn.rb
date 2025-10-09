# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024-2025, by Samuel Williams.

require_relative "logger"

module Console
	# Whether the current fiber is emitting a warning.
	Fiber.attr_accessor :console_warn
	
	# Redirect warnings to Console.warn.
	module Warn
		# Redirect warnings to {Console.warn}.
		def warn(message, **options)
			fiber = Fiber.current
			
			# We do this to be extra pendantic about avoiding infinite recursion.
			return super if fiber.console_warn
			
			begin
				fiber.console_warn = true
				message.chomp!
				
				Console::Interface.instance.warn(message, **options)
			ensure
				fiber.console_warn = false
			end
		end
	end
	
	::Warning.extend(Warn)
end
