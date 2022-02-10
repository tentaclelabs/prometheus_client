import 'package:prometheus_client/prometheus_client.dart';
import 'package:prometheus_client_shelf/shelf_metrics.dart' as shelf_metrics;
import 'package:shelf/shelf.dart' as shelf;
import 'package:test/test.dart';

void main() {
  group('Shelf Metrics', () {
    test('Should observe handler duration', () async {
      final collectorRegistry = CollectorRegistry();
      final middleware = shelf_metrics.register(collectorRegistry);
      final handler = middleware((e) => Future.delayed(
          Duration(milliseconds: 500), () => shelf.Response.ok('OK')));

      await handler(
          shelf.Request('GET', Uri.tryParse('http://example.com/test')!));

      final metricFamilySamples =
          await collectorRegistry.collectMetricFamilySamples();
      final metric = metricFamilySamples
          .firstWhere((s) => s.name == 'http_request_duration_seconds');

      expect(metric.name, equals('http_request_duration_seconds'));
      expect(metric.help, isNotEmpty);
      expect(metric.type, equals(MetricType.histogram));
      expect(metric.samples, isNotEmpty);

      final sample = metric.samples
          .firstWhere((s) => s.name == 'http_request_duration_seconds_count');

      expect(sample.value, equals(1));
    });
  });
}
