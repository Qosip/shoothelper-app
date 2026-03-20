import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shoothelper/shared/presentation/widgets/section_divider.dart';
import 'package:shoothelper/shared/presentation/widgets/expand_toggle.dart';
import 'package:shoothelper/shared/presentation/widgets/gear_badge.dart';
import 'package:shoothelper/shared/presentation/widgets/compromise_banner.dart';
import 'package:shoothelper/shared/presentation/widgets/bottom_sticky_bar.dart';
import 'package:shoothelper/shared/presentation/theme/app_colors.dart';
import 'package:shoothelper/shared/presentation/theme/app_spacing.dart';
import 'package:shoothelper/shared/presentation/theme/app_typography.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  group('SectionDivider', () {
    testWidgets('renders without label', (tester) async {
      await tester.pumpWidget(_wrap(const SectionDivider()));
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(_wrap(
        const SectionDivider(label: 'ADVANCED'),
      ));
      expect(find.text('ADVANCED'), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(2));
    });
  });

  group('ExpandToggle', () {
    testWidgets('displays label and arrow', (tester) async {
      await tester.pumpWidget(_wrap(
        const ExpandToggle(label: 'Options', isExpanded: false),
      ));
      expect(find.text('Options'), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronDown), findsOneWidget);
    });

    testWidgets('shows badge count', (tester) async {
      await tester.pumpWidget(_wrap(
        const ExpandToggle(label: 'Options', isExpanded: false, badgeCount: 5),
      ));
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('calls onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        ExpandToggle(
          label: 'Toggle',
          isExpanded: false,
          onTap: () => tapped = true,
        ),
      ));
      await tester.tap(find.text('Toggle'));
      expect(tapped, isTrue);
    });
  });

  group('GearBadge', () {
    testWidgets('displays body and lens names', (tester) async {
      await tester.pumpWidget(_wrap(
        const GearBadge(bodyName: 'A6700', lensName: 'Sigma 18-50'),
      ));
      expect(find.text('A6700'), findsOneWidget);
      expect(find.text('Sigma 18-50'), findsOneWidget);
    });

    testWidgets('shows camera and aperture icons', (tester) async {
      await tester.pumpWidget(_wrap(
        const GearBadge(bodyName: 'A6700', lensName: 'Sigma 18-50'),
      ));
      expect(find.byIcon(LucideIcons.camera), findsOneWidget);
      expect(find.byIcon(LucideIcons.aperture), findsOneWidget);
    });

    testWidgets('shows chevron when tappable', (tester) async {
      await tester.pumpWidget(_wrap(
        GearBadge(bodyName: 'A6700', lensName: 'lens', onTap: () {}),
      ));
      expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
    });
  });

  group('CompromiseBanner', () {
    testWidgets('displays text for warning', (tester) async {
      await tester.pumpWidget(_wrap(
        const CompromiseBanner(text: 'ISO monté', severity: CompromiseSeverity.warning),
      ));
      expect(find.text('ISO monté'), findsOneWidget);
      expect(find.byIcon(LucideIcons.alertCircle), findsOneWidget);
    });

    testWidgets('displays text for critical', (tester) async {
      await tester.pumpWidget(_wrap(
        const CompromiseBanner(text: 'Flou', severity: CompromiseSeverity.critical),
      ));
      expect(find.text('Flou'), findsOneWidget);
      expect(find.byIcon(LucideIcons.alertTriangle), findsOneWidget);
    });
  });

  group('BottomStickyBar', () {
    testWidgets('renders child with blur', (tester) async {
      await tester.pumpWidget(_wrap(
        const BottomStickyBar(child: Text('CTA')),
      ));
      expect(find.text('CTA'), findsOneWidget);
    });
  });

  group('AppColors', () {
    test('palette colors are defined', () {
      expect(AppColors.blueOptique, const Color(0xFF2E7DBA));
      expect(AppColors.success, const Color(0xFF2DA44E));
      expect(AppColors.warning, const Color(0xFFD4740C));
      expect(AppColors.critical, const Color(0xFFCF222E));
      expect(AppColors.darkBackground, const Color(0xFF0D0D0D));
      expect(AppColors.lightBackground, const Color(0xFFF5F3EF));
    });
  });

  group('AppSpacing', () {
    test('spacing scale is correct', () {
      expect(AppSpacing.xs, 4);
      expect(AppSpacing.sm, 8);
      expect(AppSpacing.md, 12);
      expect(AppSpacing.base, 16);
      expect(AppSpacing.lg, 20);
      expect(AppSpacing.xl, 24);
      expect(AppSpacing.xxl, 32);
      expect(AppSpacing.xxxl, 48);
      expect(AppSpacing.radiusCard, 16);
      expect(AppSpacing.radiusChip, 20);
      expect(AppSpacing.radiusButton, 12);
    });
  });

  group('AppTypography', () {
    testWidgets('textTheme contains all styles', (tester) async {
      final theme = AppTypography.textTheme;
      expect(theme.displayLarge, isNotNull);
      expect(theme.headlineMedium, isNotNull);
      expect(theme.titleMedium, isNotNull);
      expect(theme.bodyMedium, isNotNull);
      expect(theme.bodySmall, isNotNull);
      expect(theme.labelSmall, isNotNull);
    });

    testWidgets('display uses tabular figures', (tester) async {
      expect(
        AppTypography.display.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  });
}
