/// A library exposing metrics of the Dart runtime.
library prometheus_client.runtime_metrics;

import 'dart:io';

import 'package:prometheus_client/prometheus_client.dart';

/// Collector for runtime metrics. Exposes the `dart_info`,
/// `process_start_time_seconds`, and `process_resident_memory_bytes` metric.
class RuntimeCollector extends Collector {
  // This is not the actual startup time of the process, but the time the first
  // collector was created. Dart's lazy initialization of globals doesn't allow
  // for a better timing...
  static final _startupTime =
      DateTime.now().millisecondsSinceEpoch / Duration.millisecondsPerSecond;

  @override
  Future<Iterable<MetricFamilySamples>> collect() async {
    return [
      MetricFamilySamples('dart_info', MetricType.gauge,
          'Information about the Dart environment.', [
        Sample('dart_info', const ['version'], [Platform.version], 1)
      ]),

      // TODO: Metrics about gc & co would be nice runtime metrics but are
      //  unavailable in the Dart VM.

      // TODO: We can only support a limited set of process metrics, as Dart
      //  doesn't expose more of them.

      MetricFamilySamples('process_resident_memory_bytes', MetricType.gauge,
          'Resident memory size in bytes.', [
        Sample('process_resident_memory_bytes', const [], const [],
            ProcessInfo.currentRss.toDouble())
      ]),

      MetricFamilySamples('process_start_time_seconds', MetricType.gauge,
          'Start time of the process since unix epoch in seconds.', [
        Sample('process_start_time_seconds', const [], const [],
            _startupTime.toDouble())
      ]),
    ];
  }

  @override
  Iterable<String> collectNames() {
    return [
      'dart_info',
      'process_resident_memory_bytes',
      'process_start_time_seconds',
    ];
  }
}

/// Register default metrics for the Dart runtime. If no [registry] is provided,
/// the [CollectorRegistry.defaultRegistry] is used.
void register([CollectorRegistry? registry]) {
  registry ??= CollectorRegistry.defaultRegistry;

  registry.register(RuntimeCollector());
}
