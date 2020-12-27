import 'package:prometheus_client/prometheus_client.dart';
import 'package:prometheus_client_shelf/shelf_handler.dart' as shelf_handler;
import 'package:test/test.dart';

void main() {
  group('Shelf Handler', () {
    test('Should output metrics', () async {
      final collectorRegistry = CollectorRegistry();
      Gauge(name: 'my_metric', help: 'Help text')
        ..register(collectorRegistry)
        ..inc();

      final handler = shelf_handler.prometheusHandler(collectorRegistry);
      final response = await handler(null);

      expect(response.statusCode, equals(200));
      expect(
          response.headers,
          containsPair(
              'content-type', 'text/plain; version=0.0.4; charset=utf-8'));

      final body = await response.readAsString();
      expect(body, contains('my_metric'));
    });
  });
}
