/// A library to track request times for shelf servers.
library shelf_metrics;

import 'package:shelf/shelf.dart' as shelf;
import 'package:prometheus_client/prometheus_client.dart';

/// Register default metrics for the shelf and returns a [shelf.Middleware] that
/// can be added to the [shelf.Pipeline]. If no [registry] is provided, the
/// [CollectorRegistry.defaultRegistry] is used.
shelf.Middleware register([CollectorRegistry registry]) {
  final histogram = Histogram('http_request_duration_seconds',
      'A histogram of the HTTP request durations.',
      labelNames: ['method', 'code']);

  registry ??= CollectorRegistry.defaultRegistry;
  registry.register(histogram);

  return (innerHandler) {
    return (request) {
      var watch = Stopwatch()..start();

      return Future.sync(() => innerHandler(request)).then((response) {
        if (response != null) {
          histogram.labels([request.method, '${response.statusCode}']).observe(
              watch.elapsedMicroseconds / Duration.microsecondsPerSecond);
        }

        return response;
      }, onError: (error, StackTrace stackTrace) {
        if (error is shelf.HijackException) {
          throw error;
        }

        histogram.labels([request.method, '000']).observe(
            watch.elapsedMicroseconds / Duration.microsecondsPerSecond);

        throw error;
      });
    };
  };
}
