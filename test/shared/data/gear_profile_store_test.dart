import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoothelper/shared/data/data_sources/local/gear_profile_store.dart';

void main() {
  group('GearProfileStore', () {
    late SharedPreferences prefs;
    late GearProfileStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      store = GearProfileStore(prefs);
    });

    test('starts with no profiles', () {
      expect(store.profiles, isEmpty);
      expect(store.activeProfile, isNull);
    });

    test('saveProfile and retrieve', () async {
      final profile = GearProfileData(
        id: 'p1',
        name: 'Kit voyage',
        bodyId: 'sony_a6700',
        lensIds: ['sigma_18-50'],
        activeLensId: 'sigma_18-50',
        language: 'fr',
      );
      await store.saveProfile(profile);

      expect(store.profiles.length, 1);
      expect(store.profiles.first.name, 'Kit voyage');
    });

    test('setActiveProfile and activeProfile', () async {
      final p1 = GearProfileData(
        id: 'p1',
        name: 'Kit 1',
        bodyId: 'sony_a6700',
        lensIds: ['lens_a'],
        activeLensId: 'lens_a',
        language: 'fr',
      );
      final p2 = GearProfileData(
        id: 'p2',
        name: 'Kit 2',
        bodyId: 'canon_r50',
        lensIds: ['lens_b'],
        activeLensId: 'lens_b',
        language: 'en',
      );
      await store.saveProfile(p1);
      await store.saveProfile(p2);
      await store.setActiveProfile('p2');

      expect(store.activeProfileId, 'p2');
      expect(store.activeProfile?.name, 'Kit 2');
      expect(store.activeProfile?.bodyId, 'canon_r50');
    });

    test('deleteProfile removes and switches active', () async {
      final p1 = GearProfileData(
        id: 'p1',
        name: 'Kit 1',
        bodyId: 'sony_a6700',
        lensIds: ['lens_a'],
        activeLensId: 'lens_a',
        language: 'fr',
      );
      final p2 = GearProfileData(
        id: 'p2',
        name: 'Kit 2',
        bodyId: 'canon_r50',
        lensIds: ['lens_b'],
        activeLensId: 'lens_b',
        language: 'en',
      );
      await store.saveProfile(p1);
      await store.saveProfile(p2);
      await store.setActiveProfile('p1');
      await store.deleteProfile('p1');

      expect(store.profiles.length, 1);
      expect(store.activeProfileId, 'p2');
    });

    test('migrateFromLegacy creates profile from old keys', () async {
      SharedPreferences.setMockInitialValues({
        'gear_body_id': 'sony_a6700',
        'gear_lens_ids': ['sigma_18-50'],
        'gear_active_lens_id': 'sigma_18-50',
        'gear_language': 'fr',
      });
      prefs = await SharedPreferences.getInstance();
      store = GearProfileStore(prefs);

      final migrated = await store.migrateFromLegacy();

      expect(migrated, isNotNull);
      expect(migrated!.bodyId, 'sony_a6700');
      expect(migrated.name, 'Mon kit');
      expect(store.profiles.length, 1);
      expect(store.activeProfileId, 'default');
    });

    test('migrateFromLegacy does nothing when no legacy data', () async {
      final result = await store.migrateFromLegacy();
      expect(result, isNull);
      expect(store.profiles, isEmpty);
    });

    test('migrateFromLegacy does not duplicate if already migrated', () async {
      SharedPreferences.setMockInitialValues({
        'gear_body_id': 'sony_a6700',
        'gear_lens_ids': ['sigma_18-50'],
        'gear_active_lens_id': 'sigma_18-50',
        'gear_language': 'fr',
      });
      prefs = await SharedPreferences.getInstance();
      store = GearProfileStore(prefs);

      await store.migrateFromLegacy();
      await store.migrateFromLegacy(); // second call

      expect(store.profiles.length, 1);
    });

    test('GearProfileData.copyWith works correctly', () {
      const profile = GearProfileData(
        id: 'p1',
        name: 'Kit 1',
        bodyId: 'sony_a6700',
        lensIds: ['lens_a'],
        activeLensId: 'lens_a',
        language: 'fr',
      );
      final updated = profile.copyWith(name: 'Kit voyage', language: 'en');
      expect(updated.id, 'p1');
      expect(updated.name, 'Kit voyage');
      expect(updated.language, 'en');
      expect(updated.bodyId, 'sony_a6700');
    });
  });
}
