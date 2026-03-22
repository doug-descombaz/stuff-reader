import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/word_entry.dart';

/// Service to handle dictionary database operations.
/// It copies the database from assets to local storage and provides methods to query words.
class DictionaryService {
  late Database _db;
  bool _initialized = false;

  /// Map word strings to lists of record IDs for fast lookups.
  /// Used for finding the next word from within a definition.
  final Map<String, List<int>> _wordToIds = {};

  /// Stores a list of all available records as (id, word).
  List<({int id, String word})> _availableRecords = [];

  /// Returns the list of all available word-ID pairs.
  List<({int id, String word})> get availableRecords => _availableRecords;

  /// Initializes the database on MacOS.
  /// Copies assets/dictionary.db to a local directory if it hasn't been copied yet.
  Future<void> init() async {
    if (_initialized) return;

    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dictionary.db');

    final exists = File(path).existsSync();

    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      final data = await rootBundle.load('assets/dictionary.db');
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await File(path).writeAsBytes(bytes, flush: true);
    }

    _db = await openDatabase(path);

    // Cache all words for random access and matching definitions
    final result = await _db.rawQuery('SELECT id, word FROM dictionary');
    _availableRecords = result
        .map(
          (row) => (
            id: row['id'] as int,
            word: (row['word'] as String).toLowerCase(),
          ),
        )
        .toList();

    for (var entry in _availableRecords) {
      _wordToIds.putIfAbsent(entry.word, () => []).add(entry.id);
    }

    _initialized = true;
  }

  /// Fetches a specific word entry by ID.
  Future<WordEntry?> getWordById(int id) async {
    final result = await _db.query(
      'dictionary',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return WordEntry.fromMap(result.first);
  }

  /// Checks if a word exists and returns all matching record IDs.
  List<int>? findWordIds(String word) {
    return _wordToIds[word.toLowerCase()];
  }

  /// Closes the database connection.
  Future<void> dispose() async {
    if (_initialized) {
      await _db.close();
    }
  }
}
