/// A library containing the core elements of the Prometheus client, like the
/// [CollectorRegistry] and different types of metrics like [Counter], [Gauge]
/// and [Histogram].
library prometheus_client;

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import "package:collection/collection.dart";
import 'package:prometheus_client/src/double_format.dart';
import 'package:prometheus_client/src/quantiles.dart';

export 'package:prometheus_client/src/quantiles.dart' show Quantile;

part 'src/prometheus_client/collector.dart';

part 'src/prometheus_client/counter.dart';

part 'src/prometheus_client/gauge.dart';

part 'src/prometheus_client/helper.dart';

part 'src/prometheus_client/histogram.dart';

part 'src/prometheus_client/simple_collector.dart';

part 'src/prometheus_client/summary.dart';
