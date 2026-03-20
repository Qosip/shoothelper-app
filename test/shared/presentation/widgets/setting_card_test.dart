import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shoothelper/shared/presentation/widgets/setting_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SettingCard', () {
    testWidgets('displays name, explanation, and value', (tester) async {
      await tester.pumpWidget(_wrap(
        const SettingCard(
          settingName: 'Ouverture',
          explanation: 'Grande ouverture pour le bokeh',
          valueDisplay: 'f/2.8',
        ),
      ));
      expect(find.text('Ouverture'), findsOneWidget);
      expect(find.text('Grande ouverture pour le bokeh'), findsOneWidget);
      expect(find.text('f/2.8'), findsOneWidget);
    });

    testWidgets('shows chevron when onTap is provided', (tester) async {
      await tester.pumpWidget(_wrap(
        SettingCard(
          settingName: 'ISO',
          explanation: 'test',
          valueDisplay: '400',
          onTap: () {},
        ),
      ));
      expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
    });

    testWidgets('does not show chevron when onTap is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const SettingCard(
          settingName: 'ISO',
          explanation: 'test',
          valueDisplay: '400',
        ),
      ));
      expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
    });

    testWidgets('renders all variants without error', (tester) async {
      for (final variant in SettingCardVariant.values) {
        await tester.pumpWidget(_wrap(
          SettingCard(
            settingName: 'Test',
            explanation: 'desc',
            valueDisplay: 'val',
            variant: variant,
          ),
        ));
        expect(find.text('Test'), findsOneWidget);
      }
    });

    testWidgets('iconForSetting returns correct icons', (tester) async {
      expect(SettingCard.iconForSetting('aperture'), LucideIcons.aperture);
      expect(SettingCard.iconForSetting('shutter_speed'), LucideIcons.timer);
      expect(SettingCard.iconForSetting('iso'), LucideIcons.gauge);
      expect(SettingCard.iconForSetting('af_mode'), LucideIcons.focus);
      expect(SettingCard.iconForSetting('unknown'), LucideIcons.settings);
    });
  });
}
