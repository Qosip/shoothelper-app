import 'package:shared_preferences/shared_preferences.dart';

/// Persists gear selection (body, lens, language) in SharedPreferences.
class GearProfileSource {
  static const _keyBodyId = 'gear_body_id';
  static const _keyLensIds = 'gear_lens_ids';
  static const _keyActiveLensId = 'gear_active_lens_id';
  static const _keyLanguage = 'gear_language';
  static const _keyOnboardingComplete = 'onboarding_complete';

  final SharedPreferences _prefs;

  GearProfileSource(this._prefs);

  bool get isOnboardingComplete =>
      _prefs.getBool(_keyOnboardingComplete) ?? false;

  String? get bodyId => _prefs.getString(_keyBodyId);
  List<String> get lensIds => _prefs.getStringList(_keyLensIds) ?? [];
  String? get activeLensId => _prefs.getString(_keyActiveLensId);
  String get language => _prefs.getString(_keyLanguage) ?? 'fr';

  Future<void> saveOnboarding({
    required String bodyId,
    required List<String> lensIds,
    required String language,
  }) async {
    await _prefs.setString(_keyBodyId, bodyId);
    await _prefs.setStringList(_keyLensIds, lensIds);
    if (lensIds.isNotEmpty) {
      await _prefs.setString(_keyActiveLensId, lensIds.first);
    }
    await _prefs.setString(_keyLanguage, language);
    await _prefs.setBool(_keyOnboardingComplete, true);
  }

  Future<void> setActiveLens(String lensId) async {
    await _prefs.setString(_keyActiveLensId, lensId);
  }

  Future<void> addLens(String lensId) async {
    final ids = [...lensIds];
    if (!ids.contains(lensId)) {
      ids.add(lensId);
      await _prefs.setStringList(_keyLensIds, ids);
    }
  }

  Future<void> removeLens(String lensId) async {
    final ids = [...lensIds]..remove(lensId);
    await _prefs.setStringList(_keyLensIds, ids);
    // If active lens was removed, switch to first available
    if (activeLensId == lensId && ids.isNotEmpty) {
      await _prefs.setString(_keyActiveLensId, ids.first);
    }
  }

  Future<void> setBody(String newBodyId) async {
    await _prefs.setString(_keyBodyId, newBodyId);
  }

  Future<void> setLanguage(String lang) async {
    await _prefs.setString(_keyLanguage, lang);
  }

  Future<void> clear() async {
    await _prefs.remove(_keyBodyId);
    await _prefs.remove(_keyLensIds);
    await _prefs.remove(_keyActiveLensId);
    await _prefs.remove(_keyLanguage);
    await _prefs.remove(_keyOnboardingComplete);
  }
}
