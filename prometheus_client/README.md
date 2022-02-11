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
      final metrics = await CollectorRegistry.defaultRegistry.collectMetricFamilySamples();
      format.write004(request.response, metrics);
      await request.response.close();
    }));
  }
}
```

Start the example application and access the exposed metrics at `http://localhost:8080/`. For a full usage example, take
a look at [`example/prometheus_client_example.dart`][example].

### Metrics

The package provides different kinds of metrics:

#### Counter

[`Counter`][counter] is a monotonically increasing counter.
Counters can only be incremented, either by one or a custom amount:

```dart
final requestsCounter = Counter(
  name: 'metric_requests_total',
  help: 'The total amount of requests of the metrics.',
);

requestsCounter.inc();
requestsCounter.inc(64.0);
```

#### Gauge

A [`Gauge`][gauge] represents a value that can go up and down:

```dart
final gauge = Gauge(
  name: 'my_metric',
  help: 'Help!',
);

gauge.value = 1337.0;
gauge.inc(2.0);
gauge.dec(4.0);
```

#### Histogram

[`Histogram`][histogram] allows aggregatable distributions of events, such as request latencies.
The buckets of the histogram are customizable and support both linear and exponential buckets.

```dart
final histogram = Histogram(
    name: 'my_metric',
    help: 'Help!',
);

histogram.observe(20.0);
await histogram.observeDuration(() async {
  // Some code
});
histogram.observeDurationSync(() {
  // Some code
});
```

#### Summary

Similar to a Histogram, a [`Summary`][summary] samples observations (usually things like request durations and response sizes). While it also provides a total count of observations and a sum of all observed values, it calculates configurable quantiles over a sliding time window.

```dart
final summary = Summary(
  name: 'my_metric',
  help: 'Help!',
);

summary.observe(20.0);
await summary.observeDuration(() async {
  // Some code
});
summary.observeDurationSync(() {
  // Some code
});
```

#### Labels

Metrics can optionally have labels. You can pass label names during metrics creation.
Later on, you can access a child metric for your label values via the `labels()` function.

```dart
final requestsCounter = Counter(
  name: 'metric_requests_total',
  help: 'The total amount of requests of the metrics.',
  labelNames: ['path'],
);

requestsCounter.labels(['my/path/']).inc();
```

#### Collect

For metrics that should provide the current value during scraping, each metric type provides a `collectCallback` that is executed during scraping.
You can use the callback to update the metric while scraping.
The callback can either be sync, or return a `Future`:

```dart
final gauge = Gauge(
  name: 'my_metric',
  help: 'Help!',
  collectCallback: (gauge) {
    // Callback is executed every time the metric is collected.
    // Use the function parameter to access the gauge and update
    // its value.
    gauge.value = 1337;
  },
);
```

### Default Metrics

The [`RuntimeCollector`][runtime_collector] provides a basic set of built-in metrics. However, only a limited set of
the [recommended standard metrics][default_metrics] is implemented, as Dart doesn't expose them.

### Outputting Metrics

The package comes with [function for serializing][write004] the metrics into the Prometheus metrics [text format][text_format]:

```dart
final buffer = StringBuffer();
final metrics = await CollectorRegistry.defaultRegistry.collectMetricFamilySamples();
format.write004(buffer, metrics);
print(buffer.toString());
```

If you are using shelf, take a look at [prometheus_client_shelf][prometheus_client_shelf] for providing a metrics
endpoint.

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

[counter]: https://pub.dev/documentation/prometheus_client/latest/prometheus_client/Counter-class.html

[gauge]: https://pub.dev/documentation/prometheus_client/latest/prometheus_client/Gauge-class.html

[histogram]: https://pub.dev/documentation/prometheus_client/latest/prometheus_client/Histogram-class.html

[summary]: https://pub.dev/documentation/prometheus_client/latest/prometheus_client/Summary-class.html

[runtime_collector]: https://pub.dev/documentation/prometheus_client/latest/prometheus_client.runtime_metrics/RuntimeCollector-class.html

[default_metrics]: https://prometheus.io/docs/instrumenting/writing_clientlibs/#standard-and-runtime-collectors

[write004]: https://pub.dev/documentation/prometheus_client/latest/prometheus_client.format/write004.html
