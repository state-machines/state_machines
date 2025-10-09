# Fiber::Storage

This gem provides a shim for `Fiber.[]`, `Fiber.[]=`, `Fiber#storage`, `Fiber#storage=`, which was introduced in Ruby 3.2.

[![Development Status](https://github.com/ioquatix/fiber-storage/workflows/Test/badge.svg)](https://github.com/ioquatix/fiber-storage/actions?workflow=Test)

## Motivation

Ruby 3.2 introduces inheritable fiber storage for per-request or per-operation state. This gem provides a shim for Ruby 3.1 and earlier to make adoption easier. It isn't able to provide the full range of features, but it should be sufficient for most use cases.

Notably, it does not support inheritance across threads or lazy Enumerator. This is a limitation of the shim implementation.

## Usage

Please see the [project documentation](https://ioquatix.github.io/fiber-storage/) for more details.

  - [Getting Started](https://ioquatix.github.io/fiber-storage/guides/getting-started/index) - This guide explains how to use this gem and provides a brief overview of the features.

## Releases

Please see the [project releases](https://ioquatix.github.io/fiber-storage/releases/index) for all releases.

### v1.0.1

  - Fix test suite incompatibiltiies with Ruby 3.4+.

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
