prometheus_client
===

[![Pub Version](https://img.shields.io/pub/v/prometheus_client)][prometheus_client]
[![Dart CI](https://github.com/tentaclelabs/prometheus_client/actions/workflows/dart.yml/badge.svg)](https://github.com/tentaclelabs/prometheus_client/actions/workflows/dart.yml)

This is a simple Dart implementation of the [Prometheus][prometheus] client
library, [similar to to libraries for other languages][writing_clientlibs]. It supports the default metric types like
gauges, counters, summaries, or histograms. Metrics can be exported using the [text format][text_format]. To expose them
in your server application the package comes with the package [prometheus_client_shelf][prometheus_client_shelf] to
integrate metrics with a [shelf][shelf] handler. In addition, it comes with some plug-in ready metrics for the Dart
runtime.

You can find the latest updates in the [changelog][changelog].

## Usage

A simple usage example:

```dart
import 'dart:io';

import 'package:prometheus_client/format.dart' as format;
import 'package:prometheus_client/prometheus_client.dart';
import 'package:prometheus_client/runtime_metrics.dart' as runtime_metrics;

main() async {
  // Register runtime metrics with the default metrics registry
  runtime_metrics.register();

  // Create a Histogram metrics without labels. Always register your metric,
  // either at the default registry or a custom one.
  final durationHistogram = Histogram(
    name: 'http_request_duration_seconds',
    help: 'The duration of http requests in seconds.',
  )
    ..register();

  // Create a metric of type counter, with a label for the requested path:
  final metricRequestsCounter = Counter(
    name: 'metric_requests_total',
    help: 'The total amount of requests of the metrics.',
    labelNames: ['path'],
  )
    ..register();

  // Create a http server
  final server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    8080,
  );
  print('Listening on localhost:${server.port}');

  await for (HttpRequest request in server) {
    // Measure the request duration
    await durationHistogram.observeDuration(Future(() async {
      // Count calls to the metric endpoint by path.
      metricRequestsCounter.labels([request.uri.path]).inc();

      // Output metrics in the text representation
      request.response.headers.add('content-type', format.contentType);
      final metrics =
      await CollectorRegistry.defaultRegistry.collectMetricFamilySamples();
      format.write004(request.response, metrics);
      await request.response.close();
    }));
  }
}
```

Start the example application and access the exposed metrics at `http://localhost:8080/`. For a full usage example, take
a look at [`example/prometheus_client_example.dart`][example].

### Counter

**TODO:**

**TODO: Document collect function**

### Gauge

**TODO:**

### Histogram

**TODO:**

### Summary

**TODO:**

### Runtime Metrics

**TODO: Link to docs, only a limited amount. What is possible with the dart boardmittel.**

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/tentaclelabs/prometheus_client/issues

[writing_clientlibs]: https://prometheus.io/docs/instrumenting/writing_clientlibs/

[prometheus]: https://prometheus.io/

[text_format]: https://prometheus.io/docs/instrumenting/exposition_formats/#text-based-format

[shelf]: https://pub.dev/packages/shelf

[example]: https://github.com/tentaclelabs/prometheus_client/blob/main/prometheus_client/example/prometheus_client_example.dart

[changelog]: https://github.com/tentaclelabs/prometheus_client/blob/main/prometheus_client/CHANGELOG.md

[prometheus_client_shelf]: https://pub.dev/packages/prometheus_client_shelf

[prometheus_client]: https://pub.dev/packages/prometheus_client
