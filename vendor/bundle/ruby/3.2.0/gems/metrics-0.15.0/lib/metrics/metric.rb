# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2022, by Samuel Williams.

module Metrics
	class Metric
		def initialize(name, type, description, unit)
			@name = name
			@type = type
			@description = description
			@unit = unit
		end
		
		attr :name
		attr :type
		attr :description
		attr :unit
		
		def emit(value, tags: nil, sample_rate: 1.0)
			raise NotImplementedError
		end
	end
end
