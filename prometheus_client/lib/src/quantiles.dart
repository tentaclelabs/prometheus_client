import 'dart:typed_data';

/// Defines a quantile.
class Quantile {
  /// The [quantile].
  final double quantile;

  /// The allowed [error].
  final double error;
  final double u;
  final double v;

  /// Construct a new quantile with [quantile] and the allowed [error].
  Quantile(this.quantile, this.error)
      : u = 2.0 * error / (1.0 - quantile),
        v = 2.0 * error / quantile {
    if (quantile < 0.0 || quantile > 1.0) {
      throw ArgumentError.value(
          quantile, 'quantile', 'Expected number between 0.0 and 1.0');
    }
    if (error < 0.0 || error > 1.0) {
      throw ArgumentError.value(
          error, 'error', 'Expected number between 0.0 and 1.0');
    }
  }

  @override
  String toString() => 'q=$quantile, eps=$error';
}

class _Item {
  final double value;
  int g;
  final int delta;

  _Item(this.value, this.g, this.delta);

  @override
  String toString() => 'val=$value, g=$g d=$delta';
}

class CkmsQuantiles {
  final List<Quantile> quantiles;

  int _count = 0;
  final _samples = <_Item>[];
  final _buffer = Float64List(500);
  int _bufferCount = 0;

  CkmsQuantiles(List<Quantile> quantiles)
      : quantiles = List.unmodifiable(quantiles);

  void insert(double value) {
    _buffer[_bufferCount] = value;
    ++_bufferCount;

    if (_bufferCount == _buffer.length) {
      _insertBatch();
      _compress();
    }
  }

  double retrieve(double q) {
    _insertBatch();
    _compress();

    if (_samples.isEmpty) {
      return double.nan;
    }

    var rankMin = 0;
    var desired = (q * _count).floor();

    for (var i = 1; i < _samples.length; ++i) {
      final prev = _samples[i - 1];
      final cur = _samples[i];

      rankMin += prev.g;

      if (rankMin + cur.g + cur.delta >
          desired + (_allowableError(desired) / 2.0)) {
        return prev.value;
      }
    }

    return _samples.last.value;
  }

  void clear() {
    _samples.clear();
    _count = 0;
    _bufferCount = 0;
  }

  double _allowableError(int rank) {
    var size = _samples.length;
    var minError = size + 1.0;

    for (var i = 0; i < quantiles.length; ++i) {
      final q = quantiles[i];
      final error =
          rank <= q.quantile * size ? q.u * (size - rank) : q.v * rank;
      if (error < minError) {
        minError = error;
      }
    }

    return minError;
  }

  bool _insertBatch() {
    if (_bufferCount == 0) {
      return false;
    }

    Float64List.view(_buffer.buffer, 0, _bufferCount).sort();

    var start = 0;
    if (_samples.isEmpty) {
      _samples.add(_Item(_buffer[0], 1, 0));
      start++;
      _count++;
    }

    var j = 0;
    var item = _samples[j];

    for (var i = start; i < _bufferCount; i++) {
      var v = _buffer[i];
      while (j + 1 < _samples.length && item.value < v) {
        item = _samples[++j];
      }

      if (item.value > v) {
        --j;
      }

      int delta;
      if (j - 1 == 0 || j + 1 == _samples.length) {
        delta = 0;
      } else {
        delta = _allowableError(j + 1).floor() - 1;
      }

      item = _Item(v, 1, delta);
      _samples.insert(++j, item);
      ++_count;
    }

    _bufferCount = 0;
    return true;
  }

  void _compress() {
    if (_samples.length < 2) {
      return;
    }

    _Item prev;
    var next = _samples[0];

    for (var i = 1; i < _samples.length - 1; ++i) {
      prev = next;
      next = _samples[i];

      if (prev.g + next.g + next.delta <= _allowableError(i - 1)) {
        next.g += prev.g;
        _samples.removeAt(--i);
      }
    }
  }
}

class TimeWindowQuantiles {
  final List<Quantile> quantiles;
  final Duration maxAge;

  final int _durationBetweenRotatesMillis;
  final List<CkmsQuantiles> _ringBuffer;
  int _currentBucket = 0;
  int _lastRotateTimestampMillis = DateTime.now().millisecondsSinceEpoch;

  TimeWindowQuantiles(this.quantiles, this.maxAge, int ageBuckets)
      : _durationBetweenRotatesMillis = maxAge.inMilliseconds ~/ ageBuckets,
        _ringBuffer =
            List.generate(ageBuckets, (i) => CkmsQuantiles(quantiles));

  double retrieve(double q) => _rotate().retrieve(q);

  void insert(double value) {
    _rotate();
    for (var i = 0; i < _ringBuffer.length; ++i) {
      _ringBuffer[i].insert(value);
    }
  }

  CkmsQuantiles _rotate() {
    var timeSinceLastRotateMillis =
        DateTime.now().millisecondsSinceEpoch - _lastRotateTimestampMillis;
    while (timeSinceLastRotateMillis > _durationBetweenRotatesMillis) {
      _ringBuffer[_currentBucket].clear();
      if (++_currentBucket >= _ringBuffer.length) {
        _currentBucket = 0;
      }
      timeSinceLastRotateMillis -= _durationBetweenRotatesMillis;
      _lastRotateTimestampMillis += _durationBetweenRotatesMillis;
    }
    return _ringBuffer[_currentBucket];
  }
}
