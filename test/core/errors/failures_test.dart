import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/core/errors/exceptions.dart';
import 'package:shoothelper/core/errors/failures.dart';

void main() {
  group('Failure classes', () {
    test('NetworkFailure has retry action', () {
      const f = NetworkFailure();
      expect(f.actionLabel, 'Réessayer');
      expect(f.action, FailureAction.retry);
    });

    test('DataNotReadyFailure has goToSettings action', () {
      const f = DataNotReadyFailure();
      expect(f.action, FailureAction.goToSettings);
    });

    test('CorruptedDataFailure has retry action', () {
      const f = CorruptedDataFailure();
      expect(f.action, FailureAction.retry);
    });

    test('GearMissingFailure has goToSettings action', () {
      const f = GearMissingFailure();
      expect(f.action, FailureAction.goToSettings);
    });

    test('AppUpdateRequiredFailure has goToStore action', () {
      const f = AppUpdateRequiredFailure();
      expect(f.action, FailureAction.goToStore);
    });

    test('UnknownFailure has reportBug action', () {
      const f = UnknownFailure();
      expect(f.action, FailureAction.reportBug);
    });

    test('sealed class exhaustive switch works', () {
      const Failure f = NetworkFailure();
      final label = switch (f) {
        NetworkFailure() => 'network',
        DataNotReadyFailure() => 'data',
        CorruptedDataFailure() => 'corrupted',
        GearMissingFailure() => 'gear',
        AppUpdateRequiredFailure() => 'update',
        UnknownFailure() => 'unknown',
      };
      expect(label, 'network');
    });
  });

  group('mapToFailure', () {
    test('NoNetworkException → NetworkFailure', () {
      expect(mapToFailure(const NoNetworkException()), isA<NetworkFailure>());
    });

    test('NetworkTimeoutException → NetworkFailure', () {
      expect(
        mapToFailure(const NetworkTimeoutException('url')),
        isA<NetworkFailure>(),
      );
    });

    test('ServerException → NetworkFailure', () {
      expect(mapToFailure(const ServerException(500)), isA<NetworkFailure>());
    });

    test('DataPackNotFoundException → DataNotReadyFailure', () {
      expect(
        mapToFailure(const DataPackNotFoundException('sony_a6700')),
        isA<DataNotReadyFailure>(),
      );
    });

    test('DataPackCorruptedException → CorruptedDataFailure', () {
      expect(
        mapToFailure(const DataPackCorruptedException('sony_a6700')),
        isA<CorruptedDataFailure>(),
      );
    });

    test('IncompatibleLensException → GearMissingFailure', () {
      expect(
        mapToFailure(const IncompatibleLensException('l', 'b')),
        isA<GearMissingFailure>(),
      );
    });

    test('unknown error → UnknownFailure', () {
      expect(mapToFailure(Exception('oops')), isA<UnknownFailure>());
    });

    test('UnexpectedException → UnknownFailure', () {
      expect(
        mapToFailure(UnexpectedException(Exception('x'))),
        isA<UnknownFailure>(),
      );
    });
  });
}
