import 'package:prometheus_client/prometheus_client.dart';
import 'package:test/test.dart';

void main() {
  group('Collector', () {
    test('Should register collector', () {
      final collectorRegistry = CollectorRegistry();
      collectorRegistry.register(Gauge(name: 'my_metric', help: 'Help!'));

      final metricFamilySamples =
          collectorRegistry.collectMetricFamilySamples().map((m) => m.name);

      expect(metricFamilySamples, equals(['my_metric']));
    });

    test('Should register multiple collector', () {
      final collectorRegistry = CollectorRegistry();
      collectorRegistry.register(Gauge(name: 'my_metric', help: 'Help!'));
      collectorRegistry.register(Gauge(name: 'my_other_metric', help: 'Help!'));

      final metricFamilySamples =
          collectorRegistry.collectMetricFamilySamples().map((m) => m.name);

      expect(
          metricFamilySamples, containsAll(['my_metric', 'my_other_metric']));
    });

    test('Should not register collector with conflicting name', () {
      final collectorRegistry = CollectorRegistry();
      collectorRegistry.register(Gauge(name: 'my_metric', help: 'Help!'));

      expect(
          () => collectorRegistry
              .register(Histogram(name: 'my_metric', help: 'Help!')),
          throwsArgumentError);
    });

    test('Should unregister collector', () {
      final collectorRegistry = CollectorRegistry();
      final gauge = Gauge(name: 'my_metric', help: 'Help!');
      collectorRegistry.register(gauge);
      collectorRegistry.register(Gauge(name: 'my_other_metric', help: 'Help!'));

      collectorRegistry.unregister(gauge);

      final metricFamilySamples =
          collectorRegistry.collectMetricFamilySamples().map((m) => m.name);

      expect(metricFamilySamples, equals(['my_other_metric']));
    });

    test('Should re-register collector', () {
      final collectorRegistry = CollectorRegistry();
      final gauge = Gauge(name: 'my_metric', help: 'Help!');
      collectorRegistry.register(gauge);
      collectorRegistry.register(Gauge(name: 'my_other_metric', help: 'Help!'));

      collectorRegistry.unregister(gauge);
      collectorRegistry.register(gauge);

      final metricFamilySamples =
          collectorRegistry.collectMetricFamilySamples().map((m) => m.name);

      expect(
          metricFamilySamples, containsAll(['my_metric', 'my_other_metric']));
    });

    test('Should collect samples', () {
      final collectorRegistry = CollectorRegistry();
      collectorRegistry
          .register(Gauge(name: 'my_metric', help: 'Help!')..value = 42.0);

      final metricFamilySample =
          collectorRegistry.collectMetricFamilySamples().first;

      expect(metricFamilySample.name, equals('my_metric'));
      expect(
          metricFamilySample.samples.map((s) => s.value).first, equals(42.0));
    });
  });
}
