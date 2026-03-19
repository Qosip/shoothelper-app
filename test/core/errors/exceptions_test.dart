import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/core/errors/exceptions.dart';

void main() {
  group('ShootHelperException hierarchy', () {
    test('NoNetworkException is a ShootHelperException', () {
      const e = NoNetworkException();
      expect(e, isA<ShootHelperException>());
      expect(e.message, 'Pas de connexion internet');
    });

    test('NetworkTimeoutException carries url', () {
      const e = NetworkTimeoutException('https://example.com');
      expect(e.url, 'https://example.com');
      expect(e.message, 'La connexion a expiré');
    });

    test('ServerException carries statusCode', () {
      const e = ServerException(502);
      expect(e.statusCode, 502);
    });

    test('DataPackNotFoundException carries bodyId', () {
      const e = DataPackNotFoundException('sony_a6700');
      expect(e.bodyId, 'sony_a6700');
    });

    test('DataPackCorruptedException carries bodyId', () {
      const e = DataPackCorruptedException('sony_a6700');
      expect(e.bodyId, 'sony_a6700');
    });

    test('DataPackIncompleteException carries missingFiles', () {
      const e = DataPackIncompleteException('sony_a6700', ['body.json']);
      expect(e.missingFiles, ['body.json']);
    });

    test('MenuItemNotFoundException carries settingId and bodyId', () {
      const e = MenuItemNotFoundException('af_mode', 'sony_a6700');
      expect(e.settingId, 'af_mode');
      expect(e.bodyId, 'sony_a6700');
    });

    test('LabelNotFoundException carries itemId and language', () {
      const e = LabelNotFoundException('focus_mode', 'fr');
      expect(e.itemId, 'focus_mode');
      expect(e.language, 'fr');
    });

    test('ExposureImpossibleException carries reason', () {
      const e = ExposureImpossibleException('too dark');
      expect(e.reason, 'too dark');
    });

    test('IncompatibleLensException carries lensId and bodyId', () {
      const e = IncompatibleLensException('canon_rf_50', 'sony_a6700');
      expect(e.lensId, 'canon_rf_50');
      expect(e.bodyId, 'sony_a6700');
    });

    test('UnexpectedException wraps original error', () {
      final original = Exception('oops');
      final e = UnexpectedException(original);
      expect(e.originalError, original);
    });

    test('toString includes runtimeType', () {
      const e = NoNetworkException();
      expect(e.toString(), contains('NoNetworkException'));
    });

    test('sealed class exhaustive switch works', () {
      const ShootHelperException e = NoNetworkException();
      final label = switch (e) {
        NoNetworkException() => 'network',
        NetworkTimeoutException() => 'timeout',
        ServerException() => 'server',
        DataPackNotFoundException() => 'not_found',
        DataPackCorruptedException() => 'corrupted',
        DataPackIncompleteException() => 'incomplete',
        MenuItemNotFoundException() => 'menu_item',
        LabelNotFoundException() => 'label',
        LensNotFoundException() => 'lens',
        ExposureImpossibleException() => 'exposure',
        IncompatibleLensException() => 'incompatible',
        FeatureNotSupportedException() => 'feature',
        StorageFullException() => 'storage',
        FilePermissionException() => 'permission',
        UnexpectedException() => 'unexpected',
      };
      expect(label, 'network');
    });
  });
}
