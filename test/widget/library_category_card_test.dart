import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musik_app/widgets/library_category_card.dart';

void main() {
  group('LibraryCategoryCard', () {
    testWidgets('displays title text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryCategoryCard(
              title: 'Test Category',
              icon: Icons.music_note,
              gradientColors: const [Colors.blue, Colors.purple],
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Category'), findsOneWidget);
    });

    testWidgets('displays icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryCategoryCard(
              title: 'Category',
              icon: Icons.album,
              gradientColors: const [Colors.red, Colors.orange],
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.album), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryCategoryCard(
              title: 'Tappable',
              icon: Icons.touch_app,
              gradientColors: const [Colors.green, Colors.teal],
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(LibraryCategoryCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('renders with InkWell for tap feedback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryCategoryCard(
              title: 'Category',
              icon: Icons.folder,
              gradientColors: const [Colors.amber, Colors.yellow],
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('has rounded corners via ClipRRect', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryCategoryCard(
              title: 'Rounded',
              icon: Icons.rounded_corner,
              gradientColors: const [Colors.pink, Colors.purple],
              onTap: () {},
            ),
          ),
        ),
      );

      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect).first);
      expect(clipRRect.borderRadius, BorderRadius.circular(24));
    });

    testWidgets('title has correct style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryCategoryCard(
              title: 'Styled Title',
              icon: Icons.style,
              gradientColors: const [Colors.cyan, Colors.blue],
              onTap: () {},
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Styled Title'));
      expect(text.style?.fontSize, 16);
      expect(text.style?.fontWeight, FontWeight.bold);
      expect(text.textAlign, TextAlign.center);
    });
  });
}
