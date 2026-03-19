/// Lens specifications used by the Settings Engine.
/// Skill 04 §3.5 LensSpec.
class LensSpec {
  final String id;
  final String brandId;
  final String name;
  final String displayName;
  final LensType type;

  final FocalLengthSpec focalLength;
  final ApertureSpec aperture;
  final LensFocusSpec focus;
  final LensStabilizationSpec stabilization;

  const LensSpec({
    required this.id,
    required this.brandId,
    required this.name,
    required this.displayName,
    required this.type,
    required this.focalLength,
    required this.aperture,
    required this.focus,
    required this.stabilization,
  });
}

enum LensType { prime, zoom, macro, superTelephoto }

class FocalLengthSpec {
  final int minMm;
  final int maxMm;

  const FocalLengthSpec({required this.minMm, required this.maxMm});

  bool get isZoom => minMm != maxMm;
  bool get isPrime => minMm == maxMm;
}

class ApertureSpec {
  final bool isConstant;
  final double maxAperture; // widest (smallest f-number)
  final double minAperture; // narrowest (largest f-number)
  final List<VariableAperturePoint>? variableApertureMap;

  const ApertureSpec({
    required this.isConstant,
    required this.maxAperture,
    required this.minAperture,
    this.variableApertureMap,
  });

  /// Get the max aperture at a given focal length (for variable aperture zooms).
  double maxApertureAtFocal(int focalMm) {
    if (isConstant || variableApertureMap == null) return maxAperture;
    final map = variableApertureMap!;
    if (map.isEmpty) return maxAperture;

    // Exact match
    for (final point in map) {
      if (point.focalMm == focalMm) return point.maxAperture;
    }

    // Clamp
    if (focalMm <= map.first.focalMm) return map.first.maxAperture;
    if (focalMm >= map.last.focalMm) return map.last.maxAperture;

    // Linear interpolation
    for (int i = 0; i < map.length - 1; i++) {
      if (focalMm >= map[i].focalMm && focalMm <= map[i + 1].focalMm) {
        final t = (focalMm - map[i].focalMm) /
            (map[i + 1].focalMm - map[i].focalMm);
        return map[i].maxAperture +
            t * (map[i + 1].maxAperture - map[i].maxAperture);
      }
    }
    return maxAperture;
  }
}

class VariableAperturePoint {
  final int focalMm;
  final double maxAperture;

  const VariableAperturePoint({
    required this.focalMm,
    required this.maxAperture,
  });
}

class LensFocusSpec {
  final double minFocusDistanceM;
  final bool hasAutofocus;

  const LensFocusSpec({
    required this.minFocusDistanceM,
    this.hasAutofocus = true,
  });
}

class LensStabilizationSpec {
  final bool hasOis;
  final double oisStops;

  const LensStabilizationSpec({
    this.hasOis = false,
    this.oisStops = 0,
  });
}
