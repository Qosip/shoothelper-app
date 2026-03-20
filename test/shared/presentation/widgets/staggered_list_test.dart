import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/presentation/widgets/staggered_list.dart';

void main() {
  group('StaggeredList', () {
    testWidgets('renders all children', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StaggeredList(
              children: [
                Text('Step 1'),
                Text('Step 2'),
                Text('Step 3'),
              ],
            ),
          ),
        ),
      );

      // Initially children may be at 0 opacity; pump to complete animation
      await tester.pumpAndSettle();

      expect(find.text('Step 1'), findsOneWidget);
      expect(find.text('Step 2'), findsOneWidget);
      expect(find.text('Step 3'), findsOneWidget);
    });

    testWidgets('children animate in over time', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StaggeredList(
              children: [
                Text('A'),
                Text('B'),
              ],
            ),
          ),
        ),
      );

      // At frame 0, SlideTransitions from StaggeredList exist
      expect(find.byType(SlideTransition), findsAtLeast(2));

      // After settling, all visible
      await tester.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('handles single child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StaggeredList(
              children: [Text('Only')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Only'), findsOneWidget);
    });
  });
}
