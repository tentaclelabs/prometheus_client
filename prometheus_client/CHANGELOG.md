## 0.5.0-nullsafety.0

- Migrate to null-safety.
- Change all metrics constructors to take `name` and `help` as required named parameters.

## 0.4.1

- `counter.inc()` should only allow to increment by values greater than zero.

## 0.4.0+4

- Moved to new org [tentaclelabs](https://github.com/tentaclelabs).

## 0.4.0+3

- Remove author from pubspec.

## 0.4.0+2

- Fix some analyzer issues, no functional changes.

## 0.4.0+1

- Align version constraint to `prometheus_client_shelf`.

## 0.4.0

- Move shelf support into own package [`prometheus_client_shelf`](https://pub.dev/packages/prometheus_client).

## 0.3.0+1

- Increase version constraint range on package `collection` to `^1.14.11` to be compatible with flutter.

## 0.3.0

- Implement `Summary` metric type.

## 0.2.0

- Support timestamp for samples.

## 0.1.0

- Initial version.
- Implements `Counter`, `Gauge` and `Histogram`.
- Includes a shelf handler to export metrics and a shelf middleware to measure performance.
