import 'dart:math';

import '../../../../shared/domain/entities/body_spec.dart';
import '../../../../shared/domain/value_objects/f_stop.dart';
import '../../../../shared/domain/value_objects/shutter_speed.dart';

/// NPF rule calculator for astrophotography.
/// Skill 06 §3.6.
///
/// t_max = (35 × N + 30 × p) / (focal_mm × cos(δ))
/// Simplified: δ = 0 → cos(δ) = 1
class AstroCalculator {
  const AstroCalculator();

  /// Compute pixel pitch in µm from sensor dimensions and megapixels.
  double pixelPitch(SensorSpec sensor) {
    final area = sensor.sensorWidthMm * sensor.sensorHeightMm;
    final pixelCount = sensor.megapixels * 1e6;
    return sqrt(area / pixelCount) * 1000;
  }

  /// Maximum exposure time for point stars (NPF rule).
  /// Returns ShutterSpeed clamped to 30s max.
  ShutterSpeed maxExposureTime({
    required FStop aperture,
    required SensorSpec sensor,
    required int focalMm,
  }) {
    final p = pixelPitch(sensor);
    final tMax = (35 * aperture.value + 30 * p) / focalMm;
    final clamped = tMax.clamp(0.5, 30.0);
    return ShutterSpeed(clamped);
  }
}
