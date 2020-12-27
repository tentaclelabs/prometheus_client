import 'package:prometheus_client/prometheus_client.dart';
import 'package:test/test.dart';

void main() {
  group('Histogram', () {
    test('Should register histogram at registry', () {
      final collectorRegistry = CollectorRegistry();
      Histogram(name: 'my_metric', help: 'Help!').register(collectorRegistry);

      final metricFamilySamples =
          collectorRegistry.collectMetricFamilySamples().map((m) => m.name);

      expect(metricFamilySamples, contains('my_metric'));
    });

    test('Should fail if labels contain "le"', () {
      expect(
          () => Histogram(name: 'my_metric', help: 'Help!', labelNames: ['le']),
          throwsArgumentError);
    });

    test('Should initialize histogram with custom buckets', () {
      final buckets = [0.25, 0.5, 1.0];
      final histogram = Histogram(
        name: 'my_metric',
        help: 'Help!',
        buckets: buckets,
      );

      expect(histogram.buckets, equals([0.25, 0.5, 1.0, double.infinity]));
    });

    test(
        'Should initialize histogram with custom buckets that already contain +Inf',
        () {
      final buckets = [0.25, 0.5, 1.0, double.infinity];
      final histogram = Histogram(
        name: 'my_metric',
        help: 'Help!',
        buckets: buckets,
      );

      expect(histogram.buckets, equals(buckets));
    });

    test('Should fail if custom buckets have wrong order', () {
      final buckets = [0.25, 1.0, 0.5];
      expect(
          () => Histogram(name: 'my_metric', help: 'Help!', buckets: buckets),
          throwsArgumentError);
    });

    test('Should initialize histogram with linear buckets', () {
      final histogram = Histogram.linear(
        name: 'my_metric',
        help: 'Help!',
        start: 1.0,
        width: 1.0,
        count: 10,
      );

      expect(
          histogram.buckets,
          equals([
            1.0,
            2.0,
            3.0,
            4.0,
            5.0,
            6.0,
            7.0,
            8.0,
            9.0,
            10.0,
            double.infinity
          ]));
    });

    test('Should initialize histogram with exponential buckets', () {
      final histogram = Histogram.exponential(
        name: 'my_metric',
        help: 'Help!',
        start: 1.0,
        factor: 2.0,
        count: 10,
      );

      expect(
          histogram.buckets,
          equals([
            1.0,
            2.0,
            4.0,
            8.0,
            16.0,
            32.0,
            64.0,
            128.0,
            256.0,
            512.0,
            double.infinity
          ]));
    });

    test('Should initialize histogram with 0', () {
      final histogram = Histogram(name: 'my_metric', help: 'Help!');

      expect(histogram.sum, equals(0.0));
      expect(histogram.count, equals(0.0));
      expect(
          histogram.bucketValues,
          equals([
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0
          ]));
    });

    test('Should observe values and update histogram', () {
      final histogram = Histogram(
        name: 'my_metric',
        help: 'Help!',
        buckets: [0.25, 0.5, 1.0],
      );

      histogram.observe(0.75);
      histogram.observe(0.25);
      histogram.observe(10.0);

      expect(histogram.sum, equals(11.0));
      expect(histogram.count, equals(3.0));
      expect(histogram.bucketValues, equals([1.0, 1.0, 2.0, 3.0]));
    });

    test('Should observe duration of callback', () {
      final histogram = Histogram(
        name: 'my_metric',
        help: 'Help!',
        buckets: [0.25, 0.5, 1.0],
      );

      histogram.observeDurationSync(() => {});

      expect(histogram.sum, greaterThan(0.0));
      expect(histogram.count, equals(1.0));
      expect(histogram.bucketValues, equals([1.0, 1.0, 1.0, 1.0]));
    });

    test('Should observe duration of future', () async {
      final histogram = Histogram(
        name: 'my_metric',
        help: 'Help!',
        buckets: [0.25, 0.5, 1.0],
      );

      await histogram
          .observeDuration(Future.delayed(Duration(milliseconds: 350)));

      expect(histogram.sum, greaterThan(0.3));
      expect(histogram.count, equals(1.0));
      expect(histogram.bucketValues, equals([0.0, 1.0, 1.0, 1.0]));
    }, retry: 3);

    test('Should not allow to set label values if no labels were specified',
        () {
      final histogram = Histogram(name: 'my_metric', help: 'Help!');

      expect(() => histogram.labels(['not_allowed']), throwsArgumentError);
    });

    test('Should collect samples for metric without labels', () {
      final histogram = Histogram(
        name: 'my_metric',
        help: 'Help!',
        buckets: [0.25, 0.5, 1.0],
      );
      final samples = histogram.collect().toList().expand((m) => m.samples);
      final sampleSum = samples.firstWhere((s) => s.name == 'my_metric_sum');
      final sampleCount =
          samples.firstWhere((s) => s.name == 'my_metric_count');
      final sampleBuckets = samples.where((s) => s.name == 'my_metric_bucket');

      expect(sampleSum.labelNames, isEmpty);
      expect(sampleSum.labelValues, isEmpty);
      expect(sampleSum.value, equals(0.0));

      expect(sampleCount.labelNames, isEmpty);
      expect(sampleCount.labelValues, isEmpty);
      expect(sampleCount.value, equals(0.0));

      expect(sampleBuckets, hasLength(4));
    });

    test('Should get child for specified labels', () {
      final histogram = Histogram(
        name: 'my_metric',
        help: 'Help!',
        labelNames: ['name'],
        buckets: [0.25, 0.5, 1.0],
      );
      final child = histogram.labels(['mine']);

      expect(child, isNotNull);
      expect(child.sum, equals(0.0));
      expect(child.count, equals(0.0));
      expect(child.bucketValues, equals([0.0, 0.0, 0.0, 0.0]));
    });

    test('Should fail if wrong amount of labels specified', () {
      final histogram = Histogram(
        name: 'my_metric',
        help: 'Help!',
        labelNames: ['name', 'state'],
      );

      expect(() => histogram.labels(['mine']), throwsArgumentError);
    });

    test('Should fail if labels specified but used without labels', () {
      final histogram = Histogram(
        name: 'my_metric',
        help: 'Help!',
        labelNames: ['name'],
      );

      expect(() => histogram.observe(1.0), throwsStateError);
    });

    test('Should collect samples for metric with labels', () {
      final histogram = Histogram(
        name: 'my_metric',
        help: 'Help!',
        labelNames: ['name'],
        buckets: [0.25, 0.5, 1.0],
      );
      histogram.labels(['mine']);
      final samples = histogram.collect().toList().expand((m) => m.samples);
      final sampleSum = samples.firstWhere((s) => s.name == 'my_metric_sum');
      final sampleCount =
          samples.firstWhere((s) => s.name == 'my_metric_count');
      final sampleBuckets = samples.where((s) => s.name == 'my_metric_bucket');

      expect(sampleSum.labelNames, equals(['name']));
      expect(sampleSum.labelValues, equals(['mine']));
      expect(sampleSum.value, equals(0.0));

      expect(sampleCount.labelNames, equals(['name']));
      expect(sampleCount.labelValues, equals(['mine']));
      expect(sampleCount.value, equals(0.0));

      expect(sampleBuckets, hasLength(4));
    });

    test('Should remove a child', () {
      final histogram = Histogram(
        name: 'my_metric',
        help: 'Help!',
        labelNames: ['name'],
      );
      histogram.labels(['yours']);
      histogram.labels(['mine']);
      histogram.remove(['mine']);
      final labelValues = histogram
          .collect()
          .toList()
          .expand((m) => m.samples)
          .map((s) => s.labelValues)
          .expand((l) => l);

      expect(labelValues, containsAll(['yours']));
    });

    test('Should clear all children', () {
      final histogram = Histogram(
        name: 'my_metric',
        help: 'Help!',
        labelNames: ['name'],
      );
      histogram.labels(['yours']);
      histogram.labels(['mine']);
      histogram.clear();
      final labelValues = histogram
          .collect()
          .toList()
          .expand((m) => m.samples)
          .map((s) => s.labelValues)
          .expand((l) => l);

      expect(labelValues, isEmpty);
    });
  });
}
