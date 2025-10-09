# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.

module Console
	module Terminal
		module Formatter
			# Format a spawn event, including the command and arguments.
			class Spawn
				# The key used to identify this formatter.
				KEY = :spawn
				
				# Create a new spawn formatter.
				#
				# @param terminal [Terminal::Text] The terminal to use for formatting.
				def initialize(terminal)
					@terminal = terminal
					@terminal[:spawn_command] ||= @terminal.style(:blue, nil, :bold)
				end
				
				# Format the given event.
				#
				# @parameter event [Hash] The event to format.
				# @parameter stream [IO] The stream to write the formatted event to.
				# @parameter verbose [Boolean] Whether to include additional information.
				# @parameter width [Integer] The width of the progress bar.
				def format(event, stream, verbose: false, width: 80)
					environment, arguments, options = event.values_at(:environment, :arguments, :options)
					
					arguments = arguments.flatten.collect(&:to_s)
					
					stream.puts "#{@terminal[:spawn_command]}#{arguments.join(' ')}#{@terminal.reset}#{chdir_string(options)}"
					
					if verbose and environment
						environment.each do |key, value|
							stream.puts "export #{key}=#{value}"
						end
					end
				end
				
				private
				
				# Generate a string to represent the working directory.
				def chdir_string(options)
					if options and chdir = options[:chdir]
						" in #{chdir}"
					end
				end
			end
		end
	end
end
