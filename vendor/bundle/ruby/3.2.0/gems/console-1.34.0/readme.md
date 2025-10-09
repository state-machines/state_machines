# Console

Provides beautiful console logging for Ruby applications. Implements fast, buffered log output.

[![Development Status](https://github.com/socketry/console/workflows/Test/badge.svg)](https://github.com/socketry/console/actions?workflow=Test)

## Motivation

When Ruby decided to reverse the order of exception backtraces, I finally gave up using the built in logging and decided restore sanity to the output of my programs once and for all\!

## Features

  - Thread safe global logger with per-fiber context.
  - Carry along context with nested loggers.
  - Enable/disable log levels per-class.
  - Detailed logging of exceptions.
  - Beautiful logging to the terminal or structured logging using JSON.

## Usage

Please see the [project documentation](https://socketry.github.io/console/) for more details.

  - [Getting Started](https://socketry.github.io/console/guides/getting-started/index) - This guide explains how to use `console` for logging.

  - [Command Line](https://socketry.github.io/console/guides/command-line/index) - This guide explains how the `console` gem can be controlled using environment variables.

  - [Configuration](https://socketry.github.io/console/guides/configuration/index) - This guide explains how to implement per-project configuration for the `console` gem.

  - [Integration](https://socketry.github.io/console/guides/integration/index) - This guide explains how to integrate the `console` output into different systems.

  - [Events](https://socketry.github.io/console/guides/events/index) - This guide explains how to log structured events with a well-defined schema.

## Releases

Please see the [project releases](https://socketry.github.io/console/releases/index) for all releases.

### v1.34.0

  - Allow `Console::Compatible::Logger#add` to accept `**options`.

### v1.32.0

  - Add `fiber_id` to serialized output records to help identify which fiber logged the message.
  - Ractor support appears broken in older Ruby versions, so we now require Ruby 3.4 or later for Ractor compatibility, if you need Ractor support.

### v1.31.0

  - [Ractor compatibility.](https://socketry.github.io/console/releases/index#ractor-compatibility.)
  - [Symbol log level compatibility.](https://socketry.github.io/console/releases/index#symbol-log-level-compatibility.)
  - [Improved output format selection for cron jobs and email contexts.](https://socketry.github.io/console/releases/index#improved-output-format-selection-for-cron-jobs-and-email-contexts.)

### v1.30.0

  - [Introduce `Console::Config` for fine grained configuration.](https://socketry.github.io/console/releases/index#introduce-console::config-for-fine-grained-configuration.)

### v1.29.3

  - Serialized output now uses `IO#write` with a single string to reduce the chance of interleaved output.

### v1.29.2

  - Always return `nil` from `Console::Filter` logging methods.

### v1.29.1

  - Fix logging `exception:` keyword argument when the value was not an exception.

### v1.29.0

  - Don't make `Kernel#warn` redirection to `Console.warn` the default behavior, you must `require 'console/warn'` to enable it.
  - Remove deprecated `Console::Logger#failure`.
  - [Consistent handling of exceptions.](https://socketry.github.io/console/releases/index#consistent-handling-of-exceptions.)

### v1.28.0

  - Add support for `Kernel#warn` redirection to `Console.warn`.

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

### Developer Certificate of Origin

In order to protect users of this project, we require all contributors to comply with the [Developer Certificate of Origin](https://developercertificate.org/). This ensures that all contributions are properly licensed and attributed.

### Community Guidelines

This project is best served by a collaborative and respectful environment. Treat each other professionally, respect differing viewpoints, and engage constructively. Harassment, discrimination, or harmful behavior is not tolerated. Communicate clearly, listen actively, and support one another. If any issues arise, please inform the project maintainers.

## See Also

  - [console-adapter-rails](https://github.com/socketry/console-adapter-rails)
  - [console-adapter-sidekiq](https://github.com/socketry/console-adapter-sidekiq)
  - [console-output-datadog](https://github.com/socketry/console-output-datadog)
  - [sus-fixtures-console](https://github.com/sus-rb/sus-fixtures-console)
