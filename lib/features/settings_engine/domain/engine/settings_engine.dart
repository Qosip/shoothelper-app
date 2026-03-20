import '../../../../shared/domain/entities/body_spec.dart';
import '../../../../shared/domain/entities/lens_spec.dart';
import '../../../../shared/domain/entities/scene_input.dart';
import '../../../../shared/domain/entities/settings_result.dart';
import '../../../../shared/domain/enums/shooting_enums.dart';
import 'alternative_generator.dart';
import 'compromise_detector.dart';
import 'context_builder.dart';
import 'explanation_generator.dart';
import 'resolvers/af_area_resolver.dart';
import 'resolvers/af_mode_resolver.dart';
import 'resolvers/drive_resolver.dart';
import 'resolvers/exposure_mode_resolver.dart';
import 'resolvers/exposure_triangle_resolver.dart';
import 'resolvers/file_format_resolver.dart';
import 'resolvers/metering_resolver.dart';
import 'resolvers/stabilization_resolver.dart';
import 'resolvers/wb_resolver.dart';

/// Main orchestrator for the settings engine.
/// Runs the 4-phase pipeline described in Skill 06 §2.1.
class SettingsEngine {
  final ContextBuilder _contextBuilder;
  final AfModeResolver _afMode;
  final AfAreaResolver _afArea;
  final MeteringResolver _metering;
  final WbResolver _wb;
  final DriveResolver _drive;
  final StabilizationResolver _stabilization;
  final FileFormatResolver _fileFormat;
  final ExposureModeResolver _exposureMode;
  final ExposureTriangleResolver _triangle;
  final CompromiseDetector _compromises;
  final AlternativeGenerator _alternatives;
  final ExplanationGenerator _explanations;

  const SettingsEngine({
    ContextBuilder contextBuilder = const ContextBuilder(),
    AfModeResolver afMode = const AfModeResolver(),
    AfAreaResolver afArea = const AfAreaResolver(),
    MeteringResolver metering = const MeteringResolver(),
    WbResolver wb = const WbResolver(),
    DriveResolver drive = const DriveResolver(),
    StabilizationResolver stabilization = const StabilizationResolver(),
    FileFormatResolver fileFormat = const FileFormatResolver(),
    ExposureModeResolver exposureMode = const ExposureModeResolver(),
    ExposureTriangleResolver triangle = const ExposureTriangleResolver(),
    CompromiseDetector compromises = const CompromiseDetector(),
    AlternativeGenerator alternatives = const AlternativeGenerator(),
    ExplanationGenerator explanations = const ExplanationGenerator(),
  })  : _contextBuilder = contextBuilder,
        _afMode = afMode,
        _afArea = afArea,
        _metering = metering,
        _wb = wb,
        _drive = drive,
        _stabilization = stabilization,
        _fileFormat = fileFormat,
        _exposureMode = exposureMode,
        _triangle = triangle,
        _compromises = compromises,
        _alternatives = alternatives,
        _explanations = explanations;

  SettingsResult calculate(
    BodySpec body,
    LensSpec lens,
    SceneInput scene, {
    double filterLightLossStops = 0,
  }) {
    // Phase 1: Build context (focal, EV, min shutter, etc.)
    final ctx = _contextBuilder.build(body, lens, scene,
        filterLightLossStops: filterLightLossStops);

    // Phase 2: Independent settings
    final afModeSetting = _afMode.resolve(ctx);
    final afAreaSetting = _afArea.resolve(ctx);
    final meteringSetting = _metering.resolve(ctx);
    final fileFormatSetting = _fileFormat.resolve(ctx);
    final format = _fileFormat.formatValue(ctx);
    final wbSetting = _wb.resolve(ctx, fileFormat: format);
    final driveSetting = _drive.resolve(ctx);
    final stabSetting = _stabilization.resolve(ctx);
    final expModeSetting = _exposureMode.resolve(ctx);

    // Phase 3: Exposure triangle
    final triangleResult = _triangle.resolve(ctx);

    // Phase 4: Additional compromises
    final allCompromises = _compromises.detect(
      ctx: ctx,
      aperture: triangleResult.aperture,
      shutter: triangleResult.shutter,
      iso: triangleResult.iso,
      existingCompromises: triangleResult.compromises,
    );

    // Generate alternatives for exposure settings
    final isoAlts = _alternatives.isoAlternatives(
      ctx: ctx,
      aperture: triangleResult.aperture,
      shutter: triangleResult.shutter,
      iso: triangleResult.iso,
    );
    final apAlts = _alternatives.apertureAlternatives(
      ctx: ctx,
      aperture: triangleResult.aperture,
      shutter: triangleResult.shutter,
      iso: triangleResult.iso,
    );

    // Build exposure settings with explanations
    final apertureSetting = SettingRecommendation(
      settingId: 'aperture',
      value: triangleResult.aperture.value,
      valueDisplay: triangleResult.aperture.display,
      explanationShort:
          _explanations.apertureShort(ctx, triangleResult.aperture),
      explanationDetail:
          _explanations.apertureDetail(ctx, triangleResult.aperture),
      isCompromised: allCompromises.any(
          (c) => c.affectedSettings.contains('aperture')),
      alternatives: apAlts,
    );

    final shutterSetting = SettingRecommendation(
      settingId: 'shutter_speed',
      value: triangleResult.shutter.seconds,
      valueDisplay: triangleResult.shutter.display,
      explanationShort:
          _explanations.shutterShort(ctx, triangleResult.shutter),
      isCompromised: allCompromises.any(
          (c) => c.affectedSettings.contains('shutter_speed')),
    );

    final isoSetting = SettingRecommendation(
      settingId: 'iso',
      value: triangleResult.iso.value,
      valueDisplay: triangleResult.iso.display,
      explanationShort: _explanations.isoShort(ctx, triangleResult.iso),
      isCompromised:
          allCompromises.any((c) => c.affectedSettings.contains('iso')),
      alternatives: isoAlts,
    );

    // Confidence score (Skill 06 §11)
    final confidence = _computeConfidence(scene, allCompromises);

    // Scene summary
    final summary = _buildSummary(ctx);

    return SettingsResult(
      settings: [
        expModeSetting,
        apertureSetting,
        shutterSetting,
        isoSetting,
        afModeSetting,
        afAreaSetting,
        meteringSetting,
        wbSetting,
        fileFormatSetting,
        stabSetting,
        driveSetting,
      ],
      compromises: allCompromises,
      sceneSummary: summary,
      confidence: confidence,
    );
  }

  Confidence _computeConfidence(
      SceneInput scene, List<Compromise> compromises) {
    if (compromises.any((c) => c.severity == CompromiseSeverity.critical)) {
      return Confidence.low;
    }
    if (compromises.any((c) => c.severity == CompromiseSeverity.warning)) {
      return Confidence.medium;
    }

    // No level 2 info → medium
    final hasLevel2 = scene.lightCondition != null ||
        scene.subjectMotion != null ||
        scene.subjectDistance != null ||
        scene.mood != null ||
        scene.support != null;
    if (!hasLevel2) return Confidence.medium;

    return Confidence.high;
  }

  String _buildSummary(dynamic ctx) {
    final scene = ctx.scene as SceneInput;
    final subjectLabel = scene.subject.name;
    final envLabel = scene.environment.name;
    final intentionLabel = scene.intention.name;
    return '$subjectLabel en $envLabel, intention $intentionLabel';
  }
}
