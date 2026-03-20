import '../../domain/entities/body_spec.dart';
import '../../domain/enums/shooting_enums.dart';
import '../models/body_model.dart';

/// Maps BodyModel (JSON) → BodySpec (domain entity).
class BodyMapper {
  static BodySpec toEntity(BodyModel model) {
    return BodySpec(
      id: model.id,
      brandId: model.brandId,
      name: model.name,
      displayName: model.displayName,
      sensorSize: _parseSensorSize(model.sensorSize),
      cropFactor: model.cropFactor,
      supportLevel: _parseSupportLevel(model.supportLevel),
      sensor: _mapSensor(model.spec.sensor),
      shutter: _mapShutter(model.spec.shutter),
      autofocus: _mapAutofocus(model.spec.autofocus),
      metering: MeteringSpec(modes: model.spec.metering.modes),
      exposure: _mapExposure(model.spec.exposure),
      stabilization: _mapStabilization(model.spec.stabilization),
      drive: _mapDrive(model.spec.drive),
      photoFormats: model.spec.fileFormats.photo,
    );
  }

  static SupportLevel _parseSupportLevel(String value) {
    return value == 'basic' ? SupportLevel.basic : SupportLevel.full;
  }

  static SensorSize _parseSensorSize(String value) {
    switch (value) {
      case 'aps-c':
        return SensorSize.apsc;
      case 'full-frame':
        return SensorSize.fullFrame;
      case 'micro-four-thirds':
        return SensorSize.microFourThirds;
      default:
        return SensorSize.apsc;
    }
  }

  static SensorSpec _mapSensor(SensorSpecModel m) {
    return SensorSpec(
      megapixels: m.megapixels,
      isoMin: m.isoRange.min,
      isoMax: m.isoRange.max,
      isoExtendedMin: m.isoExtendedRange.min,
      isoExtendedMax: m.isoExtendedRange.max,
      isoUsableMax: m.isoUsableMax,
      dynamicRangeEv: m.dynamicRangeEv,
      sensorWidthMm: m.sensorWidthMm,
      sensorHeightMm: m.sensorHeightMm,
    );
  }

  static ShutterSpec _mapShutter(ShutterSpecModel m) {
    return ShutterSpec(
      mechanicalMinSeconds: m.mechanicalMinSeconds,
      mechanicalMaxSeconds: m.mechanicalMaxSeconds,
      hasBulb: m.hasBulb,
      electronicMinSeconds: m.electronicMinSeconds,
      electronicMaxSeconds: m.electronicMaxSeconds,
      flashSyncSpeed: m.flashSyncSpeed,
    );
  }

  static AutofocusSpec _mapAutofocus(AutofocusSpecModel m) {
    return AutofocusSpec(
      modes: m.modes,
      areas: m.areas,
      hasEyeAf: m.hasEyeAf,
      subjectDetection: m.subjectDetection,
      points: m.points,
    );
  }

  static ExposureSpec _mapExposure(ExposureSpecModel m) {
    return ExposureSpec(
      modes: m.modes,
      compensationMin: m.compensationRange.min,
      compensationMax: m.compensationRange.max,
      compensationStep: m.compensationRange.step,
    );
  }

  static StabilizationSpec _mapStabilization(StabilizationSpecModel m) {
    return StabilizationSpec(
      hasIbis: m.hasIbis,
      ibisStops: m.ibisStops ?? 0,
    );
  }

  static DriveSpec _mapDrive(DriveSpecModel m) {
    return DriveSpec(
      modes: m.modes,
      continuousFpsHi: m.continuousFpsHi,
      continuousFpsMid: m.continuousFpsMid,
      continuousFpsLo: m.continuousFpsLo,
    );
  }
}
