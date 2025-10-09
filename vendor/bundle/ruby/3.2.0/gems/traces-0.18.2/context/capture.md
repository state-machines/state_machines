# Capture

This guide explains how to use `traces` for exporting traces from your application. This can be used to document all possible traces.

## With Test Suite

If your application defines one or more traces and emits them as part of a test suite, you can export them using the `bake traces:capture` command.

```bash
$ cd test/traces/backend/.capture/
$ bake traces:capture run traces:capture:list output --format json
[
  {
    "name": "my_trace",
    "attributes": {
      "foo": "baz"
    },
    "context": {
      "trace_id": "038d110379a499a8ebcfb2b77cd69e1a",
      "parent_id": "bf134b25de4f4a82",
      "flags": 0,
      "state": null,
      "remote": false
    }
  },
  {
    "name": "nested",
    "attributes": {
    },
    "context": {
      "trace_id": "038d110379a499a8ebcfb2b77cd69e1a",
      "parent_id": "2dd5510eb8fffc5f",
      "flags": 0,
      "state": null,
      "remote": false
    }
  }
]
```
