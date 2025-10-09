# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024-2025, by Samuel Williams.

require "fiber/local"
require_relative "config"

module Console
	# The public logger interface.
	module Interface
		extend Fiber::Local
		
		# Create a new (thread local) logger instance.
		def self.local
			Config::DEFAULT.make_logger
		end
		
		# Get the current logger instance.
		def logger
			Interface.instance
		end
		
		# Set the current logger instance.
		#
		# The current logger instance is assigned per-fiber.
		def logger= instance
			Interface.instance= instance
		end
		
		# Emit a debug log message.
		def debug(...)
			Interface.instance.debug(...)
		end
		
		# Emit an informational log message.
		def info(...)
			Interface.instance.info(...)
		end
		
		# Emit a warning log message.
		def warn(...)
			Interface.instance.warn(...)
		end
		
		# Emit an error log message.
		def error(...)
			Interface.instance.error(...)
		end
		
		# Emit a fatal log message.
		def fatal(...)
			Interface.instance.fatal(...)
		end
		
		# Emit a log message with arbitrary arguments and options.
		def call(...)
			Interface.instance.call(...)
		end
	end
end
