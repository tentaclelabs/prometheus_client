## 0.6.0

- Introduce a `collectCallback` into every metric type, which allows to update the metric before the sample values are
  collected. This is useful to perform more complex metric calculation only when the metrics are scraped.
- **Breaking Change**: Make `Collector.collect()` method on metrics async. Related code
  like `CollectorRegistry.collectMetricFamilySamples()`, is now async, too.
- Polish documentation towards a `1.0.0` release.

## 0.5.1

- Migrate from `pedantic` to `lints`

## 0.5.0

- Integrate the latest `prometheus_client` version.

## 0.4.1

No changes

## 0.4.0+4

- Moved to new org [tentaclelabs](https://github.com/tentaclelabs)

## 0.4.0+3

- Remove author from pubspec.

## 0.4.0+2

- Fix some analyzer issues, no functional changes.

## 0.4.0+1

- Align version constraint to `prometheus_client_shelf`.

## 0.4.0

- Move shelf support into own package [`prometheus_client_shelf`](https://pub.dev/packages/prometheus_client).
