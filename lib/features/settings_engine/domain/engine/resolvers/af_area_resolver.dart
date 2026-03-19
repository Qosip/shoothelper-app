import '../../../../../shared/domain/enums/shooting_enums.dart';
import '../../../../../shared/domain/entities/settings_result.dart';
import '../../entities/engine_context.dart';

/// AF area decision tree — Skill 06 §4.2.
class AfAreaResolver {
  const AfAreaResolver();

  SettingRecommendation resolve(EngineContext ctx) {
    final scene = ctx.scene;
    AfArea area;
    String explanation;

    // Level 3 override
    if (scene.afAreaOverride != null) {
      area = _fromOverride(scene.afAreaOverride!);
      explanation = 'Zone AF définie manuellement.';
      return _build(area, explanation, isOverride: true);
    }

    if (scene.subject == Subject.portrait && ctx.body.autofocus.hasEyeAf) {
      area = AfArea.eyeAf;
      explanation =
          'Eye-AF verrouille la mise au point sur l\'œil du sujet — '
          'idéal pour les portraits où la netteté de l\'œil est critique.';
    } else if ((scene.subject == Subject.sport ||
            scene.subject == Subject.wildlife) &&
        (scene.subjectMotion == SubjectMotion.fast ||
            scene.subjectMotion == SubjectMotion.veryFast)) {
      if (ctx.body.autofocus.areas.contains('tracking')) {
        area = AfArea.tracking;
        explanation =
            'Le suivi AF suit le sujet dans le cadre même s\'il se déplace rapidement.';
      } else {
        area = AfArea.wide;
        explanation = 'Zone large pour couvrir un maximum du cadre.';
      }
    } else if (scene.subject == Subject.landscape ||
        scene.subject == Subject.architecture) {
      area = AfArea.wide;
      explanation =
          'Pour les sujets statiques et les scènes larges, la zone large suffit.';
    } else if (scene.subject == Subject.macro) {
      area = AfArea.spot;
      explanation =
          'En macro, la zone de netteté est très fine. Un point AF précis te donne le contrôle exact.';
    } else if (scene.subject == Subject.street) {
      area = AfArea.wide;
      explanation =
          'En street, les sujets sont imprévisibles. Une zone large laisse l\'AF réagir rapidement.';
    } else {
      area = AfArea.wide;
      explanation = 'Zone large par défaut.';
    }

    return _build(area, explanation);
  }

  AfArea _fromOverride(AfAreaOverride o) {
    switch (o) {
      case AfAreaOverride.center: return AfArea.center;
      case AfAreaOverride.wide: return AfArea.wide;
      case AfAreaOverride.tracking: return AfArea.tracking;
      case AfAreaOverride.eyeAf: return AfArea.eyeAf;
    }
  }

  SettingRecommendation _build(AfArea area, String explanation,
      {bool isOverride = false}) {
    return SettingRecommendation(
      settingId: 'af_area',
      value: area,
      valueDisplay: _display(area),
      explanationShort: explanation,
      isOverride: isOverride,
    );
  }

  String _display(AfArea a) {
    switch (a) {
      case AfArea.wide: return 'Large';
      case AfArea.zone: return 'Zone';
      case AfArea.center: return 'Centre';
      case AfArea.spot: return 'Spot';
      case AfArea.expandedSpot: return 'Spot élargi';
      case AfArea.tracking: return 'Suivi';
      case AfArea.eyeAf: return 'Eye-AF';
    }
  }
}
