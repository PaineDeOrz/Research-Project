// -----------------------------------------------------------------------------
// APPLICATION DATABASE
// -----------------------------------------------------------------------------
//
// Opens the app's SQLite database and ensures the schema exists.
// Schema is loaded from an asset file on first creation.
// Foreign keys are enabled on configure.
//
// -----------------------------------------------------------------------------

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../core/log_debug.dart';

class ApplicationDatabase {
  static const String _dbName = 'music.db';
  static const int version = 1; // Bump when schema changes
  static Database? _database;
  static Completer<Database>? _initCompleter;

  // Set to true to delete the database on startup (useful during development)
  static const bool yeetDatabaseOnStart = false;

  /// Returns a singleton instance of the database.
  /// `onCreate` runs the first time the database is created.
  /// `onUpgrade` runs when [version] is bumped.
  static Future<Database> get instance async {
    if (_database != null) return _database!;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<Database>();

    final dbDirectory = await getDatabasesPath();
    final dbPath = path.join(dbDirectory, _dbName);

    if (yeetDatabaseOnStart) {
      final exists = await databaseExists(dbPath);
      if (exists) {
        logDebug('DB: DELETING database (yeetDatabaseOnStart=true)');
        await deleteDatabase(dbPath);
        logDebug('DB: database deleted successfully');
      }
    }

    final exists = await databaseExists(dbPath);
    if (kDebugMode) {
      final status = exists ? 'opening existing' : 'creating new';
      print('DB: $status at $dbPath');
    }

    try {
      _database = await openDatabase(
        dbPath,
        version: version,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (database, _) async {
          logDebug('DB: running schema (v$version)');
          await _executeSchemaFromAsset(database, 'lib/db/schemas/schema_v1.sql');
          logDebug('DB: schema ready');
        },
        onUpgrade: (database, oldVersion, newVersion) async {
          logDebug('DB: upgrade requested $oldVersion -> $newVersion (no migration yet)');
          // TODO: for now nuke data (Clear app data)
        },
        onOpen: (database) async {
          final dbVersion = await database.getVersion();
          logDebug('DB: open (user_version=$dbVersion)');
        },
      );

      _initCompleter!.complete(_database!);
      return _database!;
    } catch (error) {
      _initCompleter!.completeError(error);
      _initCompleter = null;
      rethrow;
    }
  }

  // Loads a SQL asset file and executes it statement by statement
  static Future<void> _executeSchemaFromAsset(Database database, String assetPath) async {
    final sql = await rootBundle.loadString(assetPath);
    final statements = sql.split(';');

    for (final rawStatement in statements) {
      // Strip full line SQL comments before executing
      final statement = rawStatement
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('--'))
          .join('\n')
          .trim();
      if (statement.isEmpty) continue;
      await database.execute(statement);
    }
  }
}