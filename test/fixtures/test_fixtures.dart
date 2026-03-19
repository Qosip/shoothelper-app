// Test fixtures: Sony A6700 + Sigma 18-50mm f/2.8
// Based on Skill 04 §3.4 and §3.5 reference data.

import 'package:shoothelper/shared/domain/entities/body_spec.dart';
import 'package:shoothelper/shared/domain/entities/lens_spec.dart';
import 'package:shoothelper/shared/domain/enums/shooting_enums.dart';

/// Sony A6700 body spec for testing.
final sonyA6700 = BodySpec(
  id: 'sony_a6700',
  brandId: 'sony',
  name: 'Sony A6700',
  displayName: 'A6700',
  sensorSize: SensorSize.apsc,
  cropFactor: 1.5,
  sensor: const SensorSpec(
    megapixels: 26.0,
    isoMin: 100,
    isoMax: 32000,
    isoExtendedMin: 50,
    isoExtendedMax: 102400,
    isoUsableMax: 6400,
    dynamicRangeEv: 14.0,
    sensorWidthMm: 23.5,
    sensorHeightMm: 15.6,
  ),
  shutter: const ShutterSpec(
    mechanicalMinSeconds: 1 / 4000,
    mechanicalMaxSeconds: 30,
    hasBulb: true,
    electronicMinSeconds: 1 / 8000,
    electronicMaxSeconds: 30,
    flashSyncSpeed: '1/160',
  ),
  autofocus: const AutofocusSpec(
    modes: ['af-s', 'af-c', 'dmf', 'mf'],
    areas: ['wide', 'zone', 'center', 'spot', 'expanded-spot', 'tracking'],
    hasEyeAf: true,
    subjectDetection: [
      'human_eye', 'human_face', 'animal_eye', 'animal', 'bird', 'vehicle',
    ],
    points: 759,
  ),
  metering: const MeteringSpec(
    modes: ['multi', 'center', 'spot', 'highlight'],
  ),
  exposure: const ExposureSpec(
    modes: ['P', 'A', 'S', 'M'],
    compensationMin: -5.0,
    compensationMax: 5.0,
    compensationStep: 0.3,
  ),
  stabilization: const StabilizationSpec(
    hasIbis: true,
    ibisStops: 5.0,
  ),
  drive: const DriveSpec(
    modes: [
      'single', 'continuous-hi', 'continuous-mid', 'continuous-lo',
      'self-timer', 'bracket',
    ],
    continuousFpsHi: 11.0,
    continuousFpsMid: 6.0,
    continuousFpsLo: 3.0,
  ),
  photoFormats: ['raw', 'jpeg', 'raw+jpeg'],
);

/// Sigma 18-50mm f/2.8 DC DN lens spec for testing.
final sigma1850f28 = LensSpec(
  id: 'sigma_18-50_f2.8_dc_dn_c',
  brandId: 'sigma',
  name: 'Sigma 18-50mm f/2.8 DC DN | Contemporary',
  displayName: 'Sigma 18-50mm f/2.8',
  type: LensType.zoom,
  focalLength: const FocalLengthSpec(minMm: 18, maxMm: 50),
  aperture: const ApertureSpec(
    isConstant: true,
    maxAperture: 2.8,
    minAperture: 22,
  ),
  focus: const LensFocusSpec(
    minFocusDistanceM: 0.125,
    hasAutofocus: true,
  ),
  stabilization: const LensStabilizationSpec(
    hasOis: false,
    oisStops: 0,
  ),
);
