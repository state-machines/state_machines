# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.
# Copyright, 2025, by Patrik Wenger.

require "io/console"

module Console
	# Styled terminal output.
	module Terminal
		# A simple text-based terminal output.
		class Text
			# Create a new text terminal output.
			#
			# @parameter stream [IO] The stream to write to.
			def initialize(stream)
				@stream = stream
				@styles = {reset: self.reset}
			end
			
			# @attribute [IO] The stream to write to.
			attr :stream
			
			# Get the style associated with the given key.
			#
			# @parameter key [Symbol] The key to look up.
			# @returns [String] The style associated with the key.
			def [] key
				@styles[key]
			end
			
			# Set the style associated with the given key.
			#
			# @parameter key [Symbol] The key to associate the style with.
			# @parameter value [String] The style to associate with the key.
			def []= key, value
				@styles[key] = value
			end
			
			# @returns [Boolean] Whether the terminal supports colors.
			def colors?
				false
			end
			
			# @returns [Tuple(Integer, Integer)] The size of the terminal, or a default value of [24, 80].
			def size
				[24, 80]
			end
			
			# @returns [Integer] The width of the terminal.
			def width
				self.size.last
			end
			
			# Generate a style string for the given foreground, background, and attributes.
			#
			# @returns [String | Nil] The style string if colors are supported, otherwise nil.
			def style(foreground, background = nil, *attributes)
			end
			
			# Generate a reset sequence.
			#
			# @returns [String | Nil] The reset sequence if colors are supported, otherwise nil.
			def reset
			end
			
			# Write the given arguments to the output stream using the given style. The reset sequence is automatically appended.
			#
			# @parameter arguments [Array] The arguments to write.
			# @parameter style [Symbol] The style to apply.
			def write(*arguments, style: nil)
				if style and prefix = self[style]
					@stream.write(prefix)
					@stream.write(*arguments)
					@stream.write(self.reset)
				else
					@stream.write(*arguments)
				end
			end
			
			# Write the given arguments to the output stream using the given style. The reset sequence is automatically
			# appended at the end of each line.
			#
			# @parameter arguments [Array] The arguments to write, each on a new line.
			# @parameter style [Symbol] The style to apply.
			def puts(*arguments, style: nil)
				if style and prefix = self[style]
					arguments.each do |argument|
						argument.to_s.lines.each do |line|
							@stream.write(prefix, line.chomp)
							@stream.puts(self.reset)
						end
					end
				else
					@stream.puts(*arguments)
				end
			end
			
			# Print rich text to the output stream.
			#
			# - When the argument is a symbol, look up the style and inject it into the output stream.
			# - When the argument is a proc/lambda, call it with self as the argument.
			# - When the argument is anything else, write it directly to the output.
			#
			# @parameter arguments [Array] The arguments to print.
			def print(*arguments)
				arguments.each do |argument|
					case argument
					when Symbol
						@stream.write(self[argument])
					when Proc
						argument.call(self)
					else
						@stream.write(argument)
					end
				end
			end
			
			# Print rich text to the output stream, followed by the reset sequence and a newline.
			#
			# @parameter arguments [Array] The arguments to print.
			def print_line(*arguments)
				print(*arguments)
				@stream.puts(self.reset)
			end
		end
	end
end
