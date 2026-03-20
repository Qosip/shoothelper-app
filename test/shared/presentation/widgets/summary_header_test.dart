import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/presentation/widgets/summary_header.dart';
import 'package:shoothelper/shared/presentation/widgets/confidence_badge.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SummaryHeader', () {
    testWidgets('displays all 4 values', (tester) async {
      await tester.pumpWidget(_wrap(
        const SummaryHeader(
          aperture: 'f/2.8',
          shutterSpeed: '1/125',
          iso: '400',
          exposureMode: 'A',
        ),
      ));
      expect(find.text('f/2.8'), findsOneWidget);
      expect(find.text('1/125'), findsOneWidget);
      expect(find.text('400'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('displays overline labels', (tester) async {
      await tester.pumpWidget(_wrap(
        const SummaryHeader(
          aperture: 'f/2.8',
          shutterSpeed: '1/125',
          iso: '400',
          exposureMode: 'A',
        ),
      ));
      expect(find.text('OUVERTURE'), findsOneWidget);
      expect(find.text('VITESSE'), findsOneWidget);
      expect(find.text('ISO'), findsOneWidget);
      expect(find.text('MODE'), findsOneWidget);
    });

    testWidgets('shows confidence badge', (tester) async {
      await tester.pumpWidget(_wrap(
        const SummaryHeader(
          aperture: 'f/8',
          shutterSpeed: '1/250',
          iso: '200',
          exposureMode: 'M',
          confidence: ConfidenceLevel.medium,
        ),
      ));
      expect(find.text('Compromis'), findsOneWidget);
    });
  });
}
