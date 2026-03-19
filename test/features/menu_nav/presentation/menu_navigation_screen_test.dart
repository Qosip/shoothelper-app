import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/presentation/providers/scene_providers.dart';
import 'package:shoothelper/features/menu_nav/presentation/screens/menu_navigation_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('MenuNavigationScreen', () {
    testWidgets('shows "not available" when result is null', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          const MenuNavigationScreen(settingId: 'af_mode'),
          overrides: [
            settingsResultProvider.overrideWithValue(
              const AsyncValue.data(null),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aucun résultat'), findsOneWidget);
    });

    testWidgets('shows "not found" for unknown setting', (tester) async {
      final result = testResult();
      await tester.pumpWidget(
        testableWidget(
          const MenuNavigationScreen(settingId: 'unknown'),
          overrides: [
            settingsResultProvider.overrideWithValue(
              AsyncValue.data(result),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('non trouvé'), findsOneWidget);
    });

    testWidgets('has appbar with correct title', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          const MenuNavigationScreen(settingId: 'af_mode'),
          overrides: [
            settingsResultProvider.overrideWithValue(
              const AsyncValue.data(null),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Comment régler'), findsOneWidget);
    });

    testWidgets('shows loading while result is loading', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          const MenuNavigationScreen(settingId: 'af_mode'),
          overrides: [
            settingsResultProvider.overrideWithValue(
              const AsyncValue.loading(),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Comment régler'), findsOneWidget);
    });
  });
}
