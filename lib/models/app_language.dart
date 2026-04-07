// -----------------------------------------------------------------------------
// APP LANGUAGE
// -----------------------------------------------------------------------------
//
// Stores translations for German and English and provides lookup by key.
//
// -----------------------------------------------------------------------------

class AppLanguage {
  static String _currentLanguage = 'de';

  static String get currentLanguage => _currentLanguage;

  static void setLanguage(String language) {
    _currentLanguage = language;
  }

  /// Returns the translated string for [key] in the current language.
  /// Falls back to the key itself if no translation is found.
  static String get(String key) {
    final translations = {
      'de': {
        'tracks' : 'Titel',
        'delete song' : 'Lied löschen',
        'addToQueue' : 'Zur Warteschlange hinzufügen',
        'play' : 'Abspielen',
        'queue' : 'Warteschlange',
        'noSongsFound' : 'Keine Songs gefunden',
        'titleHomeScreen' : 'Musik App',
        'listeningHistoryDisplay' : 'Der Verlauf der Wiedergaben wird hier angezeigt.',
        'listeningHistory' : 'Hörverlauf',
        'nowPlaying': 'Jetzt läuft',
        'home': 'Start',
        'search': 'Suchen',
        'library': 'Bibliothek',
        'settings': 'Einstellungen',
        'songTitle': 'Song Titel',
        'artistName': 'Künstler Name',
        'autoPlaylists': 'Automatische Playlists',
        'basedOnGenre': 'Basierend auf Genre',
        'offlineRecommendations': 'Offline Empfehlungen',
        'similarSongs': 'Ähnliche Songs',
        'autoPlay': 'Automatisch weiterspielen',
        'mostPlayed': 'Meistgespielt',
        'topSongs': 'Deine Top Songs',
        'recentlyPlayed': 'Zuletzt gehört',
        'madeForYou': 'Für dich erstellt',
        'discover': 'Entdecken',
        'rediscover': 'Wiederentdecken',
        'moreLikeThis': 'Mehr davon',
        'startListening': 'Fang an zu hören',
        'playMusicToSeeRecommendations': 'Spiele Musik ab, um personalisierte Empfehlungen zu erhalten.',
        'shuffle': 'Shuffle',
        'timer': 'Timer',
        'trackInfo': 'Track Information',
        'editMetadata': 'Metadaten bearbeiten',
        'metadataTitle': 'Titel',
        'metadataArtist': 'Künstler',
        'metadataAlbum': 'Album',
        'metadataYear': 'Jahr',
        'metadataTrackNumber': 'Titelnummer',
        'bitrate': 'Bitrate',
        'sampleRate': 'Sample Rate',
        'format': 'Format',
        'size': 'Größe',
        'duration': 'Dauer',
        'playbackSpeed': 'Wiedergabegeschwindigkeit',
        'shuffleMode': 'Shuffle Modus',
        'trulyRandom': 'Wirklich zufällig',
        'classicShuffle': 'Klassisches Shuffle',
        'favorRare': 'Selten gespielte bevorzugen',
        'favorRecent': 'Kürzlich hinzugefügte bevorzugen',
        'sleepTimer': 'Sleep Timer',
        'minutes': 'Minuten',
        'timerSet': 'Sleep Timer auf {time} Minuten gesetzt',
        'lyrics': 'Lyrics',
        'lyricsDisplay': 'Lyrics werden hier angezeigt',
        'lrcSupport': 'Unterstützt .lrc Dateien',
        'searchFunction': 'Suchfunktion',
        'yourLibrary': 'Deine Musik Bibliothek',
        'darkMode': 'Dark Mode',
        'equalizer': 'Equalizer',
        'audioNormalizer': 'Audio Normalizer',
        'volumeLevel': 'Lautstärke angleichen',
        'gaplessPlayback': 'Gapless Playback',
        'seamlessPlay': 'Nahtlose Wiedergabe',
        'afterSongEnds': 'Nach Song Ende',
        'continueSimilar': 'Ähnliche Songs weiterspielen',
        'language': 'Sprache',
        'german': 'Deutsch',
        'english': 'English',

        'My Playlists': 'Meine Playlists',
        'Create Playlist': 'Playlist erstellen',
        'Multi-Select': 'Mehrfachauswahl',
        'No playlists available': 'Keine Playlists verfügbar',
        'No playlists yet':	'Noch keine Playlists',
        'Playlist name': 'Playlist-Name',
        'Cancel': 'Abbrechen',
        'Save': 'Speichern',
        'Add selected to Playlist': 'Auswahl zur Playlist hinzufügen',
        'Add to a Playlist': 'Zu einer Playlist hinzufügen',
        'Delete Playlist': 'Playlist löschen',
        'Reload Playlist': 'Playlist neu laden',
        'Playlist is empty': 'Playlist ist leer',
        'Rename Playlist': 'Playlist umbenennen',
        'Delete this Playlist': 'Playlist löschen',
        'Are you sure you want to delete this playlist?': 'Möchtest du diese Playlist wirklich löschen?',
        "No, don't delete": 'Nein, nicht löschen',
        'Yes, delete': 'Ja, löschen',
        'Remove from Playlist': 'Aus Playlist entfernen',

        // Sleep Timer
        'Sleep Timer': 'Schlaf-Timer',
        '5 minutes': '5 Minuten',
        '10 minutes': '10 Minuten',
        '15 minutes': '15 Minuten',
        '30 minutes': '30 Minuten',
        '45 minutes': '45 Minuten',
        '1 hour': '1 Stunde',
        '10 seconds (Debug)': '10 Sekunden (Debug)',
        'Custom': 'Benutzerdefiniert',
        'Set custom time': 'Benutzerdefinierte Zeit einstellen',
        'Hours': 'Stunden',
        'Minutes': 'Minuten',
        'Set Timer': 'Timer einstellen',
        'Time remaining': 'Verbleibende Zeit',
        'Cancel Timer': 'Timer abbrechen',

        // Onboarding
        'Welcome': 'Willkommen',
        'welcomeMessage': 'Willkommen bei Musik App! Lass uns ein paar Dinge einrichten.',
        'Choose Language': 'Sprache wählen',
        'chooseLanguageMessage': 'Wähle deine bevorzugte Sprache.',
        'Choose Theme': 'Theme wählen',
        'chooseThemeMessage': 'Wähle zwischen hellem und dunklem Modus.',
        'Light': 'Hell',
        'Dark': 'Dunkel',
        'Playback Settings': 'Wiedergabe-Einstellungen',
        'playbackSettingsMessage': 'Optimiere dein Hörerlebnis mit diesen Einstellungen.',
        'On': 'An',
        'Off': 'Aus',
        'All Set!': 'Alles bereit!',
        'allSetMessage': 'Du bist bereit loszulegen. Deine Musikbibliothek wird jetzt geladen.',
        'Next': 'Weiter',
        'Back': 'Zurück',
        'Get Started': 'Los geht\'s',
        'Track Info': 'Track Info',
        'Close': 'Schließen',

        // Theme Color Settings
        'Theme Color': 'Theme Farbe',
        'themeColorSubtitle': 'Wähle die Farbquelle für das App-Theme',
        'Default Purple': 'Standard Lila',
        'Dynamic (Album Art)': 'Dynamisch (Album Art)',
        'Material You': 'Material You',
        'Custom Color': 'Eigene Farbe',
        'Choose Color': 'Farbe wählen',

        // Search
        'Start typing to search': 'Tippe um zu suchen',

        // Genre Mixes
        'genreMixes': 'Genre Mixes',

        // See All
        'seeAll': 'Alle',

        // After Song Ends
        'afterSongEndRepeat': 'Wiederholen',
        'afterSongEndStop': 'Stoppen',
        'afterSongEndSimilar': 'Ähnliche Songs spielen',

        // Equalizer
        'No equalizer app found': 'Keine Equalizer App gefunden',
        'iOS EQ instructions': 'Du kannst den Music EQ in den Einstellungen nutzen:\nEinstellungen → Apps → Musik → EQ',
        'OK': 'OK',

        // Import
        'importFiles': 'Dateien importieren',
        'importAudioFiles': 'Audiodateien importieren',
        'importedFilesCount': '{count} Datei(en) importiert',

        // Search
        'searchForSongs': 'Nach Songs suchen...',

        // Playlist messages
        'addedToPlaylist': 'Hinzugefügt zu',
        'removedFromPlaylist': 'Entfernt aus',

        // Lyrics
        'noLyricsFound': 'Keine Lyrics gefunden',

        // Track info
        'genre': 'Genre',
        'fileSize': 'Dateigröße',
        'path': 'Pfad',
        'unknown': 'Unbekannt',
        'unknownArtist': 'Unbekannter Künstler',
        'trackNumberShort': 'Titel Nr.',

        // Actions
        'Select': 'Auswählen',
        'Tracks': 'Titel',
        'Add to Playlist': 'Zur Playlist hinzufügen',
      },
      'en': {
        'tracks' : 'Tracks',
        'delete song' : 'Delete song',
        'addToQueue' : 'Add to queue',
        'play' : 'Play',
        'queue' : 'Queue',
        'noSongsFound' : 'No songs found',
        'titleHomeScreen' : 'Music App',
        'listeningHistoryDisplay' : 'Listening history will be shown here',
        'listeningHistory' : 'Listening History',
        'nowPlaying': 'Now Playing',
        'home': 'Home',
        'search': 'Search',
        'library': 'Library',
        'settings': 'Settings',
        'songTitle': 'Song Title',
        'artistName': 'Artist Name',
        'autoPlaylists': 'Auto Playlists',
        'basedOnGenre': 'Based on Genre',
        'offlineRecommendations': 'Offline Recommendations',
        'similarSongs': 'Similar Songs',
        'autoPlay': 'Auto-play',
        'mostPlayed': 'Most Played',
        'topSongs': 'Your Top Songs',
        'recentlyPlayed': 'Recently Played',
        'madeForYou': 'Made For You',
        'discover': 'Discover',
        'rediscover': 'Rediscover',
        'moreLikeThis': 'More Like This',
        'startListening': 'Start listening',
        'playMusicToSeeRecommendations': 'Play some music to see personalized recommendations.',
        'shuffle': 'Shuffle',
        'timer': 'Timer',
        'trackInfo': 'Track Information',
        'editMetadata': 'Edit Metadata',
        'metadataTitle': 'Title',
        'metadataArtist': 'Artist',
        'metadataAlbum': 'Album',
        'metadataYear': 'Year',
        'metadataTrackNumber': 'Track Number',
        'bitrate': 'Bitrate',
        'sampleRate': 'Sample Rate',
        'format': 'Format',
        'size': 'Size',
        'duration': 'Duration',
        'playbackSpeed': 'Playback Speed',
        'shuffleMode': 'Shuffle Mode',
        'trulyRandom': 'Truly Random',
        'classicShuffle': 'Classic Shuffle',
        'favorRare': 'Favor rarely played',
        'favorRecent': 'Favor recently added',
        'sleepTimer': 'Sleep Timer',
        'minutes': 'Minutes',
        'timerSet': 'Sleep timer set to {time} minutes',
        'lyrics': 'Lyrics',
        'lyricsDisplay': 'Lyrics will be displayed here',
        'lrcSupport': 'Supports .lrc files',
        'searchFunction': 'Search Function',
        'yourLibrary': 'Your Music Library',
        'darkMode': 'Dark Mode',
        'equalizer': 'Equalizer',
        'audioNormalizer': 'Audio Normalizer',
        'volumeLevel': 'Level volume',
        'gaplessPlayback': 'Gapless Playback',
        'seamlessPlay': 'Seamless playback',
        'afterSongEnds': 'After Song Ends',
        'continueSimilar': 'Continue with similar songs',
        'language': 'Language',
        'german': 'Deutsch',
        'english': 'English',

        'My Playlists': 'My Playlists',
        'Create Playlist': 'Create Playlist',
        'Multi-Select':	'Multi-Select',
        'No playlists available': 'No playlists available',
        'No playlists yet':	'No playlists yet',	
        'Playlist name': 'Playlist name',
        'Cancel': 'Cancel',
        'Save': 'Save',
        'Add selected to Playlist': 'Add selected to Playlist',
        'Add to a Playlist': 'Add to a Playlist',
        'Delete Playlist': 'Delete Playlist',
        'Reload Playlist': 'Reload Playlist',
        'Playlist is empty': 'Playlist is empty',
        'Rename Playlist': 'Rename Playlist',
        'Delete this Playlist': 'Delete this Playlist',
        'Are you sure you want to delete this playlist?': 'Are you sure you want to delete this playlist?',
        "No, don't delete": "No, don't delete",
        'Yes, delete': 'Yes, delete',
        'Remove from Playlist': 'Remove from Playlist',

        // Sleep Timer
        'Sleep Timer': 'Sleep Timer',
        '5 minutes': '5 minutes',
        '10 minutes': '10 minutes',
        '15 minutes': '15 minutes',
        '30 minutes': '30 minutes',
        '45 minutes': '45 minutes',
        '1 hour': '1 hour',
        '10 seconds (Debug)': '10 seconds (Debug)',
        'Custom': 'Custom',
        'Set custom time': 'Set custom time',
        'Hours': 'Hours',
        'Minutes': 'Minutes',
        'Set Timer': 'Set Timer',
        'Time remaining': 'Time remaining',
        'Cancel Timer': 'Cancel Timer',

        // Onboarding
        'Welcome': 'Welcome',
        'welcomeMessage': 'Welcome to Music App! Let\'s set up a few things.',
        'Choose Language': 'Choose Language',
        'chooseLanguageMessage': 'Select your preferred language.',
        'Choose Theme': 'Choose Theme',
        'chooseThemeMessage': 'Choose between light and dark mode.',
        'Light': 'Light',
        'Dark': 'Dark',
        'Playback Settings': 'Playback Settings',
        'playbackSettingsMessage': 'Optimize your listening experience with these settings.',
        'On': 'On',
        'Off': 'Off',
        'All Set!': 'All Set!',
        'allSetMessage': 'You\'re ready to go. Your music library will be loaded now.',
        'Next': 'Next',
        'Back': 'Back',
        'Get Started': 'Get Started',
        'Track Info': 'Track Info',
        'Close': 'Close',

        // Theme Color Settings
        'Theme Color': 'Theme Color',
        'themeColorSubtitle': 'Choose the color source for the app theme',
        'Default Purple': 'Default Purple',
        'Dynamic (Album Art)': 'Dynamic (Album Art)',
        'Material You': 'Material You',
        'Custom Color': 'Custom Color',
        'Choose Color': 'Choose Color',

        // Search
        'Start typing to search': 'Start typing to search',

        // Genre Mixes
        'genreMixes': 'Genre Mixes',

        // See All
        'seeAll': 'See All',

        // After Song Ends
        'afterSongEndRepeat': 'Repeat',
        'afterSongEndStop': 'Stop',
        'afterSongEndSimilar': 'Play similar songs',

        // Equalizer
        'No equalizer app found': 'No equalizer app found',
        'iOS EQ instructions': 'You can use the Music EQ in Settings:\nSettings → Apps → Music → EQ',
        'OK': 'OK',

        // Import
        'importFiles': 'Import Files',
        'importAudioFiles': 'Import Audio Files',
        'importedFilesCount': 'Imported {count} file(s)',

        // Search
        'searchForSongs': 'Search for songs...',

        // Playlist messages
        'addedToPlaylist': 'Added to',
        'removedFromPlaylist': 'Removed from',

        // Lyrics
        'noLyricsFound': 'No lyrics found',

        // Track info
        'genre': 'Genre',
        'fileSize': 'File Size',
        'path': 'Path',
        'unknown': 'Unknown',
        'unknownArtist': 'Unknown Artist',
        'trackNumberShort': 'Track #',

        // Actions
        'Select': 'Select',
        'Tracks': 'Tracks',
        'Add to Playlist': 'Add to Playlist',
      },
    };

    return translations[_currentLanguage]?[key] ?? key;
  }

  /// Translates generated playlist names stored as English keys in the DB.
  static String getGeneratedPlaylistName(String dbName) {
    const nameToKey = {
      'Recently Played': 'recentlyPlayed',
      'Most Played': 'mostPlayed',
      'Rediscover': 'rediscover',
      'Discover': 'discover',
      'More Like This': 'moreLikeThis',
    };
    final key = nameToKey[dbName];
    if (key == null) return dbName;
    return get(key);
  }
}