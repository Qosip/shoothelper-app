import '../../../../../shared/domain/enums/shooting_enums.dart';
import '../../../../../shared/domain/entities/settings_result.dart';
import '../../entities/engine_context.dart';

/// White balance decision tree — Skill 06 §4.4.
class WbResolver {
  const WbResolver();

  SettingRecommendation resolve(EngineContext ctx, {String? fileFormat}) {
    final scene = ctx.scene;

    // Level 3 override
    if (scene.wbOverride != null) {
      return SettingRecommendation(
        settingId: 'white_balance',
        value: scene.wbOverride,
        valueDisplay: _displayOverride(scene.wbOverride!),
        explanationShort: 'Balance des blancs définie manuellement.',
        isOverride: true,
      );
    }

    // If shooting RAW, auto WB is fine
    final format = fileFormat ?? 'raw';
    if (format == 'raw' || format == 'raw+jpeg') {
      return const SettingRecommendation(
        settingId: 'white_balance',
        value: WbPreset.auto,
        valueDisplay: 'Auto',
        explanationShort:
            'En RAW, la balance des blancs est modifiable en post-traitement sans perte. Auto WB suffit.',
      );
    }

    // JPEG: map light condition to preset
    if (scene.lightCondition != null) {
      final (preset, display, kelvin) = _fromLight(scene.lightCondition!);
      return SettingRecommendation(
        settingId: 'white_balance',
        value: preset,
        valueDisplay: '$display (~${kelvin}K)',
        explanationShort: 'Balance des blancs adaptée à la condition de lumière : $display.',
      );
    }

    return const SettingRecommendation(
      settingId: 'white_balance',
      value: WbPreset.auto,
      valueDisplay: 'Auto',
      explanationShort: 'Auto WB par défaut.',
    );
  }

  (WbPreset, String, int) _fromLight(LightCondition lc) {
    switch (lc) {
      case LightCondition.directSun:
        return (WbPreset.daylight, 'Lumière du jour', 5200);
      case LightCondition.shade:
        return (WbPreset.shade, 'Ombre', 7000);
      case LightCondition.overcast:
        return (WbPreset.cloudy, 'Nuageux', 6000);
      case LightCondition.goldenHour:
        return (WbPreset.daylight, 'Lumière du jour', 5000);
      case LightCondition.blueHour:
        return (WbPreset.auto, 'Auto', 4000);
      case LightCondition.starryNight:
        return (WbPreset.auto, '3800K', 3800);
      case LightCondition.tungsten:
        return (WbPreset.tungsten, 'Tungstène', 3200);
      case LightCondition.neon:
        return (WbPreset.fluorescent, 'Fluorescent', 4000);
      case LightCondition.led:
        return (WbPreset.auto, 'Auto', 5000);
    }
  }

  String _displayOverride(WbOverride o) {
    switch (o) {
      case WbOverride.auto: return 'Auto';
      case WbOverride.daylight: return 'Lumière du jour';
      case WbOverride.shade: return 'Ombre';
      case WbOverride.cloudy: return 'Nuageux';
      case WbOverride.tungsten: return 'Tungstène';
      case WbOverride.fluorescent: return 'Fluorescent';
      case WbOverride.flash: return 'Flash';
    }
  }
}
