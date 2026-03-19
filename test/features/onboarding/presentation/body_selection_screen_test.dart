import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/domain/entities/catalog.dart';
import 'package:shoothelper/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:shoothelper/features/onboarding/presentation/screens/body_selection_screen.dart';

import '../../../helpers/test_helpers.dart';

Catalog _testCatalog() => Catalog.fromJson(const {
      'version': '1.0.0',
      'bodies': [
        {
          'id': 'sony_a6700',
          'brand_id': 'sony',
          'name': 'Sony A6700',
          'display_name': 'Sony α6700',
          'sensor_size': 'aps-c',
          'mount': 'sony_e',
          'pack_version': '1.0.0',
          'pack_size_bytes': 52000,
          'languages': ['fr', 'en'],
          'lenses': [
            {
              'id': 'sigma_18-50',
              'brand_id': 'sigma',
              'name': 'Sigma 18-50mm',
              'display_name': 'Sigma 18-50mm f/2.8',
              'is_kit_lens': false,
              'popularity_rank': 1,
            }
          ],
        }
      ],
    });

void main() {
  group('BodySelectionScreen', () {
    testWidgets('displays body from catalog', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          const BodySelectionScreen(),
          overrides: [
            catalogProvider.overrideWith((ref) => _testCatalog()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Choisis ton boîtier'), findsOneWidget);
      expect(find.text('Sony α6700'), findsOneWidget);
      expect(find.textContaining('APS-C'), findsOneWidget);
    });

    testWidgets('Suivant button disabled when no body selected',
        (tester) async {
      await tester.pumpWidget(
        testableWidget(
          const BodySelectionScreen(),
          overrides: [
            catalogProvider.overrideWith((ref) => _testCatalog()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Suivant'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('tapping body enables Suivant', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          const BodySelectionScreen(),
          overrides: [
            catalogProvider.overrideWith((ref) => _testCatalog()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sony α6700'));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Suivant'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('shows loading when catalog is null', (tester) async {
      await tester.pumpWidget(
        testableWidget(const BodySelectionScreen()),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
