import 'dart:math';

/// Represents a shutter speed value in seconds.
/// Immutable value object with standard photography shutter speed values.
class ShutterSpeed implements Comparable<ShutterSpeed> {
  /// Duration in seconds (e.g., 0.004 for 1/250s, 2.0 for 2s).
  final double seconds;

  const ShutterSpeed(this.seconds) : assert(seconds > 0);

  /// Standard 1/3-stop shutter speed scale (in seconds).
  static const List<double> standardValues = [
    1 / 8000, 1 / 6400, 1 / 5000, 1 / 4000, 1 / 3200, 1 / 2500,
    1 / 2000, 1 / 1600, 1 / 1250, 1 / 1000, 1 / 800, 1 / 640,
    1 / 500, 1 / 400, 1 / 320, 1 / 250, 1 / 200, 1 / 160,
    1 / 125, 1 / 100, 1 / 80, 1 / 60, 1 / 50, 1 / 40,
    1 / 30, 1 / 25, 1 / 20, 1 / 15, 1 / 13, 1 / 10,
    1 / 8, 1 / 6, 1 / 5, 1 / 4, 0.3, 0.4,
    0.5, 0.6, 0.8, 1, 1.3, 1.6,
    2, 2.5, 3.2, 4, 5, 6,
    8, 10, 13, 15, 20, 25, 30,
  ];

  /// Named constructors for common values.
  static ShutterSpeed fraction(int denominator) =>
      ShutterSpeed(1.0 / denominator);

  /// Rounds to the nearest standard shutter speed.
  ShutterSpeed toNearestStandard() {
    double closest = standardValues.first;
    double minRatio = _logRatio(seconds, closest).abs();
    for (final std in standardValues) {
      final ratio = _logRatio(seconds, std).abs();
      if (ratio < minRatio) {
        minRatio = ratio;
        closest = std;
      }
    }
    return ShutterSpeed(closest);
  }

  /// Rounds to the nearest standard that is FASTER (shorter exposure).
  ShutterSpeed toNearestFaster() {
    for (int i = standardValues.length - 1; i >= 0; i--) {
      if (standardValues[i] <= seconds * 1.01) return ShutterSpeed(standardValues[i]);
    }
    return ShutterSpeed(standardValues.first);
  }

  /// Rounds to the nearest standard that is SLOWER (longer exposure).
  ShutterSpeed toNearestSlower() {
    for (final std in standardValues) {
      if (std >= seconds * 0.99) return ShutterSpeed(std);
    }
    return ShutterSpeed(standardValues.last);
  }

  /// EV contribution: EV_shutter = -log2(seconds)
  double get evContribution => -(log(seconds) / ln2);

  /// Display string, e.g. "1/250s" or "2s".
  String get display {
    if (seconds >= 0.3) {
      if (seconds == seconds.roundToDouble()) {
        return '${seconds.toInt()}s';
      }
      return '${seconds}s';
    }
    final denominator = (1 / seconds).round();
    return '1/${denominator}s';
  }

  /// Difference in stops from another ShutterSpeed.
  double stopsFrom(ShutterSpeed other) => log(seconds / other.seconds) / ln2;

  static double _logRatio(double a, double b) => log(a / b) / ln2;

  @override
  int compareTo(ShutterSpeed other) => seconds.compareTo(other.seconds);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShutterSpeed && (seconds - other.seconds).abs() < 0.0001);

  @override
  int get hashCode => seconds.hashCode;

  @override
  String toString() => display;

  bool operator <(ShutterSpeed other) => seconds < other.seconds;
  bool operator >(ShutterSpeed other) => seconds > other.seconds;
  bool operator <=(ShutterSpeed other) => seconds <= other.seconds;
  bool operator >=(ShutterSpeed other) => seconds >= other.seconds;
}
