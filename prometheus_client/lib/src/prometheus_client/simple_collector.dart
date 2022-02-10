part of prometheus_client;

abstract class _SimpleCollector<Child> extends Collector {
  static const _eq = ListEquality();

  /// The [name] of the metric.
  final String name;

  /// The [help] text of the metric.
  final String help;

  /// The unmodifiable list of [labelNames] assigned to this metric.
  final List<String> labelNames;

  final _children = HashMap<List<String>, Child>(
    equals: _eq.equals,
    hashCode: _eq.hash,
    isValidKey: _eq.isValidKey,
  );

  _SimpleCollector({
    required this.name,
    required this.help,
    List<String> labelNames = const [],
  }) : labelNames = List.unmodifiable(labelNames) {
    checkMetricName(name);
    labelNames.forEach(checkMetricLabelName);
    _initializeNoLabelChild();
  }

  Child _createChild();

  /// Register the [Collector] at a [registry]. If no [registry] is provided, the
  /// [CollectorRegistry.defaultRegistry] is used.
  void register([CollectorRegistry? registry]) {
    registry ??= CollectorRegistry.defaultRegistry;

    registry.register(this);
  }

  /// Create a [Child] metric and assign the [labelValues].
  /// The size of the [labelValues] has to match the [labelNames] of the metric.
  Child labels(List<String> labelValues) {
    if (labelValues.length != labelNames.length) {
      throw ArgumentError.value(
          labelValues, 'labelValues', 'Length must match label names.');
    }

    return _children.putIfAbsent(List.unmodifiable(labelValues), _createChild);
  }

  /// Remove a [Child] metric based on it's label values.
  void remove(List<String> labelValues) {
    _children.remove(labelValues);
  }

  /// Remove all [Child] metrics.
  void clear() {
    _children.clear();
    _initializeNoLabelChild();
  }

  Child get _noLabelChild {
    if (labelNames.isNotEmpty) {
      throw StateError('Metric has labels, set label values via labels(...).');
    }

    return labels(const []);
  }

  void _initializeNoLabelChild() {
    if (labelNames.isEmpty) {
      labels(const []);
    }
  }
}
