prometheus_client
===

This is a simple Dart implementation of the [Prometheus][prometheus] client library, [similar to to libraries for other languages][writing_clientlibs].
There are two packages:

* [prometheus_client](./prometheus_client): Package implementing metric types like gauges, counters, summaries, or histograms.
* [prometheus_client_shelf](./prometheus_client_shelf): Package implementing a [shelf][shelf] integration. 


[writing_clientlibs]: https://prometheus.io/docs/instrumenting/writing_clientlibs/
[prometheus]: https://prometheus.io/
[shelf]: https://pub.dev/packages/shelf
