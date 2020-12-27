import 'package:prometheus_client/prometheus_client.dart';
import 'package:test/test.dart';

void main() {
  group('Gauge', () {
    test('Should register gauge at registry', () {
      final collectorRegistry = CollectorRegistry();
      Gauge(name: 'my_metric', help: 'Help!').register(collectorRegistry);

      final metricFamilySamples =
          collectorRegistry.collectMetricFamilySamples().map((m) => m.name);

      expect(metricFamilySamples, contains('my_metric'));
    });

    test('Should initialize gauge with 0', () {
      final gauge = Gauge(name: 'my_metric', help: 'Help!');

      expect(gauge.value, equals(0.0));
    });

    test('Should increment by one if no amount is specified', () {
      final gauge = Gauge(name: 'my_metric', help: 'Help!');

      gauge.inc();

      expect(gauge.value, equals(1.0));
    });

    test('Should increment by amount', () {
      final gauge = Gauge(name: 'my_metric', help: 'Help!');

      gauge.inc(42.0);

      expect(gauge.value, equals(42.0));
    });

    test('Should decrement by one if no amount is specified', () {
      final gauge = Gauge(name: 'my_metric', help: 'Help!');

      gauge.dec();

      expect(gauge.value, equals(-1.0));
    });

    test('Should decrement by amount', () {
      final gauge = Gauge(name: 'my_metric', help: 'Help!');

      gauge.dec(42.0);

      expect(gauge.value, equals(-42.0));
    });

    test('Should set to value', () {
      final gauge = Gauge(name: 'my_metric', help: 'Help!');

      gauge.value = 42.0;

      expect(gauge.value, equals(42.0));
    });

    test('Should set to current time', () {
      final gauge = Gauge(name: 'my_metric', help: 'Help!');

      gauge.setToCurrentTime();

      expect(gauge.value,
          closeTo(DateTime.now().millisecondsSinceEpoch.toDouble(), 1000));
    });

    test('Should not allow to set label values if no labels were specified',
        () {
      final gauge = Gauge(name: 'my_metric', help: 'Help!');

      expect(() => gauge.labels(['not_allowed']), throwsArgumentError);
    });

    test('Should collect samples for metric without labels', () {
      final gauge = Gauge(name: 'my_metric', help: 'Help!');
      final sample = gauge.collect().toList().expand((m) => m.samples).first;

      expect(sample.name, equals('my_metric'));
      expect(sample.labelNames, isEmpty);
      expect(sample.labelValues, isEmpty);
      expect(sample.value, equals(0.0));
    });

    test('Should get child for specified labels', () {
      final gauge =
          Gauge(name: 'my_metric', help: 'Help!', labelNames: ['name']);
      final child = gauge.labels(['mine']);

      expect(child, isNotNull);
      expect(child.value, 0.0);
    });

    test('Should fail if wrong amount of labels specified', () {
      final gauge = Gauge(
          name: 'my_metric', help: 'Help!', labelNames: ['name', 'state']);

      expect(() => gauge.labels(['mine']), throwsArgumentError);
    });

    test('Should fail if labels specified but used without labels', () {
      final gauge =
          Gauge(name: 'my_metric', help: 'Help!', labelNames: ['name']);

      expect(() => gauge.inc(), throwsStateError);
    });

    test('Should collect samples for metric with labels', () {
      final gauge =
          Gauge(name: 'my_metric', help: 'Help!', labelNames: ['name']);
      gauge.labels(['mine']);
      final sample = gauge.collect().toList().expand((m) => m.samples).first;

      expect(sample.name, equals('my_metric'));
      expect(sample.labelNames, equals(['name']));
      expect(sample.labelValues, equals(['mine']));
      expect(sample.value, equals(0.0));
    });

    test('Should remove a child', () {
      final gauge =
          Gauge(name: 'my_metric', help: 'Help!', labelNames: ['name']);
      gauge.labels(['yours']);
      gauge.labels(['mine']);
      gauge.remove(['mine']);
      final labelValues = gauge
          .collect()
          .toList()
          .expand((m) => m.samples)
          .map((s) => s.labelValues)
          .expand((l) => l);

      expect(labelValues, containsAll(['yours']));
    });

    test('Should clear all children', () {
      final gauge =
          Gauge(name: 'my_metric', help: 'Help!', labelNames: ['name']);
      gauge.labels(['yours']);
      gauge.labels(['mine']);
      gauge.clear();
      final labelValues = gauge
          .collect()
          .toList()
          .expand((m) => m.samples)
          .map((s) => s.labelValues)
          .expand((l) => l);

      expect(labelValues, isEmpty);
    });
  });
}
