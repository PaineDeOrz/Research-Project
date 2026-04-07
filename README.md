# Musik App

A music player for Android and iOS built with Flutter. This is a research project at the University of Stuttgart about the development of an offline music player with Flutter and the challenges it comes with.

## Features

- Gapless playback
- Synced lyrics (LRC files)
- Artist images and bios from MusicBrainz
- ReplayGain volume normalization
- Listening history and recommendations
- Dynamic theming from album artwork

## Building

```
flutter pub get
flutter run
```

Requires Dart SDK 3.9.2+.

### Dependencies

The app uses `just_audio` for playback, `sqflite` for the local database, and `on_audio_query` for Android MediaStore access (with a local patch in `plugins/`). ReplayGain tags are extracted using `audio_metadata_reader` and `id3_codec`.

## How it works

On Android, tracks come from MediaStore. On iOS, users import files via a file picker. Either way, everything gets synced to SQLite.

The playback code lives in `lib/playback/`:
- `PlaybackController` - main orchestrator, exposes state via ValueNotifiers
- `PlaybackQueue` - handles queue, shuffle, repeat
- `GaplessPlaybackHandler` - preloads next track for seamless transitions
- `MusikAudioHandler` - system media controls (lock screen, notifications)

## Project structure

```
lib/
├── core/           # utilities
├── data/           # repositories and services
├── db/             # SQLite, DAOs, schema
├── models/         # Track, Album, Playlist, etc
├── playback/       # player, queue, gapless
├── screens/        # UI
├── services/       # platform-specific stuff
├── theme/          # Material 3, dynamic colors
└── widgets/        # shared components
```

Architecture is DAO → Repository → UI.

## Tests

```
flutter test
```

Unit tests cover playback queue logic, ReplayGain conversion, LRC parsing, and model mappers. Widget tests for the reusable UI components. Integration test launches the app and checks it doesn't crash.

Integration tests need a device/emulator:
```
flutter test integration_test/app_test.dart
```

## CI

GitLab CI runs `flutter analyze` and `flutter test` on push.
