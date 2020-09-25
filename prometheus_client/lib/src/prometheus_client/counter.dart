part of prometheus_client;

/// [Counter] is a monotonically increasing counter.
class Counter extends _SimpleCollector<CounterChild> {
  /// Construct a new [Counter] with a [name], [help] text and optional
  /// [labelNames].
  /// If [labelNames] are provided, use [labels(...)] to assign label values.
  Counter(String name, String help, {List<String> labelNames = const []})
      : super(name, help, labelNames: labelNames);

  /// Increment the [value] of the counter without labels by [amount].
  /// Increments by one, if no amount is provided.
  void inc([double amount = 1]) {
    _noLabelChild.inc(amount);
  }

  /// Accesses the current value of the counter without labels.
  double get value => _noLabelChild.value;

  @override
  Iterable<MetricFamilySamples> collect() sync* {
    final samples = <Sample>[];
    _children.forEach((labelValues, child) =>
        samples.add(Sample(name, labelNames, labelValues, child._value)));

    yield MetricFamilySamples(name, MetricType.counter, help, samples);
  }

  @override
  CounterChild _createChild() => CounterChild._();
}

/// Defines a [CounterChild] of a [Counter] with assigned [labelValues].
class CounterChild {
  double _value = 0;

  CounterChild._();

  /// Increment the [value] of the counter with labels by [amount].
  /// Increments by one, if no amount is provided.
  void inc([double amount = 1]) {
    if (amount <= 0) {
      throw ArgumentError.value(
          amount, 'amount', 'Must be greater than zero.');
    }

    _value += amount;
  }

  /// Accesses the current value of the counter with labels.
  double get value => _value;
}
