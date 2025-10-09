# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.
# Copyright, 2021, by Robert Schulze.

require_relative "../clock"
require_relative "../terminal"

require "json"
require "fiber"
require "fiber/annotation"
require "stringio"

module Console
	module Output
		# Represents a terminal output, and formats log messages for display.
		class Terminal
			# Represents an output buffer that formats lines with a prefix.
			class Buffer < StringIO
				# Create a new buffer with the given prefix.
				#
				# @parameter prefix [String] The prefix to use for each line.
				def initialize(prefix = nil)
					@prefix = prefix
					
					super()
				end
				
				# @attribute [String] The prefix to use for each line.
				attr :prefix
				
				# Write lines using the given prefix.
				#
				# @parameter lines [Array] The lines to write.
				# @parameter prefix [String] The prefix to use for each line.
				def puts(*lines, prefix: @prefix)
					lines.each do |line|
						self.write(prefix) if prefix
						super(line)
					end
				end
				
				# Write a line to the buffer.
				alias << puts
			end
			
			# The environment variable used to store the start time of the console terminal output.
			CONSOLE_START_AT = "CONSOLE_START_AT"
			
			# Exports CONSOLE_START_AT which can be used to synchronize the start times of all child processes when they log using delta time.
			def self.start_at!(env = ENV)
				if time_string = env[CONSOLE_START_AT]
					start_at = Time.parse(time_string) rescue nil
				end
				
				unless start_at
					start_at = Time.now
					env[CONSOLE_START_AT] = start_at.to_s
				end
				
				return start_at
			end
			
			# Create a new terminal output.
			#
			# @parameter stream [IO] The output stream.
			# @parameter verbose [Boolean] Whether to print verbose output.
			# @parameter start_at [Time] The start time of the terminal output.
			# @parameter format [Console::Terminal::Format] The format to use for terminal output.
			# @parameter options [Hash] Additional options to customize the output.
			def initialize(stream, verbose: nil, start_at: Terminal.start_at!, format: nil, **options)
				@stream = stream
				@start_at = start_at
				
				@terminal = format.nil? ? Console::Terminal.for(@stream) : format.new(@stream)
				
				if verbose.nil?
					@verbose = !@terminal.colors?
				else
					@verbose = verbose
				end
				
				@terminal[:logger_suffix] ||= @terminal.style(:white, nil, :faint)
				@terminal[:subject] ||= @terminal.style(nil, nil, :bold)
				@terminal[:debug] = @terminal.style(:cyan)
				@terminal[:info] = @terminal.style(:green)
				@terminal[:warn] = @terminal.style(:yellow)
				@terminal[:error] = @terminal.style(:red)
				@terminal[:fatal] = @terminal[:error]
				
				@terminal[:annotation] = @terminal.reset
				@terminal[:value] = @terminal.style(:blue)
				
				@formatters = {}
				self.register_formatters
			end
			
			# This a final output.
			def last_output
				self
			end
			
			# @attribute [IO] The output stream.
			attr :stream
			
			# @attribute [Boolean] Whether to print verbose output.
			attr_accessor :verbose
			
			# @attribute [Time] The start time of the terminal output.
			attr :start
			
			# @attribute [Console::Terminal::Format] The format to use for terminal output.
			attr :terminal
			
			# Set the verbose output.
			#
			# @parameter value [Boolean] Whether to print verbose output.
			def verbose!(value = true)
				@verbose = value
			end
			
			# Register all formatters in the given namespace.
			def register_formatters(namespace = Console::Terminal::Formatter)
				namespace.constants.each do |name|
					formatter = namespace.const_get(name)
					@formatters[formatter::KEY] = formatter.new(@terminal)
				end
			end
			
			# The default severity for log messages, if not specified.
			UNKNOWN = :unknown
			
			# Log a message with the given severity.
			#
			# @parameter subject [String] The subject of the log message.
			# @parameter arguments [Array] The arguments to log.
			# @parameter name [String | Nil] The optional name of the log message, used as a prefix, otherwise defaults to the severity name.
			# @parameter severity [Symbol] The severity of the log message.
			# @parameter event [Hash] The event to log.
			# @parameter options [Hash] Additional options.
			# @yields {|buffer, terminal| ...} An optional block used to generate the log message.
			# 	@parameter buffer [Console::Output::Terminal::Buffer] The output buffer.
			# 	@parameter terminal [Console::Terminal] The terminal instance.
			def call(subject = nil, *arguments, name: nil, severity: UNKNOWN, event: nil, **options, &block)
				width = @terminal.width
				
				prefix = build_prefix(name || severity.to_s)
				indent = " " * prefix.size
				
				buffer = Buffer.new("#{indent}| ")
				indent_size = buffer.prefix.size
				
				format_subject(severity, prefix, subject, buffer)
				
				arguments.each do |argument|
					format_argument(argument, buffer)
				end
				
				if block_given?
					if block.arity.zero?
						format_argument(yield, buffer)
					else
						yield(buffer, @terminal)
					end
				end
				
				if event
					format_event(event, buffer, width - indent_size)
				end
				
				if options&.any?
					format_options(options, buffer)
				end
				
				@stream.write buffer.string
			end
			
			protected
			
			def format_event(event, buffer, width)
				event = event.to_hash
				type = event[:type]
				
				if formatter = @formatters[type]
					formatter.format(event, buffer, verbose: @verbose, width: width)
				else
					format_value(::JSON.pretty_generate(event), buffer)
				end
			end
			
			def format_options(options, output)
				format_value(::JSON.pretty_generate(options), output)
			end
			
			def format_argument(argument, output)
				argument.to_s.each_line do |line|
					output.puts line
				end
			end
			
			def format_subject(severity, prefix, subject, buffer)
				if subject.is_a?(String)
					format_string_subject(severity, prefix, subject, buffer)
				elsif subject.is_a?(Module)
					format_string_subject(severity, prefix, subject.to_s, buffer)
				else
					format_object_subject(severity, prefix, subject, buffer)
				end
			end
			
			def default_suffix(object = nil)
				buffer = +""
				
				if @verbose
					if annotation = Fiber.current.annotation
						# While typically annotations should be strings, that is not always the case.
						annotation = annotation.to_s
						
						# If the annotation is empty, we don't want to print it, as it will look like a formatting bug.
						if annotation.size > 0
							buffer << ": #{@terminal[:annotation]}#{annotation}#{@terminal.reset}"
						end
					end
				end
				
				buffer << " #{@terminal[:logger_suffix]}"
				
				if object
					buffer << "[oid=0x#{object.object_id.to_s(16)}] "
				end
				
				buffer << "[ec=0x#{Fiber.current.object_id.to_s(16)}] [pid=#{Process.pid}] [#{::Time.now}]#{@terminal.reset}"
				
				return buffer
			end
			
			def format_object_subject(severity, prefix, subject, output)
				prefix_style = @terminal[severity]
				
				if @verbose
					suffix = default_suffix(subject)
				end
				
				prefix = "#{prefix_style}#{prefix}:#{@terminal.reset} "
				
				output.puts "#{@terminal[:subject]}#{subject.class}#{@terminal.reset}#{suffix}", prefix: prefix
			end
			
			def format_string_subject(severity, prefix, subject, output)
				prefix_style = @terminal[severity]
				
				if @verbose
					suffix = default_suffix
				end
				
				prefix = "#{prefix_style}#{prefix}:#{@terminal.reset} "
				
				output.puts "#{@terminal[:subject]}#{subject}#{@terminal.reset}#{suffix}", prefix: prefix
			end
			
			def format_value(value, output)
				string = value.to_s
				
				string.each_line do |line|
					line.chomp!
					output.puts "#{@terminal[:value]}#{line}#{@terminal.reset}"
				end
			end
			
			def time_offset_prefix
				Clock.formatted_duration(Time.now - @start_at).rjust(6)
			end
			
			def build_prefix(name)
				if @verbose
					"#{time_offset_prefix} #{name.rjust(8)}"
				else
					time_offset_prefix
				end
			end
		end
		
		# Terminal text output.
		module Text
			# Create a new terminal output.
			#
			# @parameter output [IO] The output stream.
			# @parameter options [Hash] Additional options to customize the output.
			# @returns [Console::Output::Terminal] The terminal output instance.
			def self.new(output, **options)
				Terminal.new(output, format: Console::Terminal::Text, **options)
			end
		end
		
		# Terminal XTerm output.
		module XTerm
			# Create a new terminal output.
			#
			# You can use this to force XTerm output on a non-TTY output streams that support XTerm escape codes.
			#
			# @parameter output [IO] The output stream.
			# @parameter options [Hash] Additional options to customize the output.
			# @returns [Console::Output::Terminal] The terminal output instance.
			def self.new(output, **options)
				Terminal.new(output, format: Console::Terminal::XTerm, **options)
			end
		end
	end
end
