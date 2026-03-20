import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/presentation/widgets/confidence_badge.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ConfidenceBadge', () {
    testWidgets('shows "Confiance haute" for high', (tester) async {
      await tester.pumpWidget(_wrap(
        const ConfidenceBadge(level: ConfidenceLevel.high),
      ));
      expect(find.text('Confiance haute'), findsOneWidget);
    });

    testWidgets('shows "Compromis" for medium', (tester) async {
      await tester.pumpWidget(_wrap(
        const ConfidenceBadge(level: ConfidenceLevel.medium),
      ));
      expect(find.text('Compromis'), findsOneWidget);
    });

    testWidgets('shows "Confiance faible" for low', (tester) async {
      await tester.pumpWidget(_wrap(
        const ConfidenceBadge(level: ConfidenceLevel.low),
      ));
      expect(find.text('Confiance faible'), findsOneWidget);
    });
  });
}
