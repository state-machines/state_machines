# Testing

This guide explains how to test traces in your code.

## Expectations

One approach to testing traces are emitted, is by using mocks to verify that methods are called with the expected arguments.

```ruby
it "should trace the operation" do
	expect(Traces).to receive(:trace).with("my_controller.do_something")
	
	my_controller.do_something
end
```

This is generally a good appoach for testing that specific traces are emitted.

## Validation

The traces gem supports a variety of backends, and each backend may have different requirements for the data that is submitted. The test backend is designed to be used for testing that the data submitted is valid.

```ruby
ENV['TRACES_BACKEND'] = 'traces/backend/test'

require 'traces'

Traces.trace(5) do
	puts "Hello"
end
# => lib/traces/backend/test.rb:52:in `trace': Invalid name (must be String): 5! (ArgumentError)
```
