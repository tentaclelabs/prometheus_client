/// A library containing a shelf handler that exposes metrics in the Prometheus
/// text format.
library shelf_handler;

import 'package:shelf/shelf.dart' as shelf;
import 'package:prometheus_client/prometheus_client.dart';
import 'package:prometheus_client/format.dart' as format;

/// Create a shelf handler that returns the metrics in the prometheus text
/// representation. If no [registry] is provided, the
/// [CollectorRegistry.defaultRegistry] is used.
prometheusHandler([CollectorRegistry registry]) {
  registry ??= CollectorRegistry.defaultRegistry;

  return (shelf.Request request) {
    // TODO: Instead of using a StringBuffer we could directly stream to network
    final buffer = StringBuffer();
    format.write004(buffer, registry.collectMetricFamilySamples());
    return shelf.Response.ok(buffer.toString(),
        headers: {"Content-Type": format.contentType});
  };
}
