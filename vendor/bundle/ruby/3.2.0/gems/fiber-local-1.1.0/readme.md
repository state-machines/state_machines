# Fiber::Local

A module to simplify fiber-local state.

[![Development Status](https://github.com/socketry/fiber-local/workflows/Test/badge.svg)](https://github.com/socketry/fiber-local/actions?workflow=Test)

## Features

  - Easily access fiber-local state from a fiber.
  - Default to shared thread-local state.

## Installation

``` bash
$ bundle add fiber-local
```

## Usage

In your own class, e.g. `Logger`:

``` ruby
class Logger
	extend Fiber::Local
	
	def initialize
		@buffer = []
	end
	
	def log(*arguments)
		@buffer << arguments
	end
end
```

Now, instead of instantiating your cache `LOGGER = Logger.new`, use `Logger.instance`. It will return a thread-local instance.

``` ruby
Thread.new do
	Logger.instance
	# => #<Logger:0x000055a14ec6be80>
end

Thread.new do
	Logger.instance
	# => #<Logger:0x000055a14ec597d0>
end
```

In cases where you have job per fiber or request per fiber, you might want to collect all log output for a specific fiber, you can do the following:

``` ruby
Logger.instance
# => #<Logger:0x000055a14ec6be80>

Fiber.new do
	Logger.instance = Logger.new
	# => #<Logger:0x000055a14ec597d0>
end
```

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

### Developer Certificate of Origin

This project uses the [Developer Certificate of Origin](https://developercertificate.org/). All contributors to this project must agree to this document to have their contributions accepted.

### Contributor Covenant

This project is governed by the [Contributor Covenant](https://www.contributor-covenant.org/). All contributors and participants agree to abide by its terms.

## See Also

  - [thread-local](https://github.com/socketry/thread-local) — Strictly thread-local variables.
