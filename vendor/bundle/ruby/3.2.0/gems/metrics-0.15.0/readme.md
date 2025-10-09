# Metrics

Capture metrics about code execution in a vendor agnostic way. As the author of many libraries which would benefit from metrics, there are few key priorities: (1) zero overhead if metrics are disabled, minimal overhead if enabled, and (2) a small and opinionated interface with standardised semantics.

[![Development Status](https://github.com/socketry/metrics/workflows/Test/badge.svg)](https://github.com/socketry/metrics/actions?workflow=Test)

## Features

  - Zero-overhead if tracing is disabled and minimal overhead if enabled.
  - Small opinionated interface with standardised semantics.

## Usage

Please see the [project documentation](https://socketry.github.io/metrics/) for more details.

  - [Getting Started](https://socketry.github.io/metrics/guides/getting-started/index) - This guide explains how to use `metrics` for capturing run-time metrics.

  - [Capture](https://socketry.github.io/metrics/guides/capture/index) - This guide explains how to use `metrics` for exporting metric definitions from your application.

  - [Testing](https://socketry.github.io/metrics/guides/testing/index) - This guide explains how to write assertions in your test suite to validate `metrics` are being emitted correctly.

## Releases

Please see the [project releases](https://socketry.github.io/metrics/releases/index) for all releases.

### v0.15.0

  - Add `into = nil` parameter to `Metrics::Tags.normalize(tags, into = nil)` to allow reusing an existing array.

### v0.14.0

  - Don't call `prepare` in `metrics/provider.rb`. It can cause circular loading warnings.

### v0.13.0

  - Introduce `metrics:provider:list` command to list all available metrics providers.

### v0.12.1

  - [Introduce `Metrics::Config` to Expose `prepare` Hook](https://socketry.github.io/metrics/releases/index#introduce-metrics::config-to-expose-prepare-hook)

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

  - [metrics-backend-datadog](https://github.com/socketry/metrics-backend-datadog) — A Metrics backend for Datadog.
  - [traces](https://github.com/socketry/traces) — A code tracing interface which follows a similar pattern.
