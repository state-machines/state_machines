# Getting Started

This guide explains how to use `metrics` for capturing run-time metrics.

## Installation

Add the gem to your project:

~~~ bash
$ bundle add metrics
~~~

## Core Concepts

`metrics` has several core concepts:

- A {ruby Metrics::Provider} which implements custom logic for extracting metrics from existing code.
- A {ruby Metrics::Backend} which connects metrics to a specific backend system for processing.

## Usage

There are two main aspects to integrating within this gem.

1. Libraries and applications must expose metrics.
2. Those metrics must be consumed or emitted somewhere.

### Exposing Metrics

Adding metrics to libraries requires the use of {ruby Metrics::Provider}:

~~~ ruby
require 'metrics'

class MyClass
	def my_method
		puts "Hello World"
	end
end

# If metrics are disabled, this is a no-op.
Metrics::Provider(MyClass) do
	CALL_COUNT = Metrics.metric('call_count', :counter, description: 'Number of times invoked.')
	
	def my_method
		CALL_COUNT.emit(1)
		
		super
	end
end

MyClass.new.my_method
~~~

This code by itself will not create any metrics. In order to execute it and output metrics, you must set up a backend to consume them.

#### Class Methods

You can also expose metrics for class methods:

~~~ ruby
require 'metrics'

class MyClass
	def self.my_method
		puts "Hello World"
	end
end

Metrics::Provider(MyClass.singleton_class) do
	CALL_COUNT = Metrics.metric('call_count', :counter, description: 'Number of times invoked.')
	
	def my_method
		CALL_COUNT.emit(1)
		
		super
	end
end

MyClass.my_method
~~~

### Consuming Metrics

Consuming metrics means proving a backend implementation which can record those metrics to some log or service. There are several options, but two backends are included by default:

- `metrics/backend/test` does not emit any metrics, but validates the usage of the metric interface.
- `metrics/backend/console` emits metrics using the [`console`](https://github.com/socketry/console) gem.

In order to use a specific backend, set the `METRICS_BACKEND` environment variable, e.g.

~~~ shell
$ METRICS_BACKEND=metrics/backend/console ./my_script.rb
~~~
