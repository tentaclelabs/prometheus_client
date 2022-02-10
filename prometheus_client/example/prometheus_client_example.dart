import 'dart:io';

import 'package:prometheus_client/format.dart' as format;
import 'package:prometheus_client/prometheus_client.dart';
import 'package:prometheus_client/runtime_metrics.dart' as runtime_metrics;

Future main() async {
  // Register runtime metrics with the default metrics registry
  runtime_metrics.register();

  // Create a Histogram metrics without labels. Always register your metric,
  // either at the default registry or a custom one.
  final durationHistogram = Histogram(
    name: 'http_request_duration_seconds',
    help: 'The duration of http requests in seconds.',
  )..register();

  // Create a metric of type counter, with a label for the requested path:
  final metricRequestsCounter = Counter(
      name: 'metric_requests_total',
      help: 'The total amount of requests of the metrics.',
      labelNames: ['path'])
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
