import 'package:prometheus_client/prometheus_client.dart';
import 'package:prometheus_client/runtime_metrics.dart' as runtime_metrics;
import 'package:test/test.dart';

void main() {
  group('Runtime Metrics', () {
    test('Should collect metric names', () {
      final runtimeCollector = runtime_metrics.RuntimeCollector();
      final metricNames = runtimeCollector.collectNames();

      expect(
        metricNames,
        equals([
          'dart_info',
          'process_resident_memory_bytes',
          'process_start_time_seconds',
        ]),
      );
    });

    test('Should output dart_info metric', () async {
      final collectorRegistry = CollectorRegistry();
      runtime_metrics.register(collectorRegistry);
      final metricFamilySamples =
          await collectorRegistry.collectMetricFamilySamples();
      final dartInfoMetric =
          metricFamilySamples.where((m) => m.name == 'dart_info').first;

      expect(dartInfoMetric.name, equals('dart_info'));
      expect(dartInfoMetric.help, isNotEmpty);
      expect(dartInfoMetric.type, equals(MetricType.gauge));
      expect(dartInfoMetric.samples, hasLength(1));

      final dartInfoSample = dartInfoMetric.samples.first;

      expect(dartInfoSample.name, equals('dart_info'));
      expect(dartInfoSample.labelNames, equals(['version']));
      expect(dartInfoSample.labelValues, isNotEmpty);
      expect(dartInfoSample.value, equals(1.0));
    });

    test('Should output process_resident_memory_bytes metric', () async {
      final collectorRegistry = CollectorRegistry();
      runtime_metrics.register(collectorRegistry);
      final metricFamilySamples =
          await collectorRegistry.collectMetricFamilySamples();
      final dartInfoMetric = metricFamilySamples
          .where((m) => m.name == 'process_resident_memory_bytes')
          .first;

      expect(dartInfoMetric.name, equals('process_resident_memory_bytes'));
      expect(dartInfoMetric.help, isNotEmpty);
      expect(dartInfoMetric.type, equals(MetricType.gauge));
      expect(dartInfoMetric.samples, hasLength(1));

      final dartInfoSample = dartInfoMetric.samples.first;

      expect(dartInfoSample.name, equals('process_resident_memory_bytes'));
      expect(dartInfoSample.labelNames, isEmpty);
      expect(dartInfoSample.labelValues, isEmpty);
      expect(dartInfoSample.value, greaterThan(0));
    });

    test('Should output process_start_time_seconds metric', () async {
      final collectorRegistry = CollectorRegistry();
      runtime_metrics.register(collectorRegistry);
      final metricFamilySamples =
          await collectorRegistry.collectMetricFamilySamples();
      final dartInfoMetric = metricFamilySamples
          .where((m) => m.name == 'process_start_time_seconds')
          .first;

      expect(dartInfoMetric.name, equals('process_start_time_seconds'));
      expect(dartInfoMetric.help, isNotEmpty);
      expect(dartInfoMetric.type, equals(MetricType.gauge));
      expect(dartInfoMetric.samples, hasLength(1));

      final dartInfoSample = dartInfoMetric.samples.first;

      expect(dartInfoSample.name, equals('process_start_time_seconds'));
      expect(dartInfoSample.labelNames, isEmpty);
      expect(dartInfoSample.labelValues, isEmpty);
      expect(dartInfoSample.value, greaterThan(0));
    });
  });
}
