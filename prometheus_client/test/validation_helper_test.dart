import 'package:prometheus_client/src/validation_helper.dart';
import 'package:test/test.dart';

void main() {
  group('Helper', () {
    test('Should validate metric name', () {
      expect(() => checkMetricName('my_metric'), isNot(throwsArgumentError));
      expect(() => checkMetricName('my metric'), throwsArgumentError);
      expect(() => checkMetricName('99metrics'), throwsArgumentError);
    });

    test('Should validate label names', () {
      expect(() => checkMetricLabelName('some'), isNot(throwsArgumentError));
      expect(() => checkMetricLabelName('__internal'), throwsArgumentError);
      expect(() => checkMetricLabelName('not allowed'), throwsArgumentError);
    });
  });
}
