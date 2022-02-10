/// A library containing a shelf handler that exposes metrics in the Prometheus
/// text format.
library shelf_handler;

import 'package:prometheus_client/format.dart' as format;
import 'package:prometheus_client/prometheus_client.dart';
import 'package:shelf/shelf.dart' as shelf;

/// Create a shelf handler that returns the metrics in the prometheus text
/// representation. If no [registry] is provided, the
/// [CollectorRegistry.defaultRegistry] is used.
shelf.Handler prometheusHandler([CollectorRegistry? registry]) {
  final reg = registry ?? CollectorRegistry.defaultRegistry;

  return (shelf.Request? request) async {
    // TODO: Instead of using a StringBuffer we could directly stream to network
    final buffer = StringBuffer();
    final metrics = await reg.collectMetricFamilySamples();
    format.write004(buffer, metrics);
    return shelf.Response.ok(
      buffer.toString(),
      headers: {'Content-Type': format.contentType},
    );
  };
}
