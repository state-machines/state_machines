# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

module Console
	module Terminal
		module Formatter
			# Format a progress event, including the current progress and total.
			class Progress
				# The key used to identify this formatter.
				KEY = :progress
				
				# The block characters used to render the progress bar.
				BLOCK = [
					" ",
					"▏",
					"▎",
					"▍",
					"▌",
					"▋",
					"▊",
					"▉",
					"█",
				]
				
				# Create a new progress formatter.
				#
				# @param terminal [Terminal::Text] The terminal to use for formatting.
				def initialize(terminal)
					@terminal = terminal
					@terminal[:progress_bar] ||= terminal.style(:blue, :white)
				end
				
				# Format the given event.
				#
				# @parameter event [Hash] The event to format.
				# @parameter stream [IO] The stream to write the formatted event to.
				# @parameter verbose [Boolean] Whether to include additional information.
				# @parameter width [Integer] The width of the progress bar.
				def format(event, stream, verbose: false, width: 80)
					current = event[:current].to_f
					total = event[:total].to_f
					value = current / total
					
					# Clamp value to 1.0 to avoid rendering issues:
					if value > 1.0
						value = 1.0
					end
					
					stream.puts "#{@terminal[:progress_bar]}#{self.bar(value, width-10)}#{@terminal.reset} #{sprintf('%6.2f', value * 100)}%"
				end
				
				private
				
				# Render a progress bar with the given value and width.
				def bar(value, width)
					blocks = width * value
					full_blocks = blocks.floor
					partial_block = ((blocks - full_blocks) * BLOCK.size).floor
					
					if partial_block.zero?
						BLOCK.last * full_blocks
					else
						"#{BLOCK.last * full_blocks}#{BLOCK[partial_block]}"
					end.ljust(width)
				end
			end
		end
	end
end
