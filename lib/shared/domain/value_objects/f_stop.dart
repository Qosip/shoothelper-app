import 'dart:math';

/// Represents an f-stop (aperture) value.
/// Immutable value object with standard photography f-stop values.
class FStop implements Comparable<FStop> {
  final double value;

  const FStop(this.value) : assert(value > 0);

  /// Standard 1/3-stop aperture scale.
  static const List<double> standardValues = [
    1.0, 1.1, 1.2, 1.4, 1.6, 1.8, 2.0, 2.2, 2.5, 2.8,
    3.2, 3.5, 4.0, 4.5, 5.0, 5.6, 6.3, 7.1, 8.0, 9.0,
    10, 11, 13, 14, 16, 18, 20, 22,
  ];

  /// Rounds to the nearest standard f-stop value.
  FStop toNearestStandard() {
    double closest = standardValues.first;
    double minDiff = (value - closest).abs();
    for (final std in standardValues) {
      final diff = (value - std).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = std;
      }
    }
    return FStop(closest);
  }

  /// Rounds to the nearest standard f-stop that lets in MORE light (smaller f-number).
  FStop toNearestWider() {
    for (int i = standardValues.length - 1; i >= 0; i--) {
      if (standardValues[i] <= value + 0.01) return FStop(standardValues[i]);
    }
    return FStop(standardValues.first);
  }

  /// Rounds to the nearest standard f-stop that lets in LESS light (larger f-number).
  FStop toNearestNarrower() {
    for (final std in standardValues) {
      if (std >= value - 0.01) return FStop(std);
    }
    return FStop(standardValues.last);
  }

  /// EV contribution: EV_aperture = 2 * log2(f_number)
  double get evContribution => 2 * (log(value) / ln2);

  /// Display string, e.g. "f/2.8"
  String get display {
    if (value == value.roundToDouble() && value >= 1) {
      return 'f/${value.toInt()}';
    }
    return 'f/$value';
  }

  /// Difference in stops from another FStop.
  double stopsFrom(FStop other) => 2 * (log(value / other.value) / ln2);

  @override
  int compareTo(FStop other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is FStop && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => display;

  bool operator <(FStop other) => value < other.value;
  bool operator >(FStop other) => value > other.value;
  bool operator <=(FStop other) => value <= other.value;
  bool operator >=(FStop other) => value >= other.value;
}
