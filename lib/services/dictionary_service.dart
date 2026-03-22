import '../logic/stuff_service.dart';
import '../models/word_entry.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Service to handle dictionary database operations.
/// It copies the database from assets to local storage and provides methods to query words.
class DictionaryService implements StuffService {
  @override
  String get serviceId => 'dictionary';

  @override
  String get canonicalTitle => 'Dictionary';

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
  @override
  Future<void> init() async {
    print('Entering DictionaryService.init');
    if (_initialized) {
      print('Exiting DictionaryService.init (already initialized)');
      return;
    }

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
    print('Exiting DictionaryService.init (successfully initialized)');
  }

  /// Fetches a specific word entry by ID.
  @override
  Future<WordEntry?> getEntryById(String id) async {
    print('Entering DictionaryService.getEntryById with id: $id');
    final int? intId = int.tryParse(id);
    if (intId == null) {
      print('Exiting DictionaryService.getEntryById (invalid id format)');
      return null;
    }

    final result = await _db.query(
      'dictionary',
      where: 'id = ?',
      whereArgs: [intId],
    );
    if (result.isEmpty) {
      print('Exiting DictionaryService.getEntryById (word not found)');
      return null;
    }
    final wordEntry = WordEntry.fromMap(result.first);
    print('Exiting DictionaryService.getEntryById (found ${wordEntry.word})');
    return wordEntry;
  }

  @override
  Future<List<String>> getAvailableEntryIds() async {
    print('Entering DictionaryService.getAvailableEntryIds');
    if (!_initialized) await init();
    final result = _availableRecords.map((e) => e.id.toString()).toList();
    print('Exiting DictionaryService.getAvailableEntryIds - count: ${result.length}');
    return result;
  }

  @override
  List<String> findEntryIdsInText(String text) {
    print('Entering DictionaryService.findEntryIdsInText');
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Z\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty);

    final List<String> foundIds = [];
    for (var w in words) {
      final ids = _wordToIds[w];
      if (ids != null) {
        foundIds.addAll(ids.map((id) => id.toString()));
      }
    }
    print('Exiting DictionaryService.findEntryIdsInText - found: ${foundIds.length}');
    return foundIds;
  }

  /// Closes the database connection.
  @override
  Future<void> dispose() async {
    print('Entering DictionaryService.dispose');
    if (_initialized) {
      await _db.close();
    }
    print('Exiting DictionaryService.dispose');
  }
}
