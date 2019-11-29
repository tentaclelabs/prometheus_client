import 'package:prometheus_client/prometheus_client.dart';
import 'package:test/test.dart';

void main() {
  group('Helper', () {
    test('Should validate metric name', () {
      expect(Gauge('my_metric', 'Help!'), isNotNull);
      expect(() => Gauge('my metric', 'Help!'), throwsArgumentError);
      expect(() => Gauge('99metrics', 'Help!'), throwsArgumentError);
    });

    test('Should validate label names', () {
      expect(Gauge('my_metric', 'Help!', labelNames: ['some', 'labels']),
          isNotNull);
      expect(() => Gauge('my_metric', 'Help!', labelNames: ['__internal']),
          throwsArgumentError);
      expect(() => Gauge('my_metric', 'Help!', labelNames: ['not allowed']),
          throwsArgumentError);
    });
  });
}
