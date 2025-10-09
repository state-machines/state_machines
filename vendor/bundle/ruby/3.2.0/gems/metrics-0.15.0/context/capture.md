# Capture

This guide explains how to use `metrics` for exporting metric definitions from your application.

## With Provider Metrics

If your application defines one or more metrics, you can export them using the `bake metrics:document` command. This command will generate a list of metrics which you can export.

```bash
$ cd test/metrics/backend/.capture/
$ bake metrics:capture environment metrics:capture:list output --format json
[
  {
    "name": "my_metric",
    "type": "gauge",
    "description": "My metric",
    "unit": "seconds",
    "values": [

    ],
    "tags": [

    ],
    "sample_rates": [

    ]
  }
]
```

## With Test Suite

If your application has a test suite which emits metrics, you can capture those as samples for the purpose of your documentation. This includes fields like tags.

```bash
$ cd test/metrics/backend/.capture/
$ bake metrics:capture run metrics:capture:list output --format json
[
  {
    "name": "my_metric",
    "type": "gauge",
    "description": "My metric",
    "unit": "seconds",
    "values": [
      1
    ],
    "tags": [
      "environment:test"
    ],
    "sample_rates": [
      1.0
    ]
  }
]
```

This uses a custom task called `run` in the above example, but you should probably consider using `bake test` which runs your test suite.
