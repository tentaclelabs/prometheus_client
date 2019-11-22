import 'package:prometheus_client/src/double_format.dart';
import 'package:test/test.dart';

void main() {
  group('Double Format', () {
    test('Should format Infinity', () {
      expect(formatDouble(double.infinity), equals('+Inf'));
      expect(formatDouble(double.negativeInfinity), equals('-Inf'));
    });

    test('Should format NaN', () {
      expect(formatDouble(double.nan), equals('NaN'));
    });

    test('Should format number', () {
      expect(formatDouble(1.0), equals('1.0'));
    });
  });
}
