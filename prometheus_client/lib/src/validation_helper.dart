final _metricNamePattern = RegExp('^[a-zA-Z_:][a-zA-Z0-9_:]*\$');
final _labelNamePattern = RegExp('^[a-zA-Z_][a-zA-Z0-9_]*\$');
final _reservedMetricLabelNamePattern = RegExp('^__.*\$');

void checkMetricName(String name) {
  if (!_metricNamePattern.hasMatch(name)) {
    throw ArgumentError.value(name, 'name', 'Invalid metric name');
  }
}

void checkMetricLabelName(String name) {
  if (!_labelNamePattern.hasMatch(name)) {
    throw ArgumentError.value(name, 'name', 'Invalid metric label name');
  }
  if (_reservedMetricLabelNamePattern.hasMatch(name)) {
    throw ArgumentError.value(
        name, 'name', 'Invalid metric label name, reserved for internal use');
  }
}
