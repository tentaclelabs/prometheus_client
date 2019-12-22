part of prometheus_client;

/// [Histogram] allows aggregatable distributions of events, such as request
/// latencies.
class Histogram extends _SimpleCollector<HistogramChild> {
  /// Name of the 'le' label.
  static const leLabel = 'le';

  /// The default upper bounds for histogram buckets.
  static const defaultBuckets = <double>[
    .005,
    .01,
    .025,
    .05,
    .075,
    .1,
    .25,
    .5,
    .75,
    1,
    2.5,
    5,
    7.5,
    10
  ];

  /// The upper bounds of the buckets.
  final List<double> buckets;

  /// Construct a new [Histogram] with a [name], [help] text, optional
  /// [labelNames] and optional upper bounds for the [buckets].
  /// If [labelNames] are provided, use [labels(...)] to assign label values.
  /// [buckets] have to be sorted in ascending order. If no buckets are provided
  /// the [defaultBuckets] are used instead.
  Histogram(String name, String help,
      {List<String> labelNames = const [],
      List<double> buckets = defaultBuckets})
      : buckets = List.unmodifiable(_sanitizeBuckets(buckets)),
        super(name, help, labelNames: labelNames) {
    if (labelNames.contains(leLabel)) {
      throw ArgumentError.value(labelNames, 'labelNames',
          '"le" is a reseved label name for a histogram.');
    }
  }

  /// Construct a new [Histogram] with a [name], [help] text, and optional
  /// [labelNames]. The [count] buckets are linear distributed starting at
  /// [start] with a distance of [width].
  /// If [labelNames] are provided, use [labels(...)] to assign label values.
  Histogram.linear(
      String name, String help, double start, double width, int count,
      {List<String> labelNames = const []})
      : this(name, help,
            labelNames: labelNames,
            buckets:
                List.unmodifiable(_generateLinearBuckets(start, width, count)));

  /// Construct a new [Histogram] with a [name], [help] text, and optional
  /// [labelNames]. The [count] buckets are exponential distributed starting at
  /// [start] with a distance growing exponentially by [factor].
  /// If [labelNames] are provided, use [labels(...)] to assign label values.
  Histogram.exponential(
      String name, String help, double start, double factor, int count,
      {List<String> labelNames = const []})
      : this(name, help,
            labelNames: labelNames,
            buckets: List.unmodifiable(
                _generateExponentialBuckets(start, factor, count)));

  /// Observe a new value [v] and store it in the corresponding buckets of a
  /// histogram without labels.
  void observe(double v) {
    _noLabelChild.observe(v);
  }

  /// Observe the duration of [callback] and store it in the corresponding
  /// buckets of a histogram without labels.
  T observeDurationSync<T>(T Function() callback) {
    return _noLabelChild.observeDurationSync(callback);
  }

  /// Observe the duration of the [Future] [f] and store it in the corresponding
  /// buckets of a histogram without labels.
  Future<T> observeDuration<T>(Future<T> f) {
    return _noLabelChild.observeDuration(f);
  }

  /// Access the values in the buckets of a histogram without labels.
  List<double> get bucketValues => _noLabelChild.bucketValues;

  /// Access the count of elements in a histogram without labels.
  double get count => _noLabelChild.count;

  /// Access the total sum of the elements in a histogram without labels.
  double get sum => _noLabelChild.sum;

  @override
  Iterable<MetricFamilySamples> collect() sync* {
    final samples = <Sample>[];

    _children.forEach((labelValues, child) {
      final labelNamesWithLe = List.of(labelNames)..add(leLabel);

      for (var i = 0; i < buckets.length; ++i) {
        samples.add(Sample(
            name + '_bucket',
            labelNamesWithLe,
            List.of(labelValues)..add(formatDouble(buckets[i])),
            child._bucketValues[i]));
      }

      samples
          .add(Sample(name + '_count', labelNames, labelValues, child.count));
      samples.add(Sample(name + '_sum', labelNames, labelValues, child.sum));
    });

    yield MetricFamilySamples(name, MetricType.histogram, help, samples);
  }

  @override
  HistogramChild _createChild() => HistogramChild._(buckets);

  static List<double> _sanitizeBuckets(List<double> buckets) {
    if (buckets.isEmpty) {
      throw ArgumentError.value(
          buckets, 'buckets', 'Histogram must have at least one bucket.');
    }
    buckets.reduce((l, r) {
      if (l >= r) {
        throw ArgumentError.value(buckets, 'buckets',
            'Histogram buckets must be in increasing order.');
      }
      return r;
    });

    if (buckets[buckets.length - 1].isFinite) {
      buckets = List.of(buckets);
      buckets.add(double.infinity);
    }

    return buckets;
  }

  static List<double> _generateLinearBuckets(
          double start, double width, int count) =>
      List<double>.generate(count, (i) => start + i * width);

  static List<double> _generateExponentialBuckets(
          double start, double factor, int count) =>
      List<double>.generate(count, (i) => start * math.pow(factor, i));
}

/// Defines a [HistogramChild] of a [Histogram] with assigned [labelValues].
class HistogramChild {
  /// The upper bounds of the buckets.
  final List<double> buckets;

  final List<double> _bucketValues;
  double _sum = 0;

  HistogramChild._(this.buckets)
      : _bucketValues = List<double>.filled(buckets.length, 0.0);

  /// Observe a new value [v] and store it in the corresponding buckets of a
  /// histogram with labels.
  void observe(double v) {
    for (var i = 0; i < buckets.length; ++i) {
      if (v <= buckets[i]) {
        _bucketValues[i]++;
      }
    }
    _sum += v;
  }

  /// Observe the duration of [callback] and store it in the corresponding
  /// buckets of a histogram with labels.
  T observeDurationSync<T>(T Function() callback) {
    final stopwatch = Stopwatch()..start();
    try {
      return callback();
    } finally {
      observe(stopwatch.elapsedMicroseconds / Duration.microsecondsPerSecond);
    }
  }

  /// Observe the duration of the [Future] [f] and store it in the corresponding
  /// buckets of a histogram with labels.
  Future<T> observeDuration<T>(Future<T> f) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await f;
    } finally {
      observe(stopwatch.elapsedMicroseconds / Duration.microsecondsPerSecond);
    }
  }

  /// Access the values in the buckets of a histogram with labels.
  List<double> get bucketValues => List.of(_bucketValues);

  /// Access the count of elements in a histogram with labels.
  double get count => _bucketValues.last;

  /// Access the total sum of the elements in a histogram with labels.
  double get sum => _sum;
}
