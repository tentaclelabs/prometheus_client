import 'package:prometheus_client/src/quantiles.dart';

import 'package:test/test.dart';

void main() {
  group('Quantiles', () {
    test('Should create quantile and initialize helper values', () {
      final q = Quantile(0.9, 0.01);

      expect(q.quantile, equals(0.9));
      expect(q.error, equals(0.01));
      expect(q.u, closeTo(0.2, 0.001));
      expect(q.v, closeTo(0.02222, 0.001));
    });

    test('Should throw argument error if quantile has wrong input', () {
      expect(() => Quantile(-0.1, 0.01), throwsArgumentError);
      expect(() => Quantile(1.9, 0.01), throwsArgumentError);
      expect(() => Quantile(0.9, -1.0), throwsArgumentError);
      expect(() => Quantile(0.9, 1.01), throwsArgumentError);
    });

    test('Should calculate correct quantiles for known samples', () {
      final quantiles = CkmsQuantiles(
          [Quantile(0.5, 0.05), Quantile(0.9, 0.01), Quantile(0.99, 0.001)]);

      final nSamples = 1000000;
      for (var i = 1; i <= nSamples; i++) {
        quantiles.insert(i.toDouble());
      }

      expect(quantiles.retrieve(0.5), closeTo(0.5 * nSamples, 0.05 * nSamples));
      expect(quantiles.retrieve(0.9), closeTo(0.9 * nSamples, 0.01 * nSamples));
      expect(
          quantiles.retrieve(0.99), closeTo(0.99 * nSamples, 0.001 * nSamples));
    });

    test('Should calculate correct quantiles in the moving time window',
        () async {
      final quantiles = TimeWindowQuantiles(
          [Quantile(0.99, 0.001)], const Duration(seconds: 1), 2);

      quantiles.insert(8.0);
      expect(quantiles.retrieve(0.99), equals(8.0));

      await Future.delayed(const Duration(milliseconds: 600));

      expect(quantiles.retrieve(0.99), equals(8.0));

      await Future.delayed(const Duration(milliseconds: 600));

      expect(quantiles.retrieve(0.99), isNaN);
    });
  });
}
