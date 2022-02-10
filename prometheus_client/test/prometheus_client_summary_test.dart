import 'package:prometheus_client/prometheus_client.dart';
import 'package:test/test.dart';

void main() {
  group('Summary', () {
    test('Should register summary at registry', () async {
      final collectorRegistry = CollectorRegistry();
      Summary(name: 'my_metric', help: 'Help!').register(collectorRegistry);

      final metricFamilySamples =
          await collectorRegistry.collectMetricFamilySamples();

      expect(metricFamilySamples.map((m) => m.name), contains('my_metric'));
    });

    test('Should collect metric names', () {
      final summary = Summary(name: 'my_metric', help: 'Help!');

      expect(
        summary.collectNames(),
        equals(['my_metric_count', 'my_metric_sum', 'my_metric']),
      );
    });

    test('Should fail if labels contain "quantile"', () {
      expect(
        () =>
            Summary(name: 'my_metric', help: 'Help!', labelNames: ['quantile']),
        throwsArgumentError,
      );
    });

    test('Should initialize summary with quantiles, maxAge and ageBuckets', () {
      final summary = Summary(
        name: 'my_metric',
        help: 'Help!',
        quantiles: [Quantile(0.9, 0.1)],
        maxAge: Duration(seconds: 1),
        ageBuckets: 10,
      );

      expect(summary.quantiles.first.quantile, equals(0.9));
      expect(summary.quantiles.first.error, equals(0.1));
      expect(summary.values.keys, equals([0.9]));
      expect(summary.maxAge.inSeconds, equals(1));
      expect(summary.ageBuckets, equals(10));
    });

    test('Should initialize summary with 0', () {
      final summary = Summary(
        name: 'my_metric',
        help: 'Help!',
        quantiles: [Quantile(0.9, 0.1)],
      );

      expect(summary.sum, equals(0.0));
      expect(summary.count, equals(0.0));
      expect(summary.values[0.9], isNaN);
    });

    test('Should observe values and update summary', () {
      final summary = Summary(
        name: 'my_metric',
        help: 'Help!',
        quantiles: [Quantile(0.5, 0.1)],
      );

      summary.observe(1);
      summary.observe(2);
      summary.observe(3);
      summary.observe(4);

      expect(summary.sum, equals(10.0));
      expect(summary.count, equals(4.0));
      expect(summary.values[0.5], 2);
    });

    test('Should observe duration of callback', () {
      final summary = Summary(
        name: 'my_metric',
        help: 'Help!',
        quantiles: [Quantile(0.9, 0.1)],
      );

      summary.observeDurationSync(() => {});

      expect(summary.sum, greaterThan(0.0));
      expect(summary.count, equals(1.0));
      expect(summary.values[0.9], equals(summary.sum));
    });

    test('Should observe duration of future', () async {
      final summary = Summary(
        name: 'my_metric',
        help: 'Help!',
        quantiles: [Quantile(0.9, 0.1)],
      );

      await summary
          .observeDuration(Future.delayed(Duration(milliseconds: 350)));

      expect(summary.sum, greaterThan(0.0));
      expect(summary.count, equals(1.0));
      expect(summary.values[0.9], equals(summary.sum));
    }, retry: 3);

    test('Should not allow to set label values if no labels were specified',
        () {
      final summary = Summary(name: 'my_metric', help: 'Help!');

      expect(() => summary.labels(['not_allowed']), throwsArgumentError);
    });

    test('Should collect samples for metric without labels', () async {
      final summary = Summary(
        name: 'my_metric',
        help: 'Help!',
        quantiles: [Quantile(0.9, 0.1), Quantile(0.99, 0.01)],
      );
      final metricFamilySamples = await summary.collect();
      final samples = metricFamilySamples.toList().expand((m) => m.samples);
      final sampleSum = samples.firstWhere((s) => s.name == 'my_metric_sum');
      final sampleCount =
          samples.firstWhere((s) => s.name == 'my_metric_count');
      final sampleQuantiles = samples.where((s) => s.name == 'my_metric');

      expect(sampleSum.labelNames, isEmpty);
      expect(sampleSum.labelValues, isEmpty);
      expect(sampleSum.value, equals(0.0));

      expect(sampleCount.labelNames, isEmpty);
      expect(sampleCount.labelValues, isEmpty);
      expect(sampleCount.value, equals(0.0));

      expect(sampleQuantiles, hasLength(2));
    });

    test('Should get child for specified labels', () {
      final summary = Summary(
        name: 'my_metric',
        help: 'Help!',
        labelNames: ['name'],
      );
      final child = summary.labels(['mine']);

      expect(child, isNotNull);
      expect(child.sum, equals(0.0));
      expect(child.count, equals(0.0));
      expect(child.values, isEmpty);
    });

    test('Should fail if wrong amount of labels specified', () {
      final summary = Summary(
        name: 'my_metric',
        help: 'Help!',
        labelNames: ['name', 'state'],
      );

      expect(() => summary.labels(['mine']), throwsArgumentError);
    });

    test('Should fail if labels specified but used without labels', () {
      final summary = Summary(
        name: 'my_metric',
        help: 'Help!',
        labelNames: ['name'],
      );

      expect(() => summary.observe(1.0), throwsStateError);
    });

    test('Should collect samples for metric with labels', () async {
      final summary = Summary(
        name: 'my_metric',
        help: 'Help!',
        labelNames: ['name'],
        quantiles: [Quantile(0.9, 0.1), Quantile(0.99, 0.01)],
      );
      summary.labels(['mine']);
      final metricFamilySamples = await summary.collect();
      final samples = metricFamilySamples.toList().expand((m) => m.samples);
      final sampleSum = samples.firstWhere((s) => s.name == 'my_metric_sum');
      final sampleCount =
          samples.firstWhere((s) => s.name == 'my_metric_count');
      final sampleQuantiles = samples.where((s) => s.name == 'my_metric');

      expect(sampleSum.labelNames, equals(['name']));
      expect(sampleSum.labelValues, equals(['mine']));
      expect(sampleSum.value, equals(0.0));

      expect(sampleCount.labelNames, equals(['name']));
      expect(sampleCount.labelValues, equals(['mine']));
      expect(sampleCount.value, equals(0.0));

      expect(sampleQuantiles, hasLength(2));
    });

    test('Should remove a child', () async {
      final summary = Summary(
        name: 'my_metric',
        help: 'Help!',
        labelNames: ['name'],
      );
      summary.labels(['yours']);
      summary.labels(['mine']);
      summary.remove(['mine']);
      final metricFamilySamples = await summary.collect();
      final labelValues = metricFamilySamples
          .toList()
          .expand((m) => m.samples)
          .map((s) => s.labelValues)
          .expand((l) => l);

      expect(labelValues, containsAll(['yours']));
    });

    test('Should clear all children', () async {
      final summary = Summary(
        name: 'my_metric',
        help: 'Help!',
        labelNames: ['name'],
      );
      summary.labels(['yours']);
      summary.labels(['mine']);
      summary.clear();
      final metricFamilySamples = await summary.collect();
      final labelValues = metricFamilySamples
          .toList()
          .expand((m) => m.samples)
          .map((s) => s.labelValues)
          .expand((l) => l);

      expect(labelValues, isEmpty);
    });

    test('Should call collect callback on collect', () async {
      final summary = Summary(
        name: 'my_metric',
        help: 'Help!',
        collectCallback: (summary) {
          summary.observe(1337);
        },
      );
      final metricFamilySamples = await summary.collect();
      final sample = metricFamilySamples
          .toList()
          .expand((m) => m.samples)
          .where((s) => s.name == 'my_metric_sum')
          .first;

      expect(sample.name, equals('my_metric_sum'));
      expect(sample.value, equals(1337.0));
    });
  });
}
