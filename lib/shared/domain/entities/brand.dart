/// Camera brand.
class Brand {
  final String id;
  final String name;

  const Brand({required this.id, required this.name});
}

/// Lens mount system.
class Mount {
  final String id;
  final String brandId;
  final String name;
  final List<String> coversSensorSizes;

  const Mount({
    required this.id,
    required this.brandId,
    required this.name,
    required this.coversSensorSizes,
  });
}
