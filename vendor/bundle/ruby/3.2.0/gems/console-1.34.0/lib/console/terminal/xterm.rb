# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.

require "io/console"

require_relative "text"

module Console
	# Styled terminal output.
	module Terminal
		# XTerm style terminal output.
		class XTerm < Text
			# XTerm color codes.
			COLORS = {
				black: 0,
				red: 1,
				green: 2,
				yellow: 3,
				blue: 4,
				magenta: 5,
				cyan: 6,
				white: 7,
				default: 9,
			}.freeze
			
			# XTerm attribute codes.
			ATTRIBUTES = {
				normal: 0,
				bold: 1,
				bright: 1,
				faint: 2,
				italic: 3,
				underline: 4,
				blink: 5,
				reverse: 7,
				hidden: 8,
			}.freeze
			
			# Whether the terminal supports colors.
			def colors?
				true
			end
			
			# The size of the terminal.
			def size
				@stream.winsize
			rescue Errno::ENOTTY
				# Fake it...
				[24, 80]
			end
			
			# The width of the terminal.
			def width
				size.last
			end
			
			# Apply the given style to the output.
			#
			# @parameter foreground [Symbol] The foreground color.
			# @parameter background [Symbol] The background color.
			# @parameter attributes [Array(Symbol)] The attributes to apply.
			# @returns [String] The style code.
			def style(foreground, background = nil, *attributes)
				tokens = []
				
				if foreground
					tokens << 30 + COLORS.fetch(foreground)
				end
				
				if background
					tokens << 40 + COLORS.fetch(background)
				end
				
				attributes.each do |attribute|
					tokens << ATTRIBUTES.fetch(attribute){attribute.to_i}
				end
				
				return "\e[#{tokens.join(';')}m"
			end
			
			# Reset the style.
			#
			# @returns [String] The reset code.
			def reset
				"\e[0m"
			end
		end
	end
end
