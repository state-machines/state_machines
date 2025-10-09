# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

module Metrics
	module Tags
		def self.normalize(tags, into = nil)
			return into unless tags&.any?
			
			into ||= []
			
			if tags.is_a?(Array)
				into.concat(tags)
			else
				tags.each do |key, value|
					if value
						into << "#{key}:#{value}"
					end
				end
			end
			
			return into
		end
	end
end
