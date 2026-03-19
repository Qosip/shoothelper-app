import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/core/utils/label_resolver.dart';

void main() {
  group('resolveLabel', () {
    test('returns requested language when available', () {
      final result = resolveLabel(
        {'fr': 'Ouverture', 'en': 'Aperture'},
        'fr',
        fallbackId: 'aperture',
      );
      expect(result.text, 'Ouverture');
      expect(result.isFallback, false);
    });

    test('falls back to English when requested language missing', () {
      final result = resolveLabel(
        {'en': 'Aperture', 'de': 'Blende'},
        'fr',
        fallbackId: 'aperture',
      );
      expect(result.text, 'Aperture');
      expect(result.isFallback, true);
    });

    test('falls back to first available when no English', () {
      final result = resolveLabel(
        {'de': 'Blende', 'ja': '絞り'},
        'fr',
        fallbackId: 'aperture',
      );
      expect(result.text, 'Blende');
      expect(result.isFallback, true);
    });

    test('falls back to ID when labels map is empty', () {
      final result = resolveLabel(
        {},
        'fr',
        fallbackId: 'aperture',
      );
      expect(result.text, 'aperture');
      expect(result.isFallback, true);
    });
  });
}
