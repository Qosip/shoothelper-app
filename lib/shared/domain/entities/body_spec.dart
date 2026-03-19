import '../enums/shooting_enums.dart';

/// Camera body specifications used by the Settings Engine.
/// Skill 04 §3.4 BodySpec — simplified for engine calculations.
class BodySpec {
  final String id;
  final String brandId;
  final String name;
  final String displayName;
  final SensorSize sensorSize;
  final double cropFactor;

  final SensorSpec sensor;
  final ShutterSpec shutter;
  final AutofocusSpec autofocus;
  final MeteringSpec metering;
  final ExposureSpec exposure;
  final StabilizationSpec stabilization;
  final DriveSpec drive;
  final List<String> photoFormats;

  const BodySpec({
    required this.id,
    required this.brandId,
    required this.name,
    required this.displayName,
    required this.sensorSize,
    required this.cropFactor,
    required this.sensor,
    required this.shutter,
    required this.autofocus,
    required this.metering,
    required this.exposure,
    required this.stabilization,
    required this.drive,
    required this.photoFormats,
  });
}

class SensorSpec {
  final double megapixels;
  final int isoMin;
  final int isoMax;
  final int isoExtendedMin;
  final int isoExtendedMax;
  final int isoUsableMax;
  final double dynamicRangeEv;
  final double sensorWidthMm;
  final double sensorHeightMm;

  const SensorSpec({
    required this.megapixels,
    required this.isoMin,
    required this.isoMax,
    this.isoExtendedMin = 50,
    this.isoExtendedMax = 102400,
    required this.isoUsableMax,
    this.dynamicRangeEv = 14.0,
    required this.sensorWidthMm,
    required this.sensorHeightMm,
  });
}

class ShutterSpec {
  final double mechanicalMinSeconds; // e.g. 1/4000 = 0.00025
  final double mechanicalMaxSeconds; // e.g. 30
  final bool hasBulb;
  final double electronicMinSeconds; // e.g. 1/8000
  final double electronicMaxSeconds;
  final String flashSyncSpeed; // e.g. "1/160"

  const ShutterSpec({
    required this.mechanicalMinSeconds,
    required this.mechanicalMaxSeconds,
    this.hasBulb = true,
    required this.electronicMinSeconds,
    required this.electronicMaxSeconds,
    required this.flashSyncSpeed,
  });
}

class AutofocusSpec {
  final List<String> modes; // ["af-s", "af-c", "dmf", "mf"]
  final List<String> areas; // ["wide", "zone", "center", "spot", "tracking"]
  final bool hasEyeAf;
  final List<String> subjectDetection;
  final int points;

  const AutofocusSpec({
    required this.modes,
    required this.areas,
    this.hasEyeAf = false,
    this.subjectDetection = const [],
    this.points = 0,
  });
}

class MeteringSpec {
  final List<String> modes; // ["multi", "center", "spot", "highlight"]

  const MeteringSpec({required this.modes});
}

class ExposureSpec {
  final List<String> modes; // ["P", "A", "S", "M"]
  final double compensationMin;
  final double compensationMax;
  final double compensationStep;

  const ExposureSpec({
    required this.modes,
    this.compensationMin = -5.0,
    this.compensationMax = 5.0,
    this.compensationStep = 0.3,
  });
}

class StabilizationSpec {
  final bool hasIbis;
  final double ibisStops;

  const StabilizationSpec({
    this.hasIbis = false,
    this.ibisStops = 0,
  });
}

class DriveSpec {
  final List<String> modes;
  final double continuousFpsHi;
  final double continuousFpsMid;
  final double continuousFpsLo;

  const DriveSpec({
    required this.modes,
    this.continuousFpsHi = 10,
    this.continuousFpsMid = 5,
    this.continuousFpsLo = 3,
  });
}
