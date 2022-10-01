part of prometheus_client;

/// Defines the different metric type supported by Prometheus.
enum MetricType {
  /// [MetricType.counter] is a monotonically increasing counter.
  counter,

  /// [MetricType.gauge] represents a value that can go up and down.
  gauge,

  /// A [MetricType.summary] samples observations over sliding windows of time
  /// and provides instantaneous insight into their distributions, frequencies,
  /// and sums.
  summary,

  /// [MetricType.histogram]s allow aggregatable distributions of events, such
  /// as request latencies.
  histogram,

  /// [MetricType.untyped] can be used for metrics that don't fit the other
  /// types.
  untyped
}

/// A [Sample] represents a sampled value of a metric.
class Sample {
  /// The [name] of the metric.
  final String name;

  /// The unmodifiable list of label names corresponding to the [labelValues].
  /// Label values and name with the same index belong to each other.
  final List<String> labelNames;

  /// The unmodifiable list of label values corresponding to the [labelNames].
  /// Label values and name with the same index belong to each other.
  final List<String> labelValues;

  /// The sampled value of the metric.
  final double value;

  /// The timestamp of the moment the sample was taken.
  final int? timestamp;

  /// Constructs a new sample with [name], [labelNames], [labelValues] as well
  /// as the sampled [value] and an optional [timestamp].
  /// [labelNames] and [labelValues] can be empty lists.
  Sample(
    this.name,
    List<String> labelNames,
    List<String> labelValues,
    this.value, [
    this.timestamp,
  ])  : labelNames = List.unmodifiable(labelNames),
        labelValues = List.unmodifiable(labelValues);

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write(name);
    buffer.write(' (');
    for (var i = 0; i < labelNames.length; ++i) {
      if (i > 0) {
        buffer.write(' ');
      }
      buffer.write(labelNames[i]);
      buffer.write('=');
      buffer.write(labelValues[i]);
    }
    buffer.write(') ');
    buffer.write(value);
    if (timestamp != null) {
      buffer.write(' ');
      buffer.write(timestamp);
    }
    return buffer.toString();
  }
}

/// A [MetricFamilySamples] groups all samples of a metric family.
class MetricFamilySamples {
  /// The [name] of the metric.
  final String name;

  /// The [type] of the metric.
  final MetricType type;

  /// The [help] text of the metric.
  final String help;

  /// The unmodifiable list of [samples] belonging the this metric family.
  final List<Sample> samples;

  /// Constructs a new metric family with a [name], [type], [help] text and
  /// related [samples].
  MetricFamilySamples(this.name, this.type, this.help, List<Sample> samples)
      : samples = List.unmodifiable(samples);

  @override
  String toString() =>
      '$name ($type) $help [${samples.isEmpty ? '' : '\n'}${samples.join('\n')}]';
}

/// A callback used to aggregate the current sample values.
typedef Collect<T extends Collector> = FutureOr<void> Function(T collector);

/// A [Collector] is registered at a [CollectorRegistry] and scraped for metrics.
/// A [Collector] can be registered at multiple [CollectorRegistry]s.
abstract class Collector {
  /// [collect] all metrics and samples that are part of this [Collector].
  Future<Iterable<MetricFamilySamples>> collect();

  /// Collect all metric names, including child metrics.
  Iterable<String> collectNames();
}

/// A [CollectorRegistry] is used to manage [Collector]s.
/// Own [CollectorRegistry] instances can be created, but a [defaultRegistry] is
/// also provided.
class CollectorRegistry {
  /// The default [CollectorRegistry] that can be used to register [Collector]s.
  /// Most of the time, the [defaultRegistry] is sufficient.
  static final defaultRegistry = CollectorRegistry();

  final _collectorsToNames = <Collector, Set<String>>{};
  final _namesToCollectors = <String, Collector>{};

  /// Register a [Collector] with the [CollectorRegistry].
  /// Does nothing if the [collector] is already registered.
  void register(Collector collector) {
    final collectorNames = Set<String>.from(collector.collectNames());

    for (var name in collectorNames) {
      if (_namesToCollectors.containsKey(name)) {
        throw ArgumentError(
            'Collector already registered that provides name: $name');
      }
    }

    for (var name in collectorNames) {
      _namesToCollectors[name] = collector;
    }

    _collectorsToNames[collector] = collectorNames;
  }

  /// Unregister a [Collector] from the [CollectorRegistry].
  void unregister(Collector collector) {
    final collectorNames = _collectorsToNames.remove(collector);

    if (collectorNames != null) {
      for (var name in collectorNames) {
        _namesToCollectors.remove(name);
      }
    }
  }

  /// Collect all metrics and samples from the registered [Collector]s.
  Future<Iterable<MetricFamilySamples>> collectMetricFamilySamples() async {
    final metricFamilySamples =
        await Future.wait(_collectorsToNames.keys.map((c) => c.collect()));

    return metricFamilySamples.expand((m) => m);
  }

  @override
  String toString() => '${_namesToCollectors.length} metrics';
}
