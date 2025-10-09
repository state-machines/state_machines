# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2024, by Samuel Williams.

require_relative "../metric"

module Metrics
	module Backend
		module Capture
			class Metric < Metrics::Metric
				def initialize(...)
					super
					
					@values = []
					@tags = Set.new
					@sample_rates = []
				end
				
				attr :values
				attr :tags
				attr :sample_rates
				
				def emit(value, tags: nil, sample_rate: 1.0)
					@values << value
					@tags.merge(tags) if tags
					@sample_rates << sample_rate
				end
				
				def as_json
					{
						name: @name,
						type: @type,
						description: @description,
						unit: @unit,
						values: @values,
						tags: @tags.to_a.sort,
						sample_rates: @sample_rates.sort.uniq
					}
				end
				
				def to_json(...)
					as_json.to_json(...)
				end
			end
			
			def self.metrics
				@metrics ||= []
			end
			
			module Interface
				def metric(name, type, description: nil, unit: nil, &block)
					metric = Metric.new(name, type, description, unit)
					
					Capture.metrics << metric
					
					return metric
				end
			end
		end
		
		Interface = Capture::Interface
	end
end
