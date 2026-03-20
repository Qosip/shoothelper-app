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

      expect(find.text('POURQUOI CE RÉGLAGE'), findsOneWidget);
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

      expect(find.text('ALTERNATIVES'), findsOneWidget);
      expect(find.text('AF-S'), findsOneWidget);
      expect(find.text('Plus précis sur sujet immobile'), findsOneWidget);
    });

    testWidgets('shows fallback text when no NavPath', (tester) async {
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
        find.textContaining('pas encore documenté'),
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
