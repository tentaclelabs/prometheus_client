import 'package:prometheus_client/prometheus_client.dart';
import 'package:test/test.dart';

void main() {
  group('Counter', () {
    test('Should register counter at registry', () {
      final collectorRegistry = CollectorRegistry();
      Counter('my_metric', 'Help!').register(collectorRegistry);

      final metricFamilySamples =
          collectorRegistry.collectMetricFamilySamples().map((m) => m.name);

      expect(metricFamilySamples, contains('my_metric'));
    });

    test('Should initialize counter with 0', () {
      final counter = Counter('my_metric', 'Help!');

      expect(counter.value, equals(0.0));
    });

    test('Should increment by one if no amount is specified', () {
      final counter = Counter('my_metric', 'Help!');

      counter.inc();

      expect(counter.value, equals(1.0));
    });

    test('Should increment by amount', () {
      final counter = Counter('my_metric', 'Help!');

      counter.inc(42.0);

      expect(counter.value, equals(42.0));
    });

    test('Should not increment by negative amount', () {
      final counter = Counter('my_metric', 'Help!');

      expect(() => counter.inc(-42.0), throwsArgumentError);
    });

    test('Should not allow to set label values if no labels were specified',
        () {
      final counter = Counter('my_metric', 'Help!');

      expect(() => counter.labels(['not_allowed']), throwsArgumentError);
    });

    test('Should collect samples for metric without labels', () {
      final counter = Counter('my_metric', 'Help!');
      final sample = counter.collect().toList().expand((m) => m.samples).first;

      expect(sample.name, equals('my_metric'));
      expect(sample.labelNames, isEmpty);
      expect(sample.labelValues, isEmpty);
      expect(sample.value, equals(0.0));
    });

    test('Should get child for specified labels', () {
      final counter = Counter('my_metric', 'Help!', labelNames: ['name']);
      final child = counter.labels(['mine']);

      expect(child, isNotNull);
      expect(child.value, 0.0);
    });

    test('Should fail if wrong amount of labels specified', () {
      final counter =
          Counter('my_metric', 'Help!', labelNames: ['name', 'state']);

      expect(() => counter.labels(['mine']), throwsArgumentError);
    });

    test('Should fail if labels specified but used without labels', () {
      final counter = Counter('my_metric', 'Help!', labelNames: ['name']);

      expect(() => counter.inc(), throwsStateError);
    });

    test('Should collect samples for metric with labels', () {
      final counter = Counter('my_metric', 'Help!', labelNames: ['name']);
      counter.labels(['mine']);
      final sample = counter.collect().toList().expand((m) => m.samples).first;

      expect(sample.name, equals('my_metric'));
      expect(sample.labelNames, equals(['name']));
      expect(sample.labelValues, equals(['mine']));
      expect(sample.value, equals(0.0));
    });

    test('Should remove a child', () {
      final counter = Counter('my_metric', 'Help!', labelNames: ['name']);
      counter.labels(['yours']);
      counter.labels(['mine']);
      counter.remove(['mine']);
      final labelValues = counter
          .collect()
          .toList()
          .expand((m) => m.samples)
          .map((s) => s.labelValues)
          .expand((l) => l);

      expect(labelValues, containsAll(['yours']));
    });

    test('Should clear all children', () {
      final counter = Counter('my_metric', 'Help!', labelNames: ['name']);
      counter.labels(['yours']);
      counter.labels(['mine']);
      counter.clear();
      final labelValues = counter
          .collect()
          .toList()
          .expand((m) => m.samples)
          .map((s) => s.labelValues)
          .expand((l) => l);

      expect(labelValues, isEmpty);
    });
  });
}
