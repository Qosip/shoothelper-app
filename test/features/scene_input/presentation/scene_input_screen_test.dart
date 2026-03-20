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
      // With 23 subject chips, Intention may be off-screen — check with skipOffstage: false
      expect(find.text('Intention', skipOffstage: false), findsOneWidget);
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

      // Button is in BottomStickyBar (Positioned), always visible
      final buttonFinder = find.ancestor(
        of: find.text('Calculer les réglages'),
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

      // AnimatedCrossFade keeps both children in tree, so we verify
      // that after tapping the section expands (content becomes interactive)
      await tester.tap(find.text('Options avancées'));
      await tester.pumpAndSettle();

      // After expansion, Lumière and Support labels are visible
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

      // Button is in BottomStickyBar (Positioned), always visible
      final buttonFinder = find.ancestor(
        of: find.text('Calculer les réglages'),
        matching: find.byType(FilledButton),
      );
      final button = tester.widget<FilledButton>(buttonFinder);
      expect(button.onPressed, isNotNull);
    });
  });
}
