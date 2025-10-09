# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

require_relative "../metric"

require "console"

module Metrics
	module Backend
		module Console
			class Metric < Metrics::Metric
				def emit(value, tags: nil, sample_rate: 1.0)
					::Console.logger.info(self, @name, value, tags)
				end
			end
			
			module Interface
				def metric(name, type, description: nil, unit: nil, &block)
					return Metric.new(name, type, description, unit)
				end
				
				# def metric_call_counter(name, description: nil, tags: nil)
				# 	metric = self.metric(...)
				# 
				# 	self.define_method(name) do
				# 		metric.emit(1)
				#			super
				# 	end
				# end
			end
		end
		
		Interface = Console::Interface
	end
end
