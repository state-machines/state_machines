# ![IO::Event](logo.svg)

Provides low level cross-platform primitives for constructing event loops, with support for `select`, `kqueue`, `epoll` and `io_uring`.

[![Development Status](https://github.com/socketry/io-event/workflows/Test/badge.svg)](https://github.com/socketry/io-event/actions?workflow=Test)

## Motivation

The initial proof-of-concept [Async](https://github.com/socketry/async) was built on [NIO4r](https://github.com/socketry/nio4r). It was perfectly acceptable and well tested in production, however being built on `libev` was a little bit limiting. I wanted to directly build my fiber scheduler into the fabric of the event loop, which is what this gem exposes - it is specifically implemented to support building event loops beneath the fiber scheduler interface, providing an efficient C implementation of all the core operations.

## Usage

Please see the [project documentation](https://socketry.github.io/io-event/) for more details.

  - [Getting Started](https://socketry.github.io/io-event/guides/getting-started/index) - This guide explains how to use `io-event` for non-blocking IO.

## Releases

Please see the [project releases](https://socketry.github.io/io-event/releases/index) for all releases.

### v1.11.2

  - Fix Windows build.

### v1.11.1

  - Fix `read_nonblock` when using the `URing` selector, which was not handling zero-length reads correctly. This allows reading available data without blocking.

### v1.11.0

  - [Introduce `IO::Event::WorkerPool` for off-loading blocking operations.](https://socketry.github.io/io-event/releases/index#introduce-io::event::workerpool-for-off-loading-blocking-operations.)

### v1.10.2

  - Improved consistency of handling closed IO when invoking `#select`.

### v1.10.0

  - `IO::Event::Profiler` is moved to dedicated gem: [fiber-profiler](https://github.com/socketry/fiber-profiler).
  - Perform runtime checks for native selectors to ensure they are supported in the current environment. While compile-time checks determine availability, restrictions like seccomp and SELinux may still prevent them from working.

### v1.9.0

  - Improved `IO::Event::Profiler` for detecting stalls.

### v1.8.0

  - Detecting fibers that are stalling the event loop.

### v1.7.5

  - Fix `process_wait` race condition on EPoll that could cause a hang.

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
