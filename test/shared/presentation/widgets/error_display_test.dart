import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/core/errors/failures.dart';
import 'package:shoothelper/shared/presentation/widgets/error_display.dart';

void main() {
  Widget buildErrorDisplay(Failure failure, {VoidCallback? onAction}) {
    return MaterialApp(
      home: Scaffold(
        body: ErrorDisplay(failure: failure, onAction: onAction),
      ),
    );
  }

  group('ErrorDisplay', () {
    testWidgets('displays NetworkFailure with wifi_off icon', (tester) async {
      await tester.pumpWidget(buildErrorDisplay(const NetworkFailure()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.textContaining('connexion internet'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('displays DataNotReadyFailure with download icon',
        (tester) async {
      await tester.pumpWidget(buildErrorDisplay(const DataNotReadyFailure()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
      expect(find.text('Télécharger'), findsOneWidget);
    });

    testWidgets('displays CorruptedDataFailure with warning icon',
        (tester) async {
      await tester.pumpWidget(buildErrorDisplay(const CorruptedDataFailure()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
      expect(find.text('Re-télécharger'), findsOneWidget);
    });

    testWidgets('displays GearMissingFailure with camera icon',
        (tester) async {
      await tester.pumpWidget(buildErrorDisplay(const GearMissingFailure()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
      expect(find.text('Configurer'), findsOneWidget);
    });

    testWidgets('displays UnknownFailure with error icon', (tester) async {
      await tester.pumpWidget(buildErrorDisplay(const UnknownFailure()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('Signaler'), findsOneWidget);
    });

    testWidgets('action button triggers callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildErrorDisplay(
          const NetworkFailure(),
          onAction: () => tapped = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Réessayer'));
      expect(tapped, true);
    });

    testWidgets('AppUpdateRequiredFailure shows update icon', (tester) async {
      await tester
          .pumpWidget(buildErrorDisplay(const AppUpdateRequiredFailure()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.system_update_rounded), findsOneWidget);
      expect(find.text('Mettre à jour'), findsOneWidget);
    });
  });
}
