import 'package:flutter_test/flutter_test.dart';
import 'package:musik_app/models/app_language.dart';

void main() {
  group('AppLanguage', () {
    setUp(() {
      AppLanguage.setLanguage('de');
    });


    group('setLanguage / currentLanguage', () {
      test('defaults to German', () {
        expect(AppLanguage.currentLanguage, 'de');
      });

      test('can switch to English', () {
        AppLanguage.setLanguage('en');
        expect(AppLanguage.currentLanguage, 'en');
      });

      test('can switch back to German', () {
        AppLanguage.setLanguage('en');
        AppLanguage.setLanguage('de');
        expect(AppLanguage.currentLanguage, 'de');
      });
    });


    group('get()', () {
      test('returns German translation when language is de', () {
        AppLanguage.setLanguage('de');
        expect(AppLanguage.get('play'), 'Abspielen');
        expect(AppLanguage.get('search'), 'Suchen');
        expect(AppLanguage.get('settings'), 'Einstellungen');
      });

      test('returns English translation when language is en', () {
        AppLanguage.setLanguage('en');
        expect(AppLanguage.get('play'), 'Play');
        expect(AppLanguage.get('search'), 'Search');
        expect(AppLanguage.get('settings'), 'Settings');
      });

      test('returns key itself when translation not found', () {
        AppLanguage.setLanguage('de');
        expect(AppLanguage.get('nonExistentKey'), 'nonExistentKey');

        AppLanguage.setLanguage('en');
        expect(AppLanguage.get('anotherMissingKey'), 'anotherMissingKey');
      });

      test('handles keys with spaces', () {
        AppLanguage.setLanguage('de');
        expect(AppLanguage.get('delete song'), 'Lied löschen');

        AppLanguage.setLanguage('en');
        expect(AppLanguage.get('delete song'), 'Delete song');
      });
    });


    group('navigation translations', () {
      test('German navigation terms', () {
        AppLanguage.setLanguage('de');
        expect(AppLanguage.get('home'), 'Start');
        expect(AppLanguage.get('library'), 'Bibliothek');
        expect(AppLanguage.get('nowPlaying'), 'Jetzt läuft');
      });

      test('English navigation terms', () {
        AppLanguage.setLanguage('en');
        expect(AppLanguage.get('home'), 'Home');
        expect(AppLanguage.get('library'), 'Library');
        expect(AppLanguage.get('nowPlaying'), 'Now Playing');
      });
    });

    group('playback translations', () {
      test('German playback terms', () {
        AppLanguage.setLanguage('de');
        expect(AppLanguage.get('shuffle'), 'Shuffle');
        expect(AppLanguage.get('queue'), 'Warteschlange');
        expect(AppLanguage.get('addToQueue'), 'Zur Warteschlange hinzufügen');
      });

      test('English playback terms', () {
        AppLanguage.setLanguage('en');
        expect(AppLanguage.get('shuffle'), 'Shuffle');
        expect(AppLanguage.get('queue'), 'Queue');
        expect(AppLanguage.get('addToQueue'), 'Add to queue');
      });
    });

    group('playlist translations', () {
      test('German playlist terms', () {
        AppLanguage.setLanguage('de');
        expect(AppLanguage.get('My Playlists'), 'Meine Playlists');
        expect(AppLanguage.get('Create Playlist'), 'Playlist erstellen');
        expect(AppLanguage.get('Playlist is empty'), 'Playlist ist leer');
      });

      test('English playlist terms', () {
        AppLanguage.setLanguage('en');
        expect(AppLanguage.get('My Playlists'), 'My Playlists');
        expect(AppLanguage.get('Create Playlist'), 'Create Playlist');
        expect(AppLanguage.get('Playlist is empty'), 'Playlist is empty');
      });
    });

    group('home screen translations', () {
      test('German home screen terms', () {
        AppLanguage.setLanguage('de');
        expect(AppLanguage.get('recentlyPlayed'), 'Zuletzt gehört');
        expect(AppLanguage.get('mostPlayed'), 'Meistgespielt');
        expect(AppLanguage.get('madeForYou'), 'Für dich erstellt');
        expect(AppLanguage.get('discover'), 'Entdecken');
        expect(AppLanguage.get('seeAll'), 'Alle');
      });

      test('English home screen terms', () {
        AppLanguage.setLanguage('en');
        expect(AppLanguage.get('recentlyPlayed'), 'Recently Played');
        expect(AppLanguage.get('mostPlayed'), 'Most Played');
        expect(AppLanguage.get('madeForYou'), 'Made For You');
        expect(AppLanguage.get('discover'), 'Discover');
        expect(AppLanguage.get('seeAll'), 'See All');
      });
    });

    group('track info translations', () {
      test('German track info terms', () {
        AppLanguage.setLanguage('de');
        expect(AppLanguage.get('metadataTitle'), 'Titel');
        expect(AppLanguage.get('metadataArtist'), 'Künstler');
        expect(AppLanguage.get('metadataAlbum'), 'Album');
        expect(AppLanguage.get('duration'), 'Dauer');
        expect(AppLanguage.get('unknown'), 'Unbekannt');
        expect(AppLanguage.get('unknownArtist'), 'Unbekannter Künstler');
      });

      test('English track info terms', () {
        AppLanguage.setLanguage('en');
        expect(AppLanguage.get('metadataTitle'), 'Title');
        expect(AppLanguage.get('metadataArtist'), 'Artist');
        expect(AppLanguage.get('metadataAlbum'), 'Album');
        expect(AppLanguage.get('duration'), 'Duration');
        expect(AppLanguage.get('unknown'), 'Unknown');
        expect(AppLanguage.get('unknownArtist'), 'Unknown Artist');
      });
    });


    group('getGeneratedPlaylistName()', () {
      test('translates known playlist names to German', () {
        AppLanguage.setLanguage('de');
        expect(AppLanguage.getGeneratedPlaylistName('Recently Played'), 'Zuletzt gehört');
        expect(AppLanguage.getGeneratedPlaylistName('Most Played'), 'Meistgespielt');
        expect(AppLanguage.getGeneratedPlaylistName('Rediscover'), 'Wiederentdecken');
        expect(AppLanguage.getGeneratedPlaylistName('Discover'), 'Entdecken');
        expect(AppLanguage.getGeneratedPlaylistName('More Like This'), 'Mehr davon');
      });

      test('translates known playlist names to English', () {
        AppLanguage.setLanguage('en');
        expect(AppLanguage.getGeneratedPlaylistName('Recently Played'), 'Recently Played');
        expect(AppLanguage.getGeneratedPlaylistName('Most Played'), 'Most Played');
        expect(AppLanguage.getGeneratedPlaylistName('Rediscover'), 'Rediscover');
        expect(AppLanguage.getGeneratedPlaylistName('Discover'), 'Discover');
        expect(AppLanguage.getGeneratedPlaylistName('More Like This'), 'More Like This');
      });

      test('returns original name for unknown playlist names', () {
        AppLanguage.setLanguage('de');
        expect(AppLanguage.getGeneratedPlaylistName('Custom Playlist'), 'Custom Playlist');
        expect(AppLanguage.getGeneratedPlaylistName('My Mix'), 'My Mix');

        AppLanguage.setLanguage('en');
        expect(AppLanguage.getGeneratedPlaylistName('Custom Playlist'), 'Custom Playlist');
      });
    });


    group('edge cases', () {
      test('handles empty key', () {
        expect(AppLanguage.get(''), '');
      });

      test('translations are case-sensitive', () {
        AppLanguage.setLanguage('en');
        // 'Play' with capital P doesn't exist, only 'play'
        expect(AppLanguage.get('Play'), 'Play'); // returns key itself
        expect(AppLanguage.get('play'), 'Play'); // returns translation
      });

      test('unsupported language falls back gracefully', () {
        AppLanguage.setLanguage('fr'); // French not supported
        // Should return the key itself since 'fr' has no translations
        expect(AppLanguage.get('play'), 'play');
      });
    });
  });
}
