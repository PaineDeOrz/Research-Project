import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musik_app/widgets/artwork_thumbnail.dart';

void main() {
  group('ArtworkThumbnail', () {
    testWidgets('shows placeholder icon when artworkPath is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArtworkThumbnail(artworkPath: null),
          ),
        ),
      );

      expect(find.byIcon(Icons.music_note), findsOneWidget);
    });

    testWidgets('shows placeholder icon when artworkPath is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArtworkThumbnail(artworkPath: ''),
          ),
        ),
      );

      expect(find.byIcon(Icons.music_note), findsOneWidget);
    });

    testWidgets('uses custom placeholder icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArtworkThumbnail(
              artworkPath: null,
              placeholderIcon: Icons.album,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.album), findsOneWidget);
      expect(find.byIcon(Icons.music_note), findsNothing);
    });

    testWidgets('applies default size of 52', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArtworkThumbnail(artworkPath: null),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxWidth, 52);
      expect(container.constraints?.maxHeight, 52);
    });

    testWidgets('applies custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArtworkThumbnail(
              artworkPath: null,
              size: 100,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxWidth, 100);
      expect(container.constraints?.maxHeight, 100);
    });

    testWidgets('applies border radius via ClipRRect', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArtworkThumbnail(
              artworkPath: null,
              borderRadius: 16,
            ),
          ),
        ),
      );

      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clipRRect.borderRadius, BorderRadius.circular(16));
    });

    testWidgets('has container with background color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArtworkThumbnail(artworkPath: null),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.color, isNotNull);
    });

  });
}
