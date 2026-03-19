import 'dart:math';

import '../../../../shared/domain/value_objects/f_stop.dart';
import '../../../../shared/domain/value_objects/iso_value.dart';
import '../../../../shared/domain/value_objects/shutter_speed.dart';

/// Triangle d'exposition calculator.
/// Skill 06 §5.3 — resolve any one parameter given the other two + EV target.
///
/// EV = log2(A² / S) - log2(ISO / 100)
/// → ISO = 100 × A² / (S × 2^EV)
/// → S = A² / (ISO/100 × 2^EV)
/// → A = sqrt(S × ISO/100 × 2^EV)
class ExposureCalculator {
  const ExposureCalculator();

  /// Resolve ISO given aperture, shutter, and EV target.
  IsoValue resolveIso(FStop aperture, ShutterSpeed shutter, double evTarget) {
    final raw = 100.0 *
        (aperture.value * aperture.value / shutter.seconds) /
        pow(2, evTarget);
    return IsoValue(raw.round().clamp(1, 999999));
  }

  /// Resolve shutter speed given aperture, ISO, and EV target.
  ShutterSpeed resolveShutter(FStop aperture, IsoValue iso, double evTarget) {
    final raw = (aperture.value * aperture.value) /
        ((iso.value / 100.0) * pow(2, evTarget));
    return ShutterSpeed(raw.clamp(0.0001, 3600));
  }

  /// Resolve aperture given shutter, ISO, and EV target.
  FStop resolveAperture(ShutterSpeed shutter, IsoValue iso, double evTarget) {
    final raw =
        sqrt(shutter.seconds * (iso.value / 100.0) * pow(2, evTarget));
    return FStop(raw.clamp(0.7, 64));
  }

  /// Total EV from a given set of exposure parameters.
  double computeEv(FStop aperture, ShutterSpeed shutter, IsoValue iso) {
    // EV = log2(A²/S) - log2(ISO/100)
    return (2 * log(aperture.value) / ln2) -
        (log(shutter.seconds) / ln2) -
        (log(iso.value / 100.0) / ln2);
  }
}
