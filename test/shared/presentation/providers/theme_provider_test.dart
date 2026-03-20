import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoothelper/shared/presentation/providers/gear_profile_provider.dart';
import 'package:shoothelper/shared/presentation/providers/theme_provider.dart';

void main() {
  group('ThemeModeNotifier', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    ProviderContainer createContainer({Map<String, Object>? values}) {
      if (values != null) {
        SharedPreferences.setMockInitialValues(values);
      }
      return ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
    }

    test('defaults to ThemeMode.system when no preference stored', () async {
      final container = createContainer();
      expect(container.read(themeModeProvider), ThemeMode.system);
      container.dispose();
    });

    test('reads persisted light theme from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      prefs = await SharedPreferences.getInstance();
      final container = createContainer();
      expect(container.read(themeModeProvider), ThemeMode.light);
      container.dispose();
    });

    test('reads persisted dark theme from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      prefs = await SharedPreferences.getInstance();
      final container = createContainer();
      expect(container.read(themeModeProvider), ThemeMode.dark);
      container.dispose();
    });

    test('setThemeMode persists to SharedPreferences', () async {
      final container = createContainer();
      await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(prefs.getString('theme_mode'), 'dark');

      await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(prefs.getString('theme_mode'), 'light');

      await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
      expect(container.read(themeModeProvider), ThemeMode.system);
      expect(prefs.getString('theme_mode'), 'system');

      container.dispose();
    });

    test('unknown stored value defaults to system', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'invalid'});
      prefs = await SharedPreferences.getInstance();
      final container = createContainer();
      expect(container.read(themeModeProvider), ThemeMode.system);
      container.dispose();
    });
  });
}
