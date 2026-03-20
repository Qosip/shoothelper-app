import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/entities/optical_filter.dart';

/// Persists user's optical filters in SharedPreferences.
class FilterStore {
  static const _key = 'optical_filters';

  final SharedPreferences _prefs;

  FilterStore(this._prefs);

  List<OpticalFilter> get filters {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => OpticalFilter.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addFilter(OpticalFilter filter) async {
    final all = filters.where((f) => f.id != filter.id).toList();
    all.add(filter);
    await _saveAll(all);
  }

  Future<void> removeFilter(String filterId) async {
    final all = filters.where((f) => f.id != filterId).toList();
    await _saveAll(all);
  }

  Future<void> _saveAll(List<OpticalFilter> all) async {
    await _prefs.setString(
      _key,
      jsonEncode(all.map((f) => f.toJson()).toList()),
    );
  }
}
