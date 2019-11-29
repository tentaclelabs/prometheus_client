/// A library to export metrics in the Prometheus text representation.
library format;

import 'package:prometheus_client/prometheus_client.dart';
import 'package:prometheus_client/src/double_format.dart';

/// Content-type for text version 0.0.4.
const contentType = 'text/plain; version=0.0.4; charset=utf-8';

/// Write out the text version 0.0.4 of the given [MetricFamilySamples].
void write004(
    StringSink sink, Iterable<MetricFamilySamples> metricFamilySamples) {
  // See http://prometheus.io/docs/instrumenting/exposition_formats/
  // for the output format specification
  for (var metricFamilySample in metricFamilySamples) {
    sink.write('# HELP ');
    sink.write(metricFamilySample.name);
    sink.write(' ');
    _writeEscapedHelp(sink, metricFamilySample.help);
    sink.write('\n');

    sink.write('# TYPE ');
    sink.write(metricFamilySample.name);
    sink.write(' ');
    _writeMetricType(sink, metricFamilySample.type);
    sink.write('\n');

    for (var sample in metricFamilySample.samples) {
      sink.write(sample.name);
      if (sample.labelNames.isNotEmpty) {
        sink.write('{');
        for (var i = 0; i < sample.labelNames.length; ++i) {
          sink.write(sample.labelNames[i]);
          sink.write('="');
          _writeEscapedLabelValue(sink, sample.labelValues[i]);
          sink.write('\",');
        }
        sink.write('}');
      }
      sink.write(' ');
      sink.write(formatDouble(sample.value));
      if (sample.timestamp != null) {
        sink.write(' ');
        sink.write(sample.timestamp);
      }
      sink.writeln();
    }
  }
}

void _writeMetricType(StringSink sink, MetricType type) {
  switch (type) {
    case MetricType.counter:
      sink.write('counter');
      break;
    case MetricType.gauge:
      sink.write('gauge');
      break;
    case MetricType.summary:
      sink.write('summary');
      break;
    case MetricType.histogram:
      sink.write('histogram');
      break;
    case MetricType.untyped:
      sink.write('untyped');
      break;
  }
}

const _codeUnitLineFeed = 10; // \n
const _codeUnitBackslash = 92; // \
const _codeUnitDoubleQuotes = 34; // "

void _writeEscapedHelp(StringSink sink, String help) {
  for (var i = 0; i < help.length; ++i) {
    var c = help.codeUnitAt(i);
    switch (c) {
      case _codeUnitBackslash:
        sink.write('\\\\');
        break;
      case _codeUnitLineFeed:
        sink.write('\\n');
        break;
      default:
        sink.writeCharCode(c);
        break;
    }
  }
}

void _writeEscapedLabelValue(StringSink sink, String labelValue) {
  for (var i = 0; i < labelValue.length; ++i) {
    var c = labelValue.codeUnitAt(i);
    switch (c) {
      case _codeUnitBackslash:
        sink.write('\\\\');
        break;
      case _codeUnitDoubleQuotes:
        sink.write('\\"');
        break;
      case _codeUnitLineFeed:
        sink.write('\\n');
        break;
      default:
        sink.writeCharCode(c);
        break;
    }
  }
}
