import 'package:prometheus_client/prometheus_client.dart';
import 'package:prometheus_client/format.dart';
import 'package:test/test.dart';

void main() {
  group('Format v0.0.4', () {
    test('Should output metric help', () {
      final output = writeToString([
        MetricFamilySamples(
            'my_metric', MetricType.gauge, 'This is a help text.', [])
      ]);

      expect(output, contains('# HELP my_metric This is a help text.\n'));
    });

    test('Should escape metric help', () {
      final output = writeToString([
        MetricFamilySamples('my_metric', MetricType.gauge,
            'This is a help text\nwith multiple lines.', [])
      ]);

      expect(
          output,
          contains(
              '# HELP my_metric This is a help text\\nwith multiple lines.\n'));
    });

    test('Should output metric type', () {
      final output = writeToString([
        MetricFamilySamples(
            'my_metric', MetricType.gauge, 'This is a help text.', [])
      ]);

      expect(output, contains('# TYPE my_metric gauge\n'));
    });

    test('Should output metric sample without labels', () {
      final output = writeToString([
        MetricFamilySamples('my_metric', MetricType.gauge,
            'This is a help text.', [Sample('my_metric', [], [], 1.0)])
      ]);

      expect(output, contains('my_metric 1.0\n'));
    });

    test('Should output metric sample with one label', () {
      final output = writeToString([
        MetricFamilySamples(
            'my_metric', MetricType.gauge, 'This is a help text.', [
          Sample('my_metric', ['label'], ['value'], 1.0)
        ])
      ]);

      expect(output, contains('my_metric{label="value",} 1.0\n'));
    });

    test('Should output metric sample with multiple labels', () {
      final output = writeToString([
        MetricFamilySamples(
            'my_metric', MetricType.gauge, 'This is a help text.', [
          Sample('my_metric', ['label1', 'label2'], ['value1', 'value2'], 1.0)
        ])
      ]);

      expect(output,
          contains('my_metric{label1="value1",label2="value2",} 1.0\n'));
    });

    test('Should escape metric sample label value', () {
      final output = writeToString([
        MetricFamilySamples(
            'my_metric', MetricType.gauge, 'This is a help text.', [
          Sample('my_metric', ['message'],
              ['This is a "test" \\ with multiple\nlines'], 1.0)
        ])
      ]);

      expect(
          output,
          contains(
              'my_metric{message="This is a \\"test\\" \\\\ with multiple\\nlines",} 1.0\n'));
    });

    test('Should output metric with multiple samples', () {
      final output = writeToString([
        MetricFamilySamples(
            'my_metric', MetricType.gauge, 'This is a help text.', [
          Sample('my_metric_sum', [], [], 5.0),
          Sample('my_metric_total', [], [], 2.0),
        ])
      ]);

      expect(output, contains('my_metric_sum 5.0\nmy_metric_total 2.0\n'));
    });

    test('Should handle special sample values', () {
      final output = writeToString([
        MetricFamilySamples(
            'my_metric', MetricType.gauge, 'This is a help text.', [
          Sample('my_metric_inf', [], [], double.infinity),
          Sample('my_metric_ninf', [], [], double.negativeInfinity),
          Sample('my_metric_nan', [], [], double.nan),
        ])
      ]);

      expect(
          output,
          contains(
              'my_metric_inf +Inf\nmy_metric_ninf -Inf\nmy_metric_nan NaN\n'));
    });

    test('Should output multiple metrics', () {
      final output = writeToString([
        MetricFamilySamples('my_metric1', MetricType.gauge,
            'This is a help text.', [Sample('my_metric', [], [], 1.0)]),
        MetricFamilySamples('my_metric2', MetricType.counter,
            'This is a help text.', [Sample('my_metric', [], [], 1.0)]),
      ]);

      expect(
          output,
          contains(
              '# HELP my_metric1 This is a help text.\n# TYPE my_metric1 gauge\nmy_metric 1.0\n'
              '# HELP my_metric2 This is a help text.\n# TYPE my_metric2 counter\nmy_metric 1.0\n'));
    });
  });
}

String writeToString(List<MetricFamilySamples> metricFamilySamples) {
  final stringBuffer = StringBuffer();
  write004(stringBuffer, metricFamilySamples);
  return stringBuffer.toString();
}
