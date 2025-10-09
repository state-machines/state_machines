# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2024, by Samuel Williams.

# Enable capturing metrics.
def capture
	ENV["METRICS_BACKEND"] = "metrics/backend/capture"
	require "metrics"
end

# Generate a list of metrics that have been captured.
def list
	Metrics::Backend::Capture.metrics.sort_by!{|metric| metric.name}
end
