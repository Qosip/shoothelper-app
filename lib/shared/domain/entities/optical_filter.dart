/// Optical filter types that affect exposure calculations.
sealed class OpticalFilter {
  final String id;
  final String name;
  final int filterDiameterMm;

  const OpticalFilter({
    required this.id,
    required this.name,
    required this.filterDiameterMm,
  });

  /// Light loss in stops for this filter.
  double get lightLossStops;

  Map<String, dynamic> toJson();

  factory OpticalFilter.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'nd' => NdFilter(
          id: json['id'] as String,
          name: json['name'] as String,
          stops: json['stops'] as int,
          filterDiameterMm: json['filter_diameter_mm'] as int,
        ),
      'nd_variable' => NdVariableFilter(
          id: json['id'] as String,
          name: json['name'] as String,
          minStops: json['min_stops'] as int,
          maxStops: json['max_stops'] as int,
          filterDiameterMm: json['filter_diameter_mm'] as int,
        ),
      'cpl' => CplFilter(
          id: json['id'] as String,
          name: json['name'] as String,
          lightLoss: (json['light_loss_stops'] as num).toDouble(),
          filterDiameterMm: json['filter_diameter_mm'] as int,
        ),
      'uv' => UvFilter(
          id: json['id'] as String,
          name: json['name'] as String,
          filterDiameterMm: json['filter_diameter_mm'] as int,
        ),
      _ => throw ArgumentError('Unknown filter type: $type'),
    };
  }
}

class NdFilter extends OpticalFilter {
  final int stops;

  const NdFilter({
    required super.id,
    required super.name,
    required this.stops,
    required super.filterDiameterMm,
  });

  @override
  double get lightLossStops => stops.toDouble();

  @override
  Map<String, dynamic> toJson() => {
        'type': 'nd',
        'id': id,
        'name': name,
        'stops': stops,
        'filter_diameter_mm': filterDiameterMm,
      };
}

class NdVariableFilter extends OpticalFilter {
  final int minStops;
  final int maxStops;

  /// Currently selected stop value (within minStops..maxStops).
  final int? selectedStops;

  const NdVariableFilter({
    required super.id,
    required super.name,
    required this.minStops,
    required this.maxStops,
    required super.filterDiameterMm,
    this.selectedStops,
  });

  @override
  double get lightLossStops => (selectedStops ?? minStops).toDouble();

  NdVariableFilter withSelectedStops(int stops) => NdVariableFilter(
        id: id,
        name: name,
        minStops: minStops,
        maxStops: maxStops,
        filterDiameterMm: filterDiameterMm,
        selectedStops: stops.clamp(minStops, maxStops),
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'nd_variable',
        'id': id,
        'name': name,
        'min_stops': minStops,
        'max_stops': maxStops,
        'filter_diameter_mm': filterDiameterMm,
      };
}

class CplFilter extends OpticalFilter {
  final double lightLoss;

  const CplFilter({
    required super.id,
    required super.name,
    required this.lightLoss,
    required super.filterDiameterMm,
  });

  @override
  double get lightLossStops => lightLoss;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'cpl',
        'id': id,
        'name': name,
        'light_loss_stops': lightLoss,
        'filter_diameter_mm': filterDiameterMm,
      };
}

class UvFilter extends OpticalFilter {
  const UvFilter({
    required super.id,
    required super.name,
    required super.filterDiameterMm,
  });

  @override
  double get lightLossStops => 0;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'uv',
        'id': id,
        'name': name,
        'filter_diameter_mm': filterDiameterMm,
      };
}
