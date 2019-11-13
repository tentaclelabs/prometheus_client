prometheus_client
===

This is a simple Dart implementation of the [Prometheus][prometheus] client library, [similar to to libraries for other languages][writing_clientlibs].
It supports the default metric types like gauges, counters, or histograms.
Metrics can be exported using the [text format][text_format].
To expose them in your server application the package comes with a [shelf][shelf] handler. 
In addition, it comes with some plug-in ready metrics for the Dart runtime and shelf.

You can find the latest updates in the [changelog][changelog].

## Usage

A simple usage example:

```dart
import 'package:prometheus_client/prometheus_client.dart';
import 'package:prometheus_client/runtime_metrics.dart' as runtime_metrics;
import 'package:prometheus_client/shelf_handler.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

main() async {
  // Register default runtime metrics
  runtime_metrics.register();
  
  // Create a metric of type counter. 
  // Always register your metric, either at the default registry or a custom one.
  final greetingCounter =
      Counter('greetings_total', 'The total amount of greetings')..register();
  final app = Router();

  app.get('/hello', (shelf.Request request) {
    // Every time the hello is called, increase the counter by one 
    greetingCounter.inc();
    return shelf.Response.ok('hello-world');
  });
  
  // Register a handler to expose the metrics in the Prometheus text format
  app.get('/metrics', prometheusHandler());

  var handler = const shelf.Pipeline()
      .addHandler(app.handler);
  var server = await io.serve(handler, 'localhost', 8080);

  print('Serving at http://${server.address.host}:${server.port}');
}
```

Start the example application and access the exposed metrics at `http://localhost:8080/metrics`.
For a full usage example, take a look at [`example/prometheus_client.example.dart`][example].

## Planned features

To achieve the requirements from the Prometheus [Writing Client Libraries][writing_clientlibs] documentation, some features still have to be implemented: 

* Support `Summary` metric type.
* Split out shelf support into own package to avoid dependencies on shelf.


## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/Fox32/prometheus_client/issues
[writing_clientlibs]: https://prometheus.io/docs/instrumenting/writing_clientlibs/
[prometheus]: https://prometheus.io/
[text_format]: https://prometheus.io/docs/instrumenting/exposition_formats/#text-based-format
[shelf]: https://pub.dev/packages/shelf
[example]: ./example/prometheus_client_example.dart
[changelog]: ./CHANGELOG.md
