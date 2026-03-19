/// A body entry from catalog.json.
class CatalogBody {
  final String id;
  final String brandId;
  final String name;
  final String displayName;
  final String sensorSize;
  final String mount;
  final String packVersion;
  final int packSizeBytes;
  final List<String> languages;
  final List<CatalogLens> lenses;

  const CatalogBody({
    required this.id,
    required this.brandId,
    required this.name,
    required this.displayName,
    required this.sensorSize,
    required this.mount,
    required this.packVersion,
    required this.packSizeBytes,
    required this.languages,
    required this.lenses,
  });

  factory CatalogBody.fromJson(Map<String, dynamic> json) {
    return CatalogBody(
      id: json['id'] as String,
      brandId: json['brand_id'] as String,
      name: json['name'] as String,
      displayName: json['display_name'] as String,
      sensorSize: json['sensor_size'] as String,
      mount: json['mount'] as String,
      packVersion: json['pack_version'] as String,
      packSizeBytes: json['pack_size_bytes'] as int,
      languages: (json['languages'] as List).cast<String>(),
      lenses: (json['lenses'] as List)
          .map((l) => CatalogLens.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A lens entry from catalog.json.
class CatalogLens {
  final String id;
  final String brandId;
  final String name;
  final String displayName;
  final bool isKitLens;
  final int popularityRank;

  const CatalogLens({
    required this.id,
    required this.brandId,
    required this.name,
    required this.displayName,
    required this.isKitLens,
    required this.popularityRank,
  });

  factory CatalogLens.fromJson(Map<String, dynamic> json) {
    return CatalogLens(
      id: json['id'] as String,
      brandId: json['brand_id'] as String,
      name: json['name'] as String,
      displayName: json['display_name'] as String,
      isKitLens: json['is_kit_lens'] as bool? ?? false,
      popularityRank: json['popularity_rank'] as int? ?? 99,
    );
  }
}

/// Full catalog with all bodies.
class Catalog {
  final String version;
  final List<CatalogBody> bodies;

  const Catalog({required this.version, required this.bodies});

  factory Catalog.fromJson(Map<String, dynamic> json) {
    return Catalog(
      version: json['version'] as String,
      bodies: (json['bodies'] as List)
          .map((b) => CatalogBody.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }

  CatalogBody? findBody(String bodyId) {
    for (final b in bodies) {
      if (b.id == bodyId) return b;
    }
    return null;
  }
}
