import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/presentation/providers/scene_providers.dart';
import 'package:shoothelper/features/results/presentation/screens/setting_detail_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('SettingDetailScreen', () {
    testWidgets('displays setting value and explanation', (tester) async {
      final result = testResult();
      await tester.pumpWidget(
        testableWidget(
          const SettingDetailScreen(settingId: 'af_mode'),
          overrides: [
            settingsResultProvider.overrideWithValue(
              AsyncValue.data(result),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mode autofocus'), findsOneWidget);
      expect(find.text('AF-C'), findsOneWidget);
      expect(find.text('Suivi continu du sujet'), findsOneWidget);
    });

    testWidgets('displays detailed explanation', (tester) async {
      final result = testResult();
      await tester.pumpWidget(
        testableWidget(
          const SettingDetailScreen(settingId: 'af_mode'),
          overrides: [
            settingsResultProvider.overrideWithValue(
              AsyncValue.data(result),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pourquoi ce réglage ?'), findsOneWidget);
      expect(
        find.textContaining('AF-C maintient la mise au point'),
        findsOneWidget,
      );
    });

    testWidgets('displays alternatives section', (tester) async {
      final result = testResult();
      await tester.pumpWidget(
        testableWidget(
          const SettingDetailScreen(settingId: 'af_mode'),
          overrides: [
            settingsResultProvider.overrideWithValue(
              AsyncValue.data(result),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alternatives'), findsOneWidget);
      expect(find.text('AF-S'), findsOneWidget);
      expect(find.text('Plus précis sur sujet immobile'), findsOneWidget);
    });

    testWidgets('shows "Comment régler ?" button', (tester) async {
      final result = testResult();
      await tester.pumpWidget(
        testableWidget(
          const SettingDetailScreen(settingId: 'af_mode'),
          overrides: [
            settingsResultProvider.overrideWithValue(
              AsyncValue.data(result),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(FilledButton, 'Comment régler ?'),
        findsOneWidget,
      );
    });

    testWidgets('shows error for unknown setting', (tester) async {
      final result = testResult();
      await tester.pumpWidget(
        testableWidget(
          const SettingDetailScreen(settingId: 'unknown_setting'),
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
  });
}
