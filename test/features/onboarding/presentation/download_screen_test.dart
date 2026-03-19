import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/domain/entities/catalog.dart';
import 'package:shoothelper/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:shoothelper/features/onboarding/presentation/screens/download_screen.dart';

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
  group('DownloadScreen', () {
    testWidgets('displays recap with selections', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          const DownloadScreen(),
          overrides: [
            catalogProvider.overrideWith((ref) => _testCatalog()),
            selectedBodyIdProvider.overrideWith((ref) => 'sony_a6700'),
            selectedLensIdsProvider
                .overrideWith((ref) => ['sigma_18-50']),
            selectedLanguageProvider.overrideWith((ref) => 'fr'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Récapitulatif'), findsOneWidget);
      expect(find.text('Sony α6700'), findsOneWidget);
      expect(find.text('Sigma 18-50mm f/2.8'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);
    });

    testWidgets('shows Télécharger button in idle state', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          const DownloadScreen(),
          overrides: [
            catalogProvider.overrideWith((ref) => _testCatalog()),
            selectedBodyIdProvider.overrideWith((ref) => 'sony_a6700'),
            selectedLensIdsProvider
                .overrideWith((ref) => ['sigma_18-50']),
            selectedLanguageProvider.overrideWith((ref) => 'fr'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Télécharger'), findsOneWidget);
    });

    testWidgets('shows "C\'est parti !" when download is complete',
        (tester) async {
      await tester.pumpWidget(
        testableWidget(
          const DownloadScreen(),
          overrides: [
            catalogProvider.overrideWith((ref) => _testCatalog()),
            selectedBodyIdProvider.overrideWith((ref) => 'sony_a6700'),
            selectedLensIdsProvider
                .overrideWith((ref) => ['sigma_18-50']),
            selectedLanguageProvider.overrideWith((ref) => 'fr'),
            downloadStatusProvider
                .overrideWith((ref) => DownloadStatus.complete),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Téléchargement terminé !'), findsOneWidget);
      expect(find.text('C\'est parti !'), findsOneWidget);
    });
  });
}
