import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/features/scene_input/presentation/screens/scene_input_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('SceneInputScreen', () {
    testWidgets('displays Level 1 chip selectors', (tester) async {
      await tester.pumpWidget(
        testableWidget(const SceneInputScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Décris ta scène'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Environnement'), findsOneWidget);
      expect(find.text('Sujet'), findsOneWidget);
      expect(find.text('Intention'), findsOneWidget);
    });

    testWidgets('shows shoot type chips (Photo, Vidéo)', (tester) async {
      await tester.pumpWidget(
        testableWidget(const SceneInputScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('Vidéo'), findsOneWidget);
    });

    testWidgets('Calculer button is disabled when Level 1 is incomplete',
        (tester) async {
      await tester.pumpWidget(
        testableWidget(const SceneInputScreen()),
      );
      await tester.pumpAndSettle();

      // Scroll to bottom to find the button
      await tester.scrollUntilVisible(
        find.text('Calculer'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      // FilledButton.icon creates a subclass, so find by text then ancestor
      final buttonFinder = find.ancestor(
        of: find.text('Calculer'),
        matching: find.byType(FilledButton),
      );
      final button = tester.widget<FilledButton>(buttonFinder);
      expect(button.onPressed, isNull);
    });

    testWidgets('expandable sections exist', (tester) async {
      await tester.pumpWidget(
        testableWidget(const SceneInputScreen()),
      );
      await tester.pumpAndSettle();

      // Scroll to make expandable sections visible
      await tester.scrollUntilVisible(
        find.text('Options avancées'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Options avancées'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Overrides'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Overrides'), findsOneWidget);
    });

    testWidgets('tapping Options avancées expands to show Lumière',
        (tester) async {
      await tester.pumpWidget(
        testableWidget(const SceneInputScreen()),
      );
      await tester.pumpAndSettle();

      // Scroll to expandable section
      await tester.scrollUntilVisible(
        find.text('Options avancées'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      // Lumière should not be visible yet
      expect(find.text('Lumière'), findsNothing);

      // Tap to expand
      await tester.tap(find.text('Options avancées'));
      await tester.pumpAndSettle();

      expect(find.text('Lumière'), findsOneWidget);
      expect(find.text('Support'), findsOneWidget);
    });

    testWidgets('selecting all Level 1 fields enables Calculer button',
        (tester) async {
      await tester.pumpWidget(
        testableWidget(const SceneInputScreen()),
      );
      await tester.pumpAndSettle();

      // Select one chip from each Level 1 field
      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Extérieur jour'));
      await tester.pumpAndSettle();

      // Portrait might need scrolling
      await tester.scrollUntilVisible(
        find.text('Portrait'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Portrait'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Bokeh'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Bokeh'));
      await tester.pumpAndSettle();

      // Scroll to Calculer
      await tester.scrollUntilVisible(
        find.text('Calculer'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      final buttonFinder = find.ancestor(
        of: find.text('Calculer'),
        matching: find.byType(FilledButton),
      );
      final button = tester.widget<FilledButton>(buttonFinder);
      expect(button.onPressed, isNotNull);
    });
  });
}
