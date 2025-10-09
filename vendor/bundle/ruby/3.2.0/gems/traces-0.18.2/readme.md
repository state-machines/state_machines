# Traces

Capture nested traces during code execution in a vendor agnostic way.

[![Development Status](https://github.com/socketry/traces/workflows/Test/badge.svg)](https://github.com/socketry/traces/actions?workflow=Test)

## Features

  - Zero-overhead if tracing is disabled and minimal overhead if enabled.
  - Small opinionated interface with standardised semantics, consistent with the [W3C Trace Context Specification](https://github.com/w3c/trace-context).

## Usage

Please see the [project documentation](https://socketry.github.io/traces/) for more details.

  - [Getting Started](https://socketry.github.io/traces/guides/getting-started/index) - This guide explains how to use `traces` for tracing code execution.

  - [Context Propagation](https://socketry.github.io/traces/guides/context-propagation/index) - This guide explains how to propagate trace context between different execution contexts within your application using `Traces.current_context` and `Traces.with_context`.

  - [Testing](https://socketry.github.io/traces/guides/testing/index) - This guide explains how to test traces in your code.

  - [Capture](https://socketry.github.io/traces/guides/capture/index) - This guide explains how to use `traces` for exporting traces from your application. This can be used to document all possible traces.

## Releases

Please see the [project releases](https://socketry.github.io/traces/releases/index) for all releases.

### v0.18.1

  - Don't call `prepare` in `traces/provider.rb`. It can cause circular loading warnings.

### v0.18.0

  - **W3C Baggage Support** - Full support for W3C Baggage specification for application-specific context propagation.
  - [New Context Propagation Interfaces](https://socketry.github.io/traces/releases/index#new-context-propagation-interfaces)

### v0.17.0

  - Remove support for `resource:` keyword argument with no direct replacement – use an attribute instead.

### v0.16.0

  - Introduce `traces:provider:list` command to list all available trace providers.

### v0.14.0

  - [Introduce `Traces::Config` to Expose `prepare` Hook](https://socketry.github.io/traces/releases/index#introduce-traces::config-to-expose-prepare-hook)

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

  - [traces-backend-open\_telemetry](https://github.com/socketry/traces-backend-open_telemetry) — A backend for submitting traces to [OpenTelemetry](https://github.com/open-telemetry/opentelemetry-ruby), including [ScoutAPM](https://github.com/scoutapp/scout_apm_ruby).
  - [traces-backend-datadog](https://github.com/socketry/traces-backend-datadog) — A backend for submitting traces to [Datadog](https://github.com/DataDog/dd-trace-rb).
  - [traces-backend-newrelic](https://github.com/newrelic/traces-backend-newrelic) - A backend for submitting traces to [New Relic](https://github.com/newrelic/newrelic-ruby-agent).
  - [metrics](https://github.com/socketry/metrics) — A metrics interface which follows a similar pattern.
