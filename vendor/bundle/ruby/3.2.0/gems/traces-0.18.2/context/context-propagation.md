# Context Propagation

This guide explains how to propagate trace context between different execution contexts within your application using `Traces.current_context` and `Traces.with_context`.

## Overview

The `traces` library provides two complementary approaches for managing trace context:

- **Local context propagation** (`Traces.current_context` / `Traces.with_context`): For passing context between execution contexts within the same process (threads, fibers, async tasks).
- **Distributed context propagation** (`Traces.inject` / `Traces.extract`): For transmitting context across process and service boundaries via serialization (HTTP headers, message metadata, etc.).

There is a legacy interface `Traces.trace_context` and `Traces.trace_context=` but you should prefer to use the new methods outlined above.

## Local Context Propagation

Local context propagation involves passing trace context between different execution contexts within the same process. This is essential for maintaining trace continuity when code execution moves between threads, fibers, async tasks, or other concurrent execution contexts. Unlike distributed propagation which requires serialization over network boundaries, local propagation uses Context objects directly.

### Capturing the Current Context

Use `Traces.current_context` to capture the current trace context as a Context object:

~~~ ruby
current_context = Traces.current_context
# Returns a Traces::Context object or nil if no active trace
~~~

### Using the Context

Use `Traces.with_context(context)` to execute code within a specific trace context:

~~~ ruby
# With block (automatic restoration):
Traces.with_context(context) do
	# Code runs with the specified context.
end

# Without block (permanent switch):
Traces.with_context(context)
# Context remains active.
~~~

### Use Cases

#### Thread-Safe Context Propagation

When spawning background threads, you often want them to inherit the current trace context:

~~~ ruby
require 'traces'

# Main thread has active tracing
Traces.trace("main_operation") do
	# Capture current context before spawning thread:
	current_context = Traces.current_context
	
	# Spawn background thread:
	Thread.new do
		# Restore context in the new thread:
		Traces.with_context(current_context) do
			# This thread now has the same trace context as main thread:
			Traces.trace("background_work") do
				perform_heavy_computation
			end
		end
	end.join
end
~~~

#### Fiber-Based Async Operations

For fiber-based concurrency (like in async frameworks), context propagation ensures trace continuity:

~~~ ruby
require 'traces'

Traces.trace("main_operation") do
	current_context = Traces.current_context
	
	# Create fiber for async work:
	fiber = Fiber.new do
		Traces.with_context(current_context) do
			# Fiber inherits the trace context:
			Traces.trace("fiber_work") do
				perform_async_operation
			end
		end
	end
	
	fiber.resume
end
~~~

### Context Propagation vs. New Spans

Remember that context propagation maintains the same trace, while `trace()` creates new spans:

~~~ ruby
Traces.trace("parent") do
	context = Traces.current_context
	
	Thread.new do
		# This maintains the same trace context:
		Traces.with_context(context) do
			# This creates a NEW span within the same trace:
			Traces.trace("child") do
				# Child span, same trace as parent
			end
		end
	end
end
~~~

## Distributed Context Propagation

Distributed context propagation involves transmitting trace context across process and service boundaries. Unlike local propagation which works within a single process, distributed propagation requires serializing context data and transmitting it over network protocols.

### Injecting Context into Headers

Use `Traces.inject(headers, context = nil)` to add W3C Trace Context headers to a headers hash for transmission over network boundaries:

~~~ ruby
require 'traces'

# Capture current context:
context = Traces.current_context
headers = {'Content-Type' => 'application/json'}

# Inject trace headers:
Traces.inject(headers, context)
# headers now contains: {'Content-Type' => '...', 'traceparent' => '00-...'}

# Or use current context by default:
Traces.inject(headers)  # Uses current trace context
~~~

### Extracting Context from Headers

Use `Traces.extract(headers)` to extract trace context from W3C headers received over the network:

~~~ ruby
# Receive headers from incoming request:
incoming_headers = request.headers

# Extract context:
context = Traces.extract(incoming_headers)
# Returns a Traces::Context object or nil if no valid context

# Use the extracted context:
if context
  Traces.with_context(context) do
    # Process request with distributed trace context
  end
end
~~~

### Use Cases

#### Outgoing HTTP Requests

~~~ ruby
require 'traces'

class ApiClient
	def make_request(endpoint, data)
		Traces.trace("api_request", attributes: {endpoint: endpoint}) do
			headers = {
				'content-type' => 'application/json'
			}
			
			# Add trace context to outgoing request:
			Traces.inject(headers)
			
			http_client.post(endpoint, 
				body: data.to_json,
				headers: headers
			)
		end
	end
end
~~~

#### Incoming HTTP Requests

~~~ ruby
require 'traces'

class WebController
	def handle_request(request)
		# Extract trace context from incoming headers:
		context = Traces.extract(request.headers)
		
		# Process request with inherited context:
		if context
			Traces.with_context(context) do
				Traces.trace("web_request", attributes: {
					path: request.path,
					method: request.method
				}) do
					process_business_logic
				end
			end
		else
			Traces.trace("web_request", attributes: {
				path: request.path,
				method: request.method
			}) do
				process_business_logic
			end
		end
	end
end
~~~
