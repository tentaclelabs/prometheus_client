part of prometheus_client;

/// A [Gauge] represents a value that can go up and down.
class Gauge extends _SimpleCollector<GaugeChild> {
  /// Construct a new [Gauge] with a [name], [help] text and optional
  /// [labelNames].
  /// If [labelNames] are provided, use [labels(...)] to assign label values.
  Gauge(String name, String help, {List<String> labelNames = const []})
      : super(name, help, labelNames: labelNames);

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
  Iterable<MetricFamilySamples> collect() sync* {
    final samples = <Sample>[];
    _children.forEach((labelValues, child) =>
        samples.add(Sample(name, labelNames, labelValues, child._value)));

    yield MetricFamilySamples(name, MetricType.gauge, help, samples);
  }

  @override
  GaugeChild _createChild() => GaugeChild._();
}

class GaugeChild {
  double _value = 0;

  GaugeChild._();

  /// Increment the [value] of the gauge with labels by [amount].
  /// Increments by one, if no amount is provided.
  void inc([double amount = 1]) {
    _value += amount;
  }

  /// Decrement the [value] of the gauge with labels by [amount].
  /// Decrements by one, if no amount is provided.
  void dec([double amount = 1]) {
    _value -= amount;
  }

  /// Set the [value] of the gauge with labels to the current time as a unix
  /// timestamp.
  void setToCurrentTime() {
    _value = DateTime.now().millisecondsSinceEpoch.toDouble();
  }

  /// Accesses the current value of the gauge with labels.
  double get value => _value;

  /// Sets the current value of the gauge with labels.
  set value(double v) => _value = v;
}
