import 'package:prometheus_client/prometheus_client.dart';
import 'package:test/test.dart';

void main() {
  group('Counter', () {
    test('Should register counter at registry', () async {
      final collectorRegistry = CollectorRegistry();
      Counter(name: 'my_metric', help: 'Help!').register(collectorRegistry);

      final metricFamilySamples =
          await collectorRegistry.collectMetricFamilySamples();

      expect(metricFamilySamples.map((m) => m.name), contains('my_metric'));
    });

    test('Should collect metric names', () {
      final counter = Counter(name: 'my_metric', help: 'Help!');

      expect(counter.collectNames(), equals(['my_metric']));
    });

    test('Should initialize counter with 0', () {
      final counter = Counter(name: 'my_metric', help: 'Help!');

      expect(counter.value, equals(0.0));
    });

    test('Should increment by one if no amount is specified', () {
      final counter = Counter(name: 'my_metric', help: 'Help!');

      counter.inc();

      expect(counter.value, equals(1.0));
    });

    test('Should increment by amount', () {
      final counter = Counter(name: 'my_metric', help: 'Help!');

      counter.inc(42.0);

      expect(counter.value, equals(42.0));
    });

    test('Should not increment by negative amount', () {
      final counter = Counter(name: 'my_metric', help: 'Help!');

      expect(() => counter.inc(-42.0), throwsArgumentError);
    });

    test('Should not increment by zero', () {
      final counter = Counter(name: 'my_metric', help: 'Help!');

      expect(() => counter.inc(0.0), throwsArgumentError);
    });

    test('Should not allow to set label values if no labels were specified',
        () {
      final counter = Counter(name: 'my_metric', help: 'Help!');

      expect(() => counter.labels(['not_allowed']), throwsArgumentError);
    });

    test('Should collect samples for metric without labels', () async {
      final counter = Counter(name: 'my_metric', help: 'Help!');
      final metricFamilySamples = await counter.collect();
      final sample =
          metricFamilySamples.toList().expand((m) => m.samples).first;

      expect(sample.name, equals('my_metric'));
      expect(sample.labelNames, isEmpty);
      expect(sample.labelValues, isEmpty);
      expect(sample.value, equals(0.0));
    });

    test('Should get child for specified labels', () {
      final counter =
          Counter(name: 'my_metric', help: 'Help!', labelNames: ['name']);
      final child = counter.labels(['mine']);

      expect(child, isNotNull);
      expect(child.value, 0.0);
    });

    test('Should fail if wrong amount of labels specified', () {
      final counter = Counter(
          name: 'my_metric', help: 'Help!', labelNames: ['name', 'state']);

      expect(() => counter.labels(['mine']), throwsArgumentError);
    });

    test('Should fail if labels specified but used without labels', () {
      final counter =
          Counter(name: 'my_metric', help: 'Help!', labelNames: ['name']);

      expect(() => counter.inc(), throwsStateError);
    });

    test('Should collect samples for metric with labels', () async {
      final counter =
          Counter(name: 'my_metric', help: 'Help!', labelNames: ['name']);
      counter.labels(['mine']);
      final metricFamilySamples = await counter.collect();
      final sample =
          metricFamilySamples.toList().expand((m) => m.samples).first;

      expect(sample.name, equals('my_metric'));
      expect(sample.labelNames, equals(['name']));
      expect(sample.labelValues, equals(['mine']));
      expect(sample.value, equals(0.0));
    });

    test('Should remove a child', () async {
      final counter =
          Counter(name: 'my_metric', help: 'Help!', labelNames: ['name']);
      counter.labels(['yours']);
      counter.labels(['mine']);
      counter.remove(['mine']);
      final metricFamilySamples = await counter.collect();
      final labelValues = metricFamilySamples
          .toList()
          .expand((m) => m.samples)
          .map((s) => s.labelValues)
          .expand((l) => l);

      expect(labelValues, containsAll(['yours']));
    });

    test('Should clear all children', () async {
      final counter =
          Counter(name: 'my_metric', help: 'Help!', labelNames: ['name']);
      counter.labels(['yours']);
      counter.labels(['mine']);
      counter.clear();
      final metricFamilySamples = await counter.collect();
      final labelValues = metricFamilySamples
          .toList()
          .expand((m) => m.samples)
          .map((s) => s.labelValues)
          .expand((l) => l);

      expect(labelValues, isEmpty);
    });

    test('Should call collect callback on collect', () async {
      final counter = Counter(
        name: 'my_metric',
        help: 'Help!',
        collectCallback: (counter) {
          counter.inc(1337);
        },
      );
      final metricFamilySamples = await counter.collect();
      final sample =
          metricFamilySamples.toList().expand((m) => m.samples).first;

      expect(sample.name, equals('my_metric'));
      expect(sample.value, equals(1337.0));
    });
  });
}
