# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.

# Increase the verbosity of the logger to info.
def info
	require_relative "../lib/console"
	
	Console.logger.info!
end

# Increase the verbosity of the logger to debug.
def debug
	require_relative "../lib/console"
	
	Console.logger.debug!
end
