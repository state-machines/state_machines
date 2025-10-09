# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024-2025, by Samuel Williams.

module Console
	module Terminal
		module Formatter
			# Format a failure event, including the exception message and backtrace.
			class Failure
				# The key used to identify this formatter.
				KEY = :failure
				
				# Create a new failure formatter.
				#
				# @param terminal [Terminal::Text] The terminal to use for formatting.
				def initialize(terminal)
					@terminal = terminal
					
					@terminal[:exception_title] ||= @terminal.style(:red, nil, :bold)
					@terminal[:exception_detail] ||= @terminal.style(:yellow)
					@terminal[:exception_backtrace] ||= @terminal.style(:red)
					@terminal[:exception_backtrace_other] ||= @terminal.style(:red, nil, :faint)
					@terminal[:exception_message] ||= @terminal.style(:default)
				end
				
				# Format the given event.
				#
				# @parameter event [Hash] The event to format.
				# @parameter stream [IO] The stream to write the formatted event to.
				# @parameter prefix [String] The prefix to use before the title.
				# @parameter verbose [Boolean] Whether to include additional information.
				# @parameter options [Hash] Additional options.
				def format(event, stream, prefix: nil, verbose: false, **options)
					title = event[:class]
					message = event[:message]
					backtrace = event[:backtrace]
					root = event[:root]
					
					lines = message.lines.map(&:chomp)
					
					stream.puts "  #{prefix}#{@terminal[:exception_title]}#{title}#{@terminal.reset}: #{lines.shift}"
					
					lines.each do |line|
						stream.puts "  #{@terminal[:exception_detail]}#{line}#{@terminal.reset}"
					end
					
					root_pattern = /^#{root}\// if root
					
					backtrace&.each_with_index do |line, index|
						path, offset, message = line.split(":", 3)
						style = :exception_backtrace
						
						# Make the path a bit more readable:
						if root_pattern and path.sub!(root_pattern, "").nil?
							style = :exception_backtrace_other
						end
						
						stream.puts "  #{index == 0 ? "→" : " "} #{@terminal[style]}#{path}:#{offset}#{@terminal[:exception_message]} #{message}#{@terminal.reset}"
					end
					
					if cause = event[:cause]
						format(cause, stream, prefix: "Caused by ", verbose: verbose, **options)
					end
				end
			end
		end
	end
end
