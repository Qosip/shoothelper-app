import 'dart:math';

/// Represents an ISO sensitivity value.
/// Immutable value object with standard photography ISO values.
class IsoValue implements Comparable<IsoValue> {
  final int value;

  const IsoValue(this.value) : assert(value > 0);

  /// Standard 1/3-stop ISO scale.
  static const List<int> standardValues = [
    50, 64, 80, 100, 125, 160, 200, 250, 320, 400, 500, 640, 800,
    1000, 1250, 1600, 2000, 2500, 3200, 4000, 5000, 6400, 8000,
    10000, 12800, 16000, 20000, 25600, 32000, 51200, 102400,
  ];

  /// Rounds to the nearest standard ISO value.
  IsoValue toNearestStandard() {
    int closest = standardValues.first;
    double minRatio = _logRatio(value.toDouble(), closest.toDouble()).abs();
    for (final std in standardValues) {
      final ratio = _logRatio(value.toDouble(), std.toDouble()).abs();
      if (ratio < minRatio) {
        minRatio = ratio;
        closest = std;
      }
    }
    return IsoValue(closest);
  }

  /// Rounds to the nearest standard ISO that is LOWER (less noise).
  IsoValue toNearestLower() {
    for (int i = standardValues.length - 1; i >= 0; i--) {
      if (standardValues[i] <= value) return IsoValue(standardValues[i]);
    }
    return IsoValue(standardValues.first);
  }

  /// Rounds to the nearest standard ISO that is HIGHER (more sensitive).
  IsoValue toNearestHigher() {
    for (final std in standardValues) {
      if (std >= value) return IsoValue(std);
    }
    return IsoValue(standardValues.last);
  }

  /// EV contribution: EV_iso = -log2(ISO / 100)
  double get evContribution => -(log(value / 100) / ln2);

  /// Display string, e.g. "ISO 3200".
  String get display => 'ISO $value';

  /// Difference in stops from another IsoValue.
  double stopsFrom(IsoValue other) => log(value / other.value) / ln2;

  static double _logRatio(double a, double b) => log(a / b) / ln2;

  @override
  int compareTo(IsoValue other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is IsoValue && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => display;

  bool operator <(IsoValue other) => value < other.value;
  bool operator >(IsoValue other) => value > other.value;
  bool operator <=(IsoValue other) => value <= other.value;
  bool operator >=(IsoValue other) => value >= other.value;
}
