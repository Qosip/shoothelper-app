import 'dart:math';

import '../../../../shared/domain/entities/settings_result.dart';
import '../../../../shared/domain/value_objects/f_stop.dart';
import '../../../../shared/domain/value_objects/iso_value.dart';
import '../../../../shared/domain/value_objects/shutter_speed.dart';
import '../entities/engine_context.dart';
import 'exposure_calculator.dart';

/// Generates 1-2 alternatives per exposure setting (±1 stop).
/// Skill 06 §6.3.
class AlternativeGenerator {
  final ExposureCalculator _calc;

  const AlternativeGenerator({
    ExposureCalculator calc = const ExposureCalculator(),
  }) : _calc = calc;

  List<Alternative> isoAlternatives({
    required EngineContext ctx,
    required FStop aperture,
    required ShutterSpeed shutter,
    required IsoValue iso,
  }) {
    final alts = <Alternative>[];

    // -1 stop ISO (less noise)
    final lowerIso = IsoValue((iso.value / 2).round()).toNearestStandard();
    if (lowerIso.value >= ctx.body.sensor.isoMin) {
      final newShutter = _calc.resolveShutter(aperture, lowerIso, ctx.evTarget);
      alts.add(Alternative(
        value: lowerIso.value,
        valueDisplay: lowerIso.display,
        tradeOff: 'Moins de bruit, mais vitesse plus lente (${newShutter.toNearestStandard().display})',
        cascadeChanges: [
          CascadeChange(
            settingId: 'shutter_speed',
            fromValue: shutter.display,
            toValue: newShutter.toNearestStandard().display,
            reason: 'Compensation -1 stop ISO',
          ),
        ],
      ));
    }

    // +1 stop ISO (faster shutter)
    final higherIso = IsoValue((iso.value * 2).round()).toNearestStandard();
    if (higherIso.value <= ctx.body.sensor.isoMax) {
      final newShutter =
          _calc.resolveShutter(aperture, higherIso, ctx.evTarget);
      alts.add(Alternative(
        value: higherIso.value,
        valueDisplay: higherIso.display,
        tradeOff: 'Plus de bruit, mais sujet figé plus net (${newShutter.toNearestStandard().display})',
        cascadeChanges: [
          CascadeChange(
            settingId: 'shutter_speed',
            fromValue: shutter.display,
            toValue: newShutter.toNearestStandard().display,
            reason: 'Compensation +1 stop ISO',
          ),
        ],
      ));
    }

    return alts;
  }

  List<Alternative> apertureAlternatives({
    required EngineContext ctx,
    required FStop aperture,
    required ShutterSpeed shutter,
    required IsoValue iso,
  }) {
    final alts = <Alternative>[];

    // Wider (+1 stop light, more bokeh)
    final wider = FStop(aperture.value / sqrt2).toNearestWider();
    if (wider.value >= ctx.maxApertureAtFocal.value) {
      final newIso = _calc.resolveIso(wider, shutter, ctx.evTarget).toNearestStandard();
      alts.add(Alternative(
        value: wider.value,
        valueDisplay: wider.display,
        tradeOff: 'Plus de flou d\'arrière-plan, ISO ${newIso.display}',
        cascadeChanges: [
          CascadeChange(
            settingId: 'iso',
            fromValue: iso.display,
            toValue: newIso.display,
            reason: 'Plus de lumière via ouverture',
          ),
        ],
      ));
    }

    // Narrower (-1 stop light, more DoF)
    final narrower = FStop(aperture.value * sqrt2).toNearestNarrower();
    if (narrower.value <= ctx.lens.aperture.minAperture) {
      final newIso = _calc.resolveIso(narrower, shutter, ctx.evTarget).toNearestStandard();
      alts.add(Alternative(
        value: narrower.value,
        valueDisplay: narrower.display,
        tradeOff: 'Plus de profondeur de champ, ISO ${newIso.display}',
        cascadeChanges: [
          CascadeChange(
            settingId: 'iso',
            fromValue: iso.display,
            toValue: newIso.display,
            reason: 'Moins de lumière via ouverture',
          ),
        ],
      ));
    }

    return alts;
  }
}
