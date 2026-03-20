import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shoothelper/features/onboarding/presentation/screens/welcome_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('WelcomeScreen', () {
    testWidgets('displays app name and tagline', (tester) async {
      await tester.pumpWidget(
        testableWidget(const WelcomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('ShootHelper'), findsOneWidget);
      expect(
        find.textContaining('réglages photo optimaux'),
        findsOneWidget,
      );
    });

    testWidgets('displays Commencer button', (tester) async {
      await tester.pumpWidget(
        testableWidget(const WelcomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Commencer'), findsOneWidget);
    });

    testWidgets('displays camera icon', (tester) async {
      await tester.pumpWidget(
        testableWidget(const WelcomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.camera), findsOneWidget);
    });
  });
}
