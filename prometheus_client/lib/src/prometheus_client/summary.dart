part of prometheus_client;

/// Similar to a [Histogram], a [Summary] samples observations (usually things
/// like request durations and response sizes). While it also provides a total
/// count of observations and a sum of all observed values, it calculates
/// configurable quantiles over a sliding time window.
class Summary extends _SimpleCollector<SummaryChild> {
  static const quantileLabel = 'quantile';

  /// Optional callback called in [collect] before samples are collected.
  ///
  /// Can be used to update the current sample value before collecting it.
  final Collect<Summary>? collectCallback;

  /// Quantiles to observe by the summary.
  final List<Quantile> quantiles;

  /// Set the duration of the time window is, i.e. how long observations are
  /// kept before they are discarded.
  final Duration maxAge;

  /// Set the number of buckets used to implement the sliding time window. If
  /// your time window is 10 minutes, and you have ageBuckets=5, buckets will
  /// be switched every 2 minutes. The value is a trade-off between resources
  /// (memory and cpu for maintaining the bucket) and how smooth the time window
  /// is moved.
  final int ageBuckets;

  /// Construct a new [Summary] with a [name], [help] text, optional
  /// [labelNames], optional [quantiles], optional [maxAge] and optional
  /// [ageBuckets].
  /// If [labelNames] are provided, use [labels(...)] to assign label values.
  /// If no [quantiles] are provided the summary only has a count and sum.
  /// If not provided, [maxAge] defaults to 10 minutes and [ageBuckets] to 5.
  /// The optional [collectCallback] is called at the beginning of [collect] and
  /// allows to update the value of the summary before collecting it.
  Summary({
    required String name,
    required String help,
    List<String> labelNames = const [],
    List<Quantile> quantiles = const [],
    this.maxAge = const Duration(minutes: 10),
    this.ageBuckets = 5,
    this.collectCallback,
  })  : quantiles = List.unmodifiable(quantiles),
        super(name: name, help: help, labelNames: labelNames) {
    if (labelNames.contains(quantileLabel)) {
      throw ArgumentError.value(labelNames, 'labelNames',
          '"quantile" is a reserved label name for a summary.');
    }
  }

  /// Observe a new value [v] and store it in the summary without labels.
  void observe(double v) {
    _noLabelChild.observe(v);
  }

  /// Observe the duration of [callback] and store it in the summary without
  /// labels.
  T observeDurationSync<T>(T Function() callback) {
    return _noLabelChild.observeDurationSync(callback);
  }

  /// Observe the duration of the [Future] [f] and store it in the summary
  /// without labels.
  Future<T> observeDuration<T>(Future<T> f) {
    return _noLabelChild.observeDuration(f);
  }

  /// Access the count of elements in a summary without labels.
  double get count => _noLabelChild.count;

  /// Access the total sum of the elements in a summary without labels.
  double get sum => _noLabelChild.sum;

  /// Access the value of each quantile of a summary without labels.
  Map get values => _noLabelChild.values;

  @override
  SummaryChild _createChild() => SummaryChild._(quantiles, maxAge, ageBuckets);

  @override
  Future<Iterable<MetricFamilySamples>> collect() async {
    await collectCallback?.call(this);

    final samples = <Sample>[];

    _children.forEach((labelValues, child) {
      final labelNamesWithQuantile = List.of(labelNames)..add(quantileLabel);
      final values = child.values;

      for (var i = 0; i < quantiles.length; ++i) {
        final q = quantiles[i].quantile;
        samples.add(Sample(name, labelNamesWithQuantile,
            List.of(labelValues)..add(formatDouble(q)), values[q]));
      }

      samples
          .add(Sample('${name}_count', labelNames, labelValues, child.count));
      samples.add(Sample('${name}_sum', labelNames, labelValues, child.sum));
    });

    return [MetricFamilySamples(name, MetricType.summary, help, samples)];
  }

  @override
  Iterable<String> collectNames() {
    return [
      '${name}_count',
      '${name}_sum',
      name,
    ];
  }
}

/// Defines a [SummaryChild] of a [Summary] with assigned [labelValues].
class SummaryChild {
  /// Quantiles to observe by the summary.
  final List<Quantile> quantiles;

  double _count = 0;
  double _sum = 0;
  final TimeWindowQuantiles? _quantileValues;

  SummaryChild._(this.quantiles, Duration maxAge, int ageBuckets)
      : _quantileValues = quantiles.isEmpty
            ? null
            : TimeWindowQuantiles(quantiles, maxAge, ageBuckets);

  /// Observe a new value [v] and store it in the summary with labels.
  void observe(double v) {
    _count += 1;
    _sum += v;
    _quantileValues?.insert(v);
  }

  /// Observe the duration of [callback] and store it in the summary with
  /// labels.
  T observeDurationSync<T>(T Function() callback) {
    final stopwatch = Stopwatch()..start();
    try {
      return callback();
    } finally {
      observe(stopwatch.elapsedMicroseconds / Duration.microsecondsPerSecond);
    }
  }

  /// Observe the duration of the [Future] [f] and store it in the summary with
  /// labels.
  Future<T> observeDuration<T>(Future<T> f) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await f;
    } finally {
      observe(stopwatch.elapsedMicroseconds / Duration.microsecondsPerSecond);
    }
  }

  /// Access the count of elements in a summary with labels.
  double get count => _count;

  /// Access the total sum of the elements in a summary with labels.
  double get sum => _sum;

  /// Access the value of each quantile of a summary with labels.
  Map get values => {
        for (var q in quantiles)
          q.quantile: _quantileValues!.retrieve(q.quantile),
      };
}
