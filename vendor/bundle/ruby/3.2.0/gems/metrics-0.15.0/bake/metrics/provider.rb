# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

# List available providers for metrics from all loaded gems.
def list
	available = {}
	
	Gem.loaded_specs.each do |name, spec|
		spec.require_paths.each do |require_path|
			root = File.expand_path(require_path, spec.full_gem_path)
			Dir.glob("metrics/provider/**/*.rb", base: root).each do |path|
				(available[name] ||= []) << path
			end
		end
	end
	
	return available
end
