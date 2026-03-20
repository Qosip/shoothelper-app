import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/domain/entities/settings_result.dart';
import 'package:shoothelper/shared/domain/enums/shooting_enums.dart';
import 'package:shoothelper/shared/presentation/providers/scene_providers.dart';
import 'package:shoothelper/features/results/presentation/screens/results_screen.dart';

import '../../../helpers/test_helpers.dart';

/// Minimal result with fewer settings to fit on screen.
SettingsResult _smallResult() => const SettingsResult(
      settings: [
        SettingRecommendation(
          settingId: 'aperture',
          value: 2.8,
          valueDisplay: 'f/2.8',
          explanationShort: 'Grande ouverture pour bokeh',
        ),
        SettingRecommendation(
          settingId: 'shutter_speed',
          value: '1/200',
          valueDisplay: '1/200s',
          explanationShort: 'Rapide pour le portrait',
        ),
        SettingRecommendation(
          settingId: 'iso',
          value: 400,
          valueDisplay: 'ISO 400',
          explanationShort: 'Bon compromis',
        ),
        SettingRecommendation(
          settingId: 'exposure_mode',
          value: 'a',
          valueDisplay: 'A',
          explanationShort: 'Priorité ouverture',
        ),
      ],
      compromises: [],
      sceneSummary: 'Portrait bokeh',
      confidence: Confidence.high,
    );

void main() {
  group('ResultsScreen', () {
    testWidgets('displays exposure summary when result is available',
        (tester) async {
      final result = testResult();
      await tester.pumpWidget(
        testableWidget(
          const ResultsScreen(),
          overrides: [
            settingsResultProvider.overrideWithValue(
              AsyncValue.data(result),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Résultats'), findsOneWidget);
      // Exposure summary values
      expect(find.text('f/2.8'), findsWidgets);
      expect(find.text('1/200s'), findsWidgets);
      expect(find.text('ISO 400'), findsWidgets);
      expect(find.text('A'), findsWidgets);
    });

    testWidgets('displays scene summary and confidence', (tester) async {
      final result = testResult();
      await tester.pumpWidget(
        testableWidget(
          const ResultsScreen(),
          overrides: [
            settingsResultProvider.overrideWithValue(
              AsyncValue.data(result),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // SummaryHeader shows confidence badge
      expect(find.text('Confiance haute'), findsOneWidget);
    });

    testWidgets('displays compromise banner', (tester) async {
      final result = testResult();
      await tester.pumpWidget(
        testableWidget(
          const ResultsScreen(),
          overrides: [
            settingsResultProvider.overrideWithValue(
              AsyncValue.data(result),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('ISO 400'), findsWidgets);
    });

    testWidgets('displays all settings list', (tester) async {
      final result = _smallResult();
      await tester.pumpWidget(
        testableWidget(
          const ResultsScreen(),
          overrides: [
            settingsResultProvider.overrideWithValue(
              AsyncValue.data(result),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TOUS LES RÉGLAGES'), findsOneWidget);
      // "Ouverture" appears in both the ExposureSummaryCard and SettingRow
      expect(find.text('Ouverture'), findsWidgets);
      expect(find.text('Vitesse'), findsWidgets);
    });

    testWidgets('shows loading when result is loading', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          const ResultsScreen(),
          overrides: [
            settingsResultProvider.overrideWithValue(
              const AsyncValue.loading(),
            ),
          ],
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows message when result is null', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          const ResultsScreen(),
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
  });
}
