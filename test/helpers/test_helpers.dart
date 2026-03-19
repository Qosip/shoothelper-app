import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shoothelper/shared/domain/entities/body_spec.dart';
import 'package:shoothelper/shared/domain/entities/lens_spec.dart';
import 'package:shoothelper/shared/domain/entities/settings_result.dart';
import 'package:shoothelper/shared/domain/enums/shooting_enums.dart';

/// Test body spec for Sony A6700 (simplified).
BodySpec testBody() => const BodySpec(
      id: 'sony_a6700',
      brandId: 'sony',
      name: 'Sony A6700',
      displayName: 'Sony α6700',
      sensorSize: SensorSize.apsc,
      cropFactor: 1.5,
      sensor: SensorSpec(
        megapixels: 26.0,
        isoMin: 100,
        isoMax: 32000,
        isoUsableMax: 6400,
        sensorWidthMm: 23.5,
        sensorHeightMm: 15.6,
      ),
      shutter: ShutterSpec(
        mechanicalMinSeconds: 1 / 4000,
        mechanicalMaxSeconds: 30,
        electronicMinSeconds: 1 / 8000,
        electronicMaxSeconds: 30,
        flashSyncSpeed: '1/160',
      ),
      autofocus: AutofocusSpec(
        modes: ['af-s', 'af-c', 'dmf', 'mf'],
        areas: ['wide', 'zone', 'center', 'spot', 'tracking'],
        hasEyeAf: true,
      ),
      metering: MeteringSpec(modes: ['multi', 'center', 'spot', 'highlight']),
      exposure: ExposureSpec(modes: ['p', 'a', 's', 'm']),
      stabilization: StabilizationSpec(hasIbis: true, ibisStops: 5),
      drive: DriveSpec(modes: ['single', 'continuous_hi', 'continuous_lo']),
      photoFormats: ['raw', 'jpeg', 'raw+jpeg'],
    );

/// Test lens spec for Sigma 18-50mm f/2.8.
LensSpec testLens() => const LensSpec(
      id: 'sigma_18-50_f2.8',
      brandId: 'sigma',
      name: 'Sigma 18-50mm f/2.8 DC DN',
      displayName: 'Sigma 18-50mm f/2.8',
      type: LensType.zoom,
      focalLength: FocalLengthSpec(minMm: 18, maxMm: 50),
      aperture: ApertureSpec(
        isConstant: true,
        maxAperture: 2.8,
        minAperture: 22,
      ),
      focus: LensFocusSpec(minFocusDistanceM: 0.125),
      stabilization: LensStabilizationSpec(),
    );

/// Test settings result with typical portrait settings.
SettingsResult testResult() => const SettingsResult(
      settings: [
        SettingRecommendation(
          settingId: 'aperture',
          value: 2.8,
          valueDisplay: 'f/2.8',
          explanationShort: 'Grande ouverture pour bokeh',
        ),
        SettingRecommendation(
          settingId: 'shutter_speed',
          value: '1/200',
          valueDisplay: '1/200s',
          explanationShort: 'Assez rapide pour le portrait',
        ),
        SettingRecommendation(
          settingId: 'iso',
          value: 400,
          valueDisplay: 'ISO 400',
          explanationShort: 'Bon compromis bruit/lumière',
        ),
        SettingRecommendation(
          settingId: 'exposure_mode',
          value: 'a',
          valueDisplay: 'A',
          explanationShort: 'Priorité ouverture',
        ),
        SettingRecommendation(
          settingId: 'af_mode',
          value: 'af-c',
          valueDisplay: 'AF-C',
          explanationShort: 'Suivi continu du sujet',
          explanationDetail:
              'Le mode AF-C maintient la mise au point sur un sujet en mouvement.',
          alternatives: [
            Alternative(
              value: 'af-s',
              valueDisplay: 'AF-S',
              tradeOff: 'Plus précis sur sujet immobile',
            ),
          ],
        ),
        SettingRecommendation(
          settingId: 'af_area',
          value: 'wide',
          valueDisplay: 'Large',
          explanationShort: 'Couverture maximale',
        ),
        SettingRecommendation(
          settingId: 'metering',
          value: 'multi',
          valueDisplay: 'Multi',
          explanationShort: 'Mesure matricielle',
        ),
        SettingRecommendation(
          settingId: 'white_balance',
          value: 'auto',
          valueDisplay: 'Auto',
          explanationShort: 'AWB fiable en extérieur',
        ),
        SettingRecommendation(
          settingId: 'drive',
          value: 'single',
          valueDisplay: 'Single',
          explanationShort: 'Une photo à la fois',
        ),
        SettingRecommendation(
          settingId: 'stabilization',
          value: 'on',
          valueDisplay: 'On',
          explanationShort: 'IBIS activé',
        ),
        SettingRecommendation(
          settingId: 'file_format',
          value: 'raw',
          valueDisplay: 'RAW',
          explanationShort: 'Maximum de latitude',
        ),
      ],
      compromises: [
        Compromise(
          type: CompromiseType.noise,
          severity: CompromiseSeverity.info,
          message: 'ISO 400 peut introduire un léger bruit',
          suggestion: 'Ajouter de la lumière si possible',
        ),
      ],
      sceneSummary: 'Portrait en extérieur jour, bokeh',
      confidence: Confidence.high,
    );

/// Wraps a widget in MaterialApp.router with GoRouter for testing.
Widget testableWidget(Widget child, {List<Override>? overrides}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => child),
    ],
  );

  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}
