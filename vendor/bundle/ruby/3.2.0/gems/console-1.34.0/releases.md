# Releases

## v1.34.0

  - Allow `Console::Compatible::Logger#add` to accept `**options`.

## v1.32.0

  - Add `fiber_id` to serialized output records to help identify which fiber logged the message.
  - Ractor support appears broken in older Ruby versions, so we now require Ruby 3.4 or later for Ractor compatibility, if you need Ractor support.

## v1.31.0

### Ractor compatibility.

The console library now works correctly with Ruby's Ractor concurrency model. Previously, attempting to use console logging within Ractors would fail with errors about non-shareable objects. This has been fixed by ensuring the default configuration is properly frozen.

``` ruby
# This now works without errors:
ractor = Ractor.new do
  require 'console'
  Console.info('Hello from Ractor!')
  'Ractor completed successfully'
end

result = ractor.take
puts result # => 'Ractor completed successfully'
```

The fix is minimal and maintains full backward compatibility while enabling safe parallel logging across multiple Ractors.

### Symbol log level compatibility.

Previously, returning symbols from custom `log_level` methods in configuration files would cause runtime errors like "comparison of Integer with :debug failed". This has been fixed to properly convert symbols to their corresponding integer values.

``` ruby
# config/console.rb - This now works correctly:
def log_level(env = ENV)
	:debug  # Automatically converted to Console::Logger::LEVELS[:debug]
end
```

While this fix maintains backward compatibility, the recommended approach is still to use integer values directly:

``` ruby
# config/console.rb - Recommended approach:
def log_level(env = ENV)
	Console::Logger::LEVELS[:debug]  # Returns 0
end
```

### Improved output format selection for cron jobs and email contexts.

When `MAILTO` environment variable is set (typically in cron jobs), the console library now prefers human-readable terminal output instead of JSON serialized output, even when the output stream is not a TTY. This ensures that cron job output sent via email is formatted in a readable way for administrators.

``` ruby
# Previously in cron jobs (non-TTY), this would output JSON:
# {"time":"2025-06-07T10:30:00Z","severity":"info","subject":"CronJob","message":["Task completed"]}

# Now with MAILTO set, it outputs human-readable format:
#   0.1s     info: CronJob
#                | Task completed
```

This change is conservative and only affects environments where `MAILTO` is explicitly set, ensuring compatibility with existing deployments.

## v1.30.0

### Introduce `Console::Config` for fine grained configuration.

Introduced a new explicit configuration interface via config/console.rb to enhance logging setup in complex applications. This update gives the application code an opportunity to load files if required and control aspects such as log level, output, and more. Users can override default behaviors (e.g., make\_output, make\_logger, and log\_level) for improved customization.

``` ruby
# config/console.rb
def log_level(env = ENV)
	# Set a custom log level, e.g., force debug mode:
	:debug
end

def make_logger(output = $stderr, env = ENV, **options)
	# Custom logger configuration with verbose output:
	options[:verbose] = true
	
	 Logger.new(output, **options)
end
```

This approach provides a standard way to hook into the log setup process, allowing tailored adjustments for reliable and customizable logging behavior.

## v1.29.3

  - Serialized output now uses `IO#write` with a single string to reduce the chance of interleaved output.

## v1.29.2

  - Always return `nil` from `Console::Filter` logging methods.

## v1.29.1

  - Fix logging `exception:` keyword argument when the value was not an exception.

## v1.29.0

  - Don't make `Kernel#warn` redirection to `Console.warn` the default behavior, you must `require 'console/warn'` to enable it.
  - Remove deprecated `Console::Logger#failure`.

### Consistent handling of exceptions.

`Console.call` and all wrapper methods will now consistently handle exceptions that are the last positional argument or keyword argument. This means that the following code will work as expected:

``` ruby
begin
rescue => error
	# Last positional argument:
	Console.warn(self, "There may be an issue", error)
	
	# Keyword argument (preferable):
	Console.error(self, "There is an issue", exception: error)
end
```

## v1.28.0

  - Add support for `Kernel#warn` redirection to `Console.warn`.
