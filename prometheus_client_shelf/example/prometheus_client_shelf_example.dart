import 'dart:math';

import 'package:prometheus_client/prometheus_client.dart';
import 'package:prometheus_client/runtime_metrics.dart' as runtime_metrics;
import 'package:prometheus_client_shelf/shelf_metrics.dart' as shelf_metrics;
import 'package:prometheus_client_shelf/shelf_handler.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

void main() async {
  runtime_metrics.register();

  // Create a labeled gauge metric that stores the last time an endpoint was
  // accessed. Always register your metric, either at the default registry or a
  // custom one.
  final timeGauge = Gauge(
      'last_accessed_time', 'The last time the hello endpoint was accessed',
      labelNames: ['endpoint'])
    ..register();
  // Create a gauge metric without labels to store the last rolled value
  final rollGauge = Gauge('roll_value', 'The last roll value')..register();
  // Create a metric of type counter
  final greetingCounter =
      Counter('greetings_total', 'The total amount of greetings')..register();

  final app = Router();

  app.get('/hello', (shelf.Request request) {
    // Set the current time to the time metric for the label 'hello'
    timeGauge..labels(['hello']).setToCurrentTime();
    // Every time the hello is called, increase the counter by one
    greetingCounter.inc();
    return shelf.Response.ok('hello-world');
  });

  app.get('/roll', (shelf.Request request) {
    timeGauge..labels(['roll']).setToCurrentTime();
    final value = Random().nextDouble();
    // Store the rolled value without labels
    rollGauge.value = value;
    return shelf.Response.ok('rolled $value');
  });

  // Register a handler to expose the metrics in the Prometheus text format
  app.get('/metrics', prometheusHandler());

  app.all('/<ignored|.*>', (shelf.Request request) {
    return shelf.Response.notFound('Not Found');
  });

  var handler = const shelf.Pipeline()
      // Register a middleware to track request times
      .addMiddleware(shelf_metrics.register())
      .addMiddleware(shelf.logRequests())
      .addHandler(app.handler);
  var server = await io.serve(handler, 'localhost', 8080);

  print('Serving at http://${server.address.host}:${server.port}');
}
