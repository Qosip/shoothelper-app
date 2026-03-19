import '../../domain/entities/brand.dart';
import '../models/brand_model.dart';

/// Maps BrandModel/MountModel (JSON) → Brand/Mount (domain entities).
class BrandMapper {
  static Brand toEntity(BrandModel model) {
    return Brand(id: model.id, name: model.name);
  }
}

class MountMapper {
  static Mount toEntity(MountModel model) {
    return Mount(
      id: model.id,
      brandId: model.brandId,
      name: model.name,
      coversSensorSizes: model.coversSensorSizes,
    );
  }
}
