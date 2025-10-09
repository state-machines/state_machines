# Releases

## v0.18.1

  - Don't call `prepare` in `traces/provider.rb`. It can cause circular loading warnings.

## v0.18.0

  - **W3C Baggage Support** - Full support for W3C Baggage specification for application-specific context propagation.

### New Context Propagation Interfaces

`Traces#trace_context` and `Traces.trace_context` are insufficient for efficient inter-process tracing when using OpenTelemetry. That is because OpenTelemetry has it's own "Context" concept with arbitrary key-value storage (of which the current span is one such key/value pair). Unfortunately, OpenTelemetry requires those values to be propagated "inter-process" while ignores them for "intra-process" tracing.

Therefore, in order to propagate this context, we introduce 4 new methods:

  - `Traces.current_context` - Capture the current trace context for local propagation between execution contexts (threads, fibers).
  - `Traces.with_context(context)` - Execute code within a specific trace context, with automatic restoration when used with blocks.
  - `Traces.inject(headers = nil, context = nil)` - Inject W3C Trace Context headers into a headers hash for distributed propagation.
  - `Traces.extract(headers)` - Extract trace context from W3C Trace Context headers.

The default implementation is built on top of `Traces.trace_context`, however these methods can be replaced by the backend. In that case, the `context` object is opaque, in other words it is library-specific, and you should not assume it is an instance of `Traces::Context`.

## v0.17.0

  - Remove support for `resource:` keyword argument with no direct replacement – use an attribute instead.

## v0.16.0

  - Introduce `traces:provider:list` command to list all available trace providers.

## v0.14.0

### Introduce `Traces::Config` to Expose `prepare` Hook

The `traces` gem uses aspect-oriented programming to wrap existing methods to emit traces. However, while there are some reasonable defaults for emitting traces, it can be useful to customize the behavior and level of detail. To that end, the `traces` gem now optionally loads a `config/traces.rb` which includes a `prepare` hook that can be used to load additional providers.

``` ruby
# config/traces.rb

def prepare
	require 'traces/provider/async'
	require 'traces/provider/async/http'
end
```

The `prepare` method is called immediately after the traces backend is loaded. You can require any provider you want in this file, or even add your own custom providers.
