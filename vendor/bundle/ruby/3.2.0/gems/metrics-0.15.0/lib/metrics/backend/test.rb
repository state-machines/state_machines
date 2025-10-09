# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

require_relative "../metric"

module Metrics
	module Backend
		module Test
			VALID_METRIC_NAME = /\A[a-z0-9\-_\.]{1,128}\Z/i
			VALID_TAG = /\A[a-z][a-z0-9\-_\.:\\]{0,127}\Z/i
			
			class Metric < Metrics::Metric
				def emit(value, tags: nil, sample_rate: 1.0)
					unless value.is_a?(Numeric)
						raise ArgumentError, "Value must be numeric!"
					end
					
					tags&.each do |tag|
						raise ArgumentError, "Invalid tag (must be String): #{tag.inspect}!" unless tag.is_a?(String)
						
						# We should let the underlying backend handle any tag limitations, e.g. converting invalid characters to underscores, etc.
						#
						# unless tag =~ VALID_TAG
						# 	raise ArgumentError, "Invalid tag (must match #{VALID_TAG}): #{tag.inspect}!"
						# end
					end
				end
			end
			
			module Interface
				def metric(name, type, description: nil, unit: nil, &block)
					unless name.is_a?(String)
						raise ArgumentError, "Invalid name (must be String): #{name.inspect}!"
					end
					
					unless name =~ VALID_METRIC_NAME
						raise ArgumentError, "Invalid name (must match #{VALID_METRIC_NAME}): #{name.inspect}!"
					end
					
					unless type.is_a?(Symbol)
						raise ArgumentError, "Invalid type (must be Symbol): #{type.inspect}!"
					end
					
					# Description is optional but must be string if given:
					if description
						unless description.is_a?(String)
							raise ArgumentError, "Invalid description (must be String): #{description.inspect}!"
						end
					end
					
					# Unit is optional but must be string if given:
					if unit
						unless unit.is_a?(String)
							raise ArgumentError, "Invalid unit (must be String): #{unit.inspect}!"
						end
					end
					
					return Metric.new(name, type, description, unit)
				end
			end
		end
		
		Interface = Test::Interface
	end
end
