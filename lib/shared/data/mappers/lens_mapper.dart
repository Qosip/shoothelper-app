import '../../domain/entities/lens_spec.dart';
import '../models/lens_model.dart';

/// Maps LensModel (JSON) → LensSpec (domain entity).
class LensMapper {
  static LensSpec toEntity(LensModel model) {
    return LensSpec(
      id: model.id,
      brandId: model.brandId,
      name: model.name,
      displayName: model.displayName,
      type: _parseLensType(model.type),
      focalLength: FocalLengthSpec(
        minMm: model.spec.focalLength.minMm,
        maxMm: model.spec.focalLength.maxMm,
      ),
      aperture: _mapAperture(model.spec.aperture),
      focus: LensFocusSpec(
        minFocusDistanceM: model.spec.focus.minFocusDistanceM,
        hasAutofocus: model.spec.focus.autofocus,
      ),
      stabilization: LensStabilizationSpec(
        hasOis: model.spec.stabilization.hasOis,
        oisStops: model.spec.stabilization.oisStops ?? 0,
      ),
    );
  }

  static LensType _parseLensType(String value) {
    switch (value) {
      case 'prime':
        return LensType.prime;
      case 'zoom':
        return LensType.zoom;
      case 'macro':
        return LensType.macro;
      case 'super-telephoto':
        return LensType.superTelephoto;
      default:
        return LensType.zoom;
    }
  }

  static ApertureSpec _mapAperture(ApertureModel m) {
    return ApertureSpec(
      isConstant: m.type == 'constant',
      maxAperture: m.maxAperture,
      minAperture: m.minAperture,
      variableApertureMap: m.variableApertureMap
          ?.map((p) => VariableAperturePoint(
                focalMm: p.focalMm,
                maxAperture: p.maxAperture,
              ))
          .toList(),
    );
  }
}
