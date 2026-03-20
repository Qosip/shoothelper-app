import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/presentation/providers/gear_providers.dart';
import 'package:shoothelper/shared/presentation/providers/gear_profile_store_provider.dart';
import 'package:shoothelper/features/scene_input/presentation/screens/home_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('displays body and lens names when loaded', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          const HomeScreen(),
          overrides: [
            currentBodyProvider.overrideWithValue(
              AsyncValue.data(testBody()),
            ),
            currentLensProvider.overrideWithValue(
              AsyncValue.data(testLens()),
            ),
            activeProfileProvider.overrideWithValue(null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ShootHelper'), findsOneWidget);
      // GearBadge shows displayName
      expect(find.text('Sony α6700'), findsOneWidget);
      expect(find.text('Sigma 18-50mm f/2.8'), findsOneWidget);
      expect(find.text('Nouveau shoot'), findsOneWidget);
    });

    testWidgets('shows loading indicator while data loads', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          const HomeScreen(),
          overrides: [
            currentBodyProvider.overrideWithValue(
              const AsyncValue.loading(),
            ),
            currentLensProvider.overrideWithValue(
              const AsyncValue.loading(),
            ),
            activeProfileProvider.overrideWithValue(null),
          ],
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows error when body fails to load', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          const HomeScreen(),
          overrides: [
            currentBodyProvider.overrideWithValue(
              AsyncValue.error('Load failed', StackTrace.current),
            ),
            currentLensProvider.overrideWithValue(
              AsyncValue.data(testLens()),
            ),
            activeProfileProvider.overrideWithValue(null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Erreur'), findsOneWidget);
    });

    testWidgets('"Nouveau shoot" button exists', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          const HomeScreen(),
          overrides: [
            currentBodyProvider.overrideWithValue(
              AsyncValue.data(testBody()),
            ),
            currentLensProvider.overrideWithValue(
              AsyncValue.data(testLens()),
            ),
            activeProfileProvider.overrideWithValue(null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Nouveau shoot'), findsOneWidget);
    });
  });
}
