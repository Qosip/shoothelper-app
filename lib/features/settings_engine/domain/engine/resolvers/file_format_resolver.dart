import '../../../../../shared/domain/enums/shooting_enums.dart';
import '../../../../../shared/domain/entities/settings_result.dart';
import '../../entities/engine_context.dart';

/// File format decision tree — Skill 06 §4.5.
class FileFormatResolver {
  const FileFormatResolver();

  SettingRecommendation resolve(EngineContext ctx) {
    final scene = ctx.scene;

    if (scene.fileFormatOverride != null) {
      return SettingRecommendation(
        settingId: 'file_format',
        value: _overrideToString(scene.fileFormatOverride!),
        valueDisplay: _overrideDisplay(scene.fileFormatOverride!),
        explanationShort: 'Format défini manuellement.',
        isOverride: true,
      );
    }

    // Astro: RAW mandatory
    if (scene.subject == Subject.astro) {
      return const SettingRecommendation(
        settingId: 'file_format',
        value: 'raw',
        valueDisplay: 'RAW',
        explanationShort:
            'RAW obligatoire en astrophoto pour le stacking et le traitement des hauts ISO.',
      );
    }

    return const SettingRecommendation(
      settingId: 'file_format',
      value: 'raw',
      valueDisplay: 'RAW',
      explanationShort:
          'RAW capture toute l\'information du capteur. Tu pourras ajuster l\'exposition, '
          'la balance des blancs et les couleurs en post-traitement sans perte.',
    );
  }

  String formatValue(EngineContext ctx) {
    if (ctx.scene.fileFormatOverride != null) {
      return _overrideToString(ctx.scene.fileFormatOverride!);
    }
    return 'raw';
  }

  String _overrideToString(FileFormatOverride o) {
    switch (o) {
      case FileFormatOverride.raw: return 'raw';
      case FileFormatOverride.jpeg: return 'jpeg';
      case FileFormatOverride.rawPlusJpeg: return 'raw+jpeg';
    }
  }

  String _overrideDisplay(FileFormatOverride o) {
    switch (o) {
      case FileFormatOverride.raw: return 'RAW';
      case FileFormatOverride.jpeg: return 'JPEG';
      case FileFormatOverride.rawPlusJpeg: return 'RAW+JPEG';
    }
  }
}
