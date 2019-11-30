prometheus_client_shelf
===

This package exposes [Prometheus][prometheus] metrics for [shelf][shelf] using the package [prometheus_client][prometheus_client]. 
To expose them in your server application the package comes with a shelf handler. 
In addition, it comes with some plug-in ready metrics for the shelf.

You can find the latest updates in the [changelog][changelog].

## Usage

A simple usage example:

```dart
import 'package:prometheus_client/prometheus_client.dart';
import 'package:prometheus_client/runtime_metrics.dart' as runtime_metrics;
import 'package:prometheus_client_shelf/shelf_metrics.dart' as shelf_metrics;
import 'package:prometheus_client_shelf/shelf_handler.dart';
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
      // Register a middleware to track request times
      .addMiddleware(shelf_metrics.register())
      .addHandler(app.handler);
  var server = await io.serve(handler, 'localhost', 8080);

  print('Serving at http://${server.address.host}:${server.port}');
}
```

Start the example application and access the exposed metrics at `http://localhost:8080/metrics`.
For a full usage example, take a look at [`example/prometheus_client_shelf_example.dart`][example].

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[prometheus_client]: https://pub.dev/packages/prometheus_client
[tracker]: https://github.com/Fox32/prometheus_client/issues
[prometheus]: https://prometheus.io/
[shelf]: https://pub.dev/packages/shelf
[example]: https://github.com/Fox32/prometheus_client/blob/master/prometheus_client_shelf/example/prometheus_client_shelf_example.dart
[changelog]: https://github.com/Fox32/prometheus_client/blob/master/prometheus_client_shelf/CHANGELOG.md
