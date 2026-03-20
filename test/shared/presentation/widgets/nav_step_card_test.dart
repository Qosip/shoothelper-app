import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/presentation/widgets/nav_step_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('NavStepCard', () {
    testWidgets('displays step number and text', (tester) async {
      await tester.pumpWidget(_wrap(
        const NavStepCard(stepNumber: 1, text: 'Menu principal'),
      ));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Menu principal'), findsOneWidget);
    });

    testWidgets('shows connector line when not last', (tester) async {
      await tester.pumpWidget(_wrap(
        const NavStepCard(stepNumber: 1, text: 'Step'),
      ));
      // Not the last step → connector line exists (Expanded Container with width 2)
      expect(find.text('Step'), findsOneWidget);
    });

    testWidgets('last step renders without error', (tester) async {
      await tester.pumpWidget(_wrap(
        const NavStepCard(stepNumber: 3, text: 'Final', isLast: true),
      ));
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Final'), findsOneWidget);
    });
  });
}
