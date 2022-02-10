part of prometheus_client;

/// A [Gauge] represents a value that can go up and down.
class Gauge extends _SimpleCollector<GaugeChild> {
  /// Optional callback called in [collect] before samples are collected.
  ///
  /// Can be used to update the current sample value before collecting it.
  final Collect<Gauge>? collectCallback;

  /// Construct a new [Gauge] with a [name], [help] text and optional
  /// [labelNames].
  /// If [labelNames] are provided, use [labels(...)] to assign label values.
  /// The optional [collectCallback] is called at the beginning of [collect] and
  /// allows to update the value of the gauge before collecting it.
  Gauge({
    required String name,
    required String help,
    List<String> labelNames = const [],
    this.collectCallback,
  }) : super(name: name, help: help, labelNames: labelNames);

  /// Increment the [value] of the gauge without labels by [amount].
  /// Increments by one, if no amount is provided.
  void inc([double amount = 1]) {
    _noLabelChild.inc(amount);
  }

  /// Decrement the [value] of the gauge without labels by [amount].
  /// Decrements by one, if no amount is provided.
  void dec([double amount = 1]) {
    _noLabelChild.dec(amount);
  }

  /// Set the [value] of the gauge without labels to the current time as a unix
  /// timestamp.
  void setToCurrentTime() {
    _noLabelChild.setToCurrentTime();
  }

  /// Accesses the current value of the gauge without labels.
  double get value => _noLabelChild.value;

  /// Sets the current value of the gauge without labels.
  set value(double v) => _noLabelChild.value = v;

  @override
  Future<Iterable<MetricFamilySamples>> collect() async {
    await collectCallback?.call(this);

    final samples = <Sample>[];
    _children.forEach((labelValues, child) =>
        samples.add(Sample(name, labelNames, labelValues, child.value)));

    return [MetricFamilySamples(name, MetricType.gauge, help, samples)];
  }

  @override
  Iterable<String> collectNames() {
    return [name];
  }

  @override
  GaugeChild _createChild() => GaugeChild._();
}

/// Defines a [GaugeChild] of a [Gauge] with assigned [labelValues].
class GaugeChild {
  /// Accesses the current value of the gauge with labels.
  double value = 0;

  GaugeChild._();

  /// Increment the [value] of the gauge with labels by [amount].
  /// Increments by one, if no amount is provided.
  void inc([double amount = 1]) {
    value += amount;
  }

  /// Decrement the [value] of the gauge with labels by [amount].
  /// Decrements by one, if no amount is provided.
  void dec([double amount = 1]) {
    value -= amount;
  }

  /// Set the [value] of the gauge with labels to the current time as a unix
  /// timestamp.
  void setToCurrentTime() {
    value = DateTime.now().millisecondsSinceEpoch.toDouble();
  }
}
