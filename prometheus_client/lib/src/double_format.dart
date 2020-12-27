String formatDouble(double value) {
  if (value.isInfinite) {
    if (value.isNegative) {
      return '-Inf';
    } else {
      return '+Inf';
    }
  } else if (value.isNaN) {
    return 'NaN';
  } else {
    return value.toString();
  }
}
