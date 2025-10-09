# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2025, by Samuel Williams.

# Enable capturing traces.
def capture
	ENV["TRACES_BACKEND"] = "traces/backend/capture"
	require "traces"
end

# Generate a list of traces that have been captured.
def list
	Traces::Backend::Capture.spans.sort_by!{|span| span.name}
end
