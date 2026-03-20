import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A single gear profile: body + lenses + language + custom name.
class GearProfileData {
  final String id;
  final String name;
  final String bodyId;
  final List<String> lensIds;
  final String activeLensId;
  final String language;

  const GearProfileData({
    required this.id,
    required this.name,
    required this.bodyId,
    required this.lensIds,
    required this.activeLensId,
    required this.language,
  });

  GearProfileData copyWith({
    String? name,
    String? bodyId,
    List<String>? lensIds,
    String? activeLensId,
    String? language,
  }) =>
      GearProfileData(
        id: id,
        name: name ?? this.name,
        bodyId: bodyId ?? this.bodyId,
        lensIds: lensIds ?? this.lensIds,
        activeLensId: activeLensId ?? this.activeLensId,
        language: language ?? this.language,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'body_id': bodyId,
        'lens_ids': lensIds,
        'active_lens_id': activeLensId,
        'language': language,
      };

  factory GearProfileData.fromJson(Map<String, dynamic> json) =>
      GearProfileData(
        id: json['id'] as String,
        name: json['name'] as String,
        bodyId: json['body_id'] as String,
        lensIds: (json['lens_ids'] as List).cast<String>(),
        activeLensId: json['active_lens_id'] as String,
        language: json['language'] as String? ?? 'fr',
      );
}

/// Multi-profile storage backed by SharedPreferences (JSON-encoded list).
class GearProfileStore {
  static const _keyProfiles = 'gear_profiles';
  static const _keyActiveProfileId = 'gear_active_profile_id';

  final SharedPreferences _prefs;

  GearProfileStore(this._prefs);

  List<GearProfileData> get profiles {
    final raw = _prefs.getString(_keyProfiles);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => GearProfileData.fromJson(e as Map<String, dynamic>)).toList();
  }

  String? get activeProfileId => _prefs.getString(_keyActiveProfileId);

  GearProfileData? get activeProfile {
    final id = activeProfileId;
    if (id == null) return null;
    final all = profiles;
    return all.where((p) => p.id == id).firstOrNull;
  }

  Future<void> saveProfile(GearProfileData profile) async {
    final all = profiles.where((p) => p.id != profile.id).toList();
    all.add(profile);
    await _saveAll(all);
  }

  Future<void> deleteProfile(String profileId) async {
    final all = profiles.where((p) => p.id != profileId).toList();
    await _saveAll(all);
    if (activeProfileId == profileId && all.isNotEmpty) {
      await setActiveProfile(all.first.id);
    }
  }

  Future<void> setActiveProfile(String profileId) async {
    await _prefs.setString(_keyActiveProfileId, profileId);
  }

  Future<void> _saveAll(List<GearProfileData> all) async {
    await _prefs.setString(
      _keyProfiles,
      jsonEncode(all.map((p) => p.toJson()).toList()),
    );
  }

  /// Migrate from old single-profile GearProfileSource to multi-profile store.
  Future<GearProfileData?> migrateFromLegacy() async {
    final bodyId = _prefs.getString('gear_body_id');
    if (bodyId == null) return null;
    // Already migrated?
    if (profiles.isNotEmpty) return activeProfile;

    final lensIds = _prefs.getStringList('gear_lens_ids') ?? [];
    final activeLensId =
        _prefs.getString('gear_active_lens_id') ?? (lensIds.isNotEmpty ? lensIds.first : '');
    final language = _prefs.getString('gear_language') ?? 'fr';

    final profile = GearProfileData(
      id: 'default',
      name: 'Mon kit',
      bodyId: bodyId,
      lensIds: lensIds,
      activeLensId: activeLensId,
      language: language,
    );

    await saveProfile(profile);
    await setActiveProfile(profile.id);
    return profile;
  }
}
