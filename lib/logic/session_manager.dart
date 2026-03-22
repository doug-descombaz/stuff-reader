import 'dart:math';
import '../models/word_entry.dart';
import '../services/dictionary_service.dart';

/// Manages the state of a dictionary reading session.
/// Keeps track of previously read words to avoid repetition and handles
/// the logic for selecting the next word from definitions.
class SessionManager {
  final DictionaryService _dictionaryService;
  final Random _random = Random();
  
  /// Set of IDs of words that have already been read in this session.
  final Set<int> _readWordIds = {};
  
  /// The word currently being read.
  WordEntry? _currentWord;
  
  /// The list of words found in the current definition that are available in the dictionary.
  final List<int> _candidatesFromDefinition = [];

  SessionManager(this._dictionaryService);

  /// The current word entry.
  WordEntry? get currentWord => _currentWord;

  /// Starts a new session or continues by picking a random first word.
  Future<WordEntry?> pickRandomWord() async {
    final available = _dictionaryService.availableRecords;
    if (available.isEmpty) return null;

    // Filter out already read words if possible
    final unread = available.where((e) => !_readWordIds.contains(e.id)).toList();
    
    final pool = unread.isNotEmpty ? unread : available;
    final selection = pool[_random.nextInt(pool.length)];
    
    return _setCurrentWord(selection.id);
  }

  /// Sets the current word and parses its definition for potential next words.
  Future<WordEntry?> _setCurrentWord(int id) async {
    final entry = await _dictionaryService.getWordById(id);
    if (entry == null) return null;

    _currentWord = entry;
    _readWordIds.add(id);
    _candidatesFromDefinition.clear();

    // Parse definitions for available words
    final wordsInDef = _parseWords(entry.definition);
    for (var w in wordsInDef) {
      final ids = _dictionaryService.findWordIds(w);
      if (ids != null) {
        for (var matchId in ids) {
          if (!_readWordIds.contains(matchId)) {
            _candidatesFromDefinition.add(matchId);
          }
        }
      }
    }

    return entry;
  }

  /// Picks the next word based on the rules:
  /// 1. Randomly from unread words in the current definition.
  /// 2. If exhausted, randomly from all unread words in the dictionary.
  Future<WordEntry?> pickNextWord() async {
    if (_candidatesFromDefinition.isNotEmpty) {
      final nextId = _candidatesFromDefinition[_random.nextInt(_candidatesFromDefinition.length)];
      return _setCurrentWord(nextId);
    } else {
      return pickRandomWord();
    }
  }

  /// Resets the session history.
  void resetSession() {
    _readWordIds.clear();
    _currentWord = null;
    _candidatesFromDefinition.clear();
  }

  /// Extracts words from a string using regex.
  List<String> _parseWords(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Z\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
