import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoothelper/shared/data/data_sources/local/gear_profile_source.dart';

void main() {
  late GearProfileSource source;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    source = GearProfileSource(prefs);
  });

  group('GearProfileSource', () {
    test('defaults: not onboarded, no body, empty lenses, fr language', () {
      expect(source.isOnboardingComplete, false);
      expect(source.bodyId, isNull);
      expect(source.lensIds, isEmpty);
      expect(source.activeLensId, isNull);
      expect(source.language, 'fr');
    });

    test('saveOnboarding persists all fields', () async {
      await source.saveOnboarding(
        bodyId: 'sony_a6700',
        lensIds: ['sigma_18-50', 'sony_50_f1.8'],
        language: 'en',
      );

      expect(source.isOnboardingComplete, true);
      expect(source.bodyId, 'sony_a6700');
      expect(source.lensIds, ['sigma_18-50', 'sony_50_f1.8']);
      expect(source.activeLensId, 'sigma_18-50');
      expect(source.language, 'en');
    });

    test('setActiveLens changes active lens', () async {
      await source.saveOnboarding(
        bodyId: 'sony_a6700',
        lensIds: ['a', 'b'],
        language: 'fr',
      );
      await source.setActiveLens('b');
      expect(source.activeLensId, 'b');
    });

    test('addLens adds to list without duplicates', () async {
      await source.saveOnboarding(
        bodyId: 'sony_a6700',
        lensIds: ['a'],
        language: 'fr',
      );
      await source.addLens('b');
      expect(source.lensIds, ['a', 'b']);

      // Adding duplicate does nothing
      await source.addLens('b');
      expect(source.lensIds, ['a', 'b']);
    });

    test('removeLens removes from list', () async {
      await source.saveOnboarding(
        bodyId: 'sony_a6700',
        lensIds: ['a', 'b'],
        language: 'fr',
      );
      await source.removeLens('b');
      expect(source.lensIds, ['a']);
    });

    test('removeLens switches active if active was removed', () async {
      await source.saveOnboarding(
        bodyId: 'sony_a6700',
        lensIds: ['a', 'b'],
        language: 'fr',
      );
      expect(source.activeLensId, 'a');
      await source.removeLens('a');
      expect(source.activeLensId, 'b');
    });

    test('setBody changes body ID', () async {
      await source.saveOnboarding(
        bodyId: 'sony_a6700',
        lensIds: ['a'],
        language: 'fr',
      );
      await source.setBody('canon_r50');
      expect(source.bodyId, 'canon_r50');
    });

    test('setLanguage changes language', () async {
      await source.setLanguage('en');
      expect(source.language, 'en');
    });

    test('clear removes all data', () async {
      await source.saveOnboarding(
        bodyId: 'sony_a6700',
        lensIds: ['a'],
        language: 'en',
      );
      await source.clear();
      expect(source.isOnboardingComplete, false);
      expect(source.bodyId, isNull);
      expect(source.lensIds, isEmpty);
    });
  });
}
