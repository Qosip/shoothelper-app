import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shoothelper/shared/presentation/widgets/shoot_chip.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ShootChip', () {
    testWidgets('displays label', (tester) async {
      await tester.pumpWidget(_wrap(const ShootChip(label: 'Portrait')));
      expect(find.text('Portrait'), findsOneWidget);
    });

    testWidgets('displays icon when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const ShootChip(label: 'Paysage', icon: LucideIcons.mountain),
      ));
      expect(find.byIcon(LucideIcons.mountain), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        ShootChip(label: 'Street', onTap: () => tapped = true),
      ));
      await tester.tap(find.text('Street'));
      expect(tapped, isTrue);
    });

    testWidgets('disabled state does not fire onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        ShootChip(
          label: 'Off',
          state: ShootChipState.disabled,
          onTap: () => tapped = true,
        ),
      ));
      await tester.tap(find.text('Off'));
      expect(tapped, isFalse);
    });

    testWidgets('renders all 4 states without error', (tester) async {
      for (final state in ShootChipState.values) {
        await tester.pumpWidget(_wrap(ShootChip(label: state.name, state: state)));
        expect(find.text(state.name), findsOneWidget);
      }
    });
  });
}
