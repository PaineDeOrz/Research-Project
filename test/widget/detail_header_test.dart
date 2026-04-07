import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musik_app/widgets/detail_header.dart';

void main() {
  group('DetailActionButton', () {
    testWidgets('displays icon and label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailActionButton(
              icon: Icons.play_arrow,
              label: 'Play',
              onTap: () {},
              isPrimary: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
    });

    testWidgets('calls onTap when pressed', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailActionButton(
              icon: Icons.shuffle,
              label: 'Shuffle',
              onTap: () => tapped = true,
              isPrimary: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DetailActionButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('handles null onTap gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DetailActionButton(
              icon: Icons.play_arrow,
              label: 'Play',
              onTap: null,
              isPrimary: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DetailActionButton));
      await tester.pump();
    });

    testWidgets('primary style uses colorScheme.primary background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: Scaffold(
            body: DetailActionButton(
              icon: Icons.play_arrow,
              label: 'Play',
              onTap: () {},
              isPrimary: true,
            ),
          ),
        ),
      );

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(DetailActionButton),
          matching: find.byType(Material),
        ),
      );

      expect(material.color, isNotNull);
      expect(material.color?.alpha, greaterThan(200));
    });

    testWidgets('secondary style uses semi-transparent background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailActionButton(
              icon: Icons.shuffle,
              label: 'Shuffle',
              onTap: () {},
              isPrimary: false,
            ),
          ),
        ),
      );

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(DetailActionButton),
          matching: find.byType(Material),
        ),
      );

      expect(material.color, isNotNull);
    });

    testWidgets('has rounded border radius of 24', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailActionButton(
              icon: Icons.play_arrow,
              label: 'Play',
              onTap: () {},
              isPrimary: true,
            ),
          ),
        ),
      );

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(DetailActionButton),
          matching: find.byType(Material),
        ),
      );

      expect(material.borderRadius, BorderRadius.circular(24));
    });

    testWidgets('label has bold font weight', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailActionButton(
              icon: Icons.play_arrow,
              label: 'Play',
              onTap: () {},
              isPrimary: true,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Play'));
      expect(text.style?.fontWeight, FontWeight.w600);
    });
  });

  group('CollapsedDetailTitle', () {
    testWidgets('displays title and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsedDetailTitle(
              title: 'Album Title',
              subtitle: '10 tracks',
              artworkPath: null,
              placeholderIcon: Icons.album,
            ),
          ),
        ),
      );

      expect(find.text('Album Title'), findsOneWidget);
      expect(find.text('10 tracks'), findsOneWidget);
    });

    testWidgets('shows placeholder icon when no artwork', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsedDetailTitle(
              title: 'Title',
              subtitle: 'Subtitle',
              artworkPath: null,
              placeholderIcon: Icons.album,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.album), findsOneWidget);
    });

    testWidgets('shows placeholder icon when artwork path is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsedDetailTitle(
              title: 'Title',
              subtitle: 'Subtitle',
              artworkPath: '',
              placeholderIcon: Icons.person,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('uses custom placeholder icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsedDetailTitle(
              title: 'Artist',
              subtitle: '5 albums',
              artworkPath: null,
              placeholderIcon: Icons.person,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.album), findsNothing);
    });

    testWidgets('has 32x32 thumbnail size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsedDetailTitle(
              title: 'Title',
              subtitle: 'Subtitle',
              artworkPath: null,
              placeholderIcon: Icons.album,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(CollapsedDetailTitle),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.constraints?.maxWidth, 32);
      expect(container.constraints?.maxHeight, 32);
    });

    testWidgets('title has correct style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsedDetailTitle(
              title: 'Styled Title',
              subtitle: 'Subtitle',
              artworkPath: null,
              placeholderIcon: Icons.album,
            ),
          ),
        ),
      );

      final titleText = tester.widget<Text>(find.text('Styled Title'));
      expect(titleText.style?.fontSize, 14);
      expect(titleText.style?.fontWeight, FontWeight.w600);
      expect(titleText.maxLines, 1);
      expect(titleText.overflow, TextOverflow.ellipsis);
    });

    testWidgets('subtitle has smaller font size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsedDetailTitle(
              title: 'Title',
              subtitle: 'Small Subtitle',
              artworkPath: null,
              placeholderIcon: Icons.album,
            ),
          ),
        ),
      );

      final subtitleText = tester.widget<Text>(find.text('Small Subtitle'));
      expect(subtitleText.style?.fontSize, 10);
    });

  });

  group('DetailHeaderArtwork', () {
    testWidgets('shows placeholder icon when no artwork', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DetailHeaderArtwork(
              artworkPath: null,
              hasArtwork: false,
              placeholderIcon: Icons.album,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.album), findsOneWidget);
    });

    testWidgets('has 120x120 size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DetailHeaderArtwork(
              artworkPath: null,
              hasArtwork: false,
              placeholderIcon: Icons.album,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(DetailHeaderArtwork),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.constraints?.maxWidth, 120);
      expect(container.constraints?.maxHeight, 120);
    });

    testWidgets('has rounded corners with radius 12', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DetailHeaderArtwork(
              artworkPath: null,
              hasArtwork: false,
              placeholderIcon: Icons.album,
            ),
          ),
        ),
      );

      final clipRRect = tester.widget<ClipRRect>(
        find.descendant(
          of: find.byType(DetailHeaderArtwork),
          matching: find.byType(ClipRRect),
        ),
      );

      expect(clipRRect.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('placeholder icon has size 64', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DetailHeaderArtwork(
              artworkPath: null,
              hasArtwork: false,
              placeholderIcon: Icons.music_note,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.music_note));
      expect(icon.size, 64);
    });
  });
}
