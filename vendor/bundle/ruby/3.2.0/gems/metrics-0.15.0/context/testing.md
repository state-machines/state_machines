# Testing

This guide explains how to write assertions in your test suite to validate `metrics` are being emitted correctly.

## Application Code

In your application code, you should emit metrics, e.g.

```ruby
require 'metrics/provider'

class MyApplication
	def work
		# ...
	end
	
	Metrics::Provider(self) do
		WORK_METRIC = Metrics.metric('my_application.work.count', :counter, description: 'Work counter')
		
		def work
			WORK_METRIC.emit(1)
			super
		end
	end
end
```

## Test Code

In your test code, you should assert that the metrics are being emitted correctly, e.g.

```ruby
ENV['METRICS_BACKEND'] ||= 'metrics/backend/test'

require_relative 'app'

describe MyApplication do
	it 'should emit metrics' do
		expect(MyApplication::WORK_METRIC).to receive(:emit).with(1)
		MyApplication.new.work
	end
end
```
