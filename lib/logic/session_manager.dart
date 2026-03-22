import 'dart:math';
import 'stuff_service.dart';

/// Manages the state of a stuff reading session.
/// Keeps track of previously read items to avoid repetition and handles
/// the logic for selecting the next item from content.
class SessionManager {
  StuffService _service;
  final Random _random = Random();
  
  /// Set of IDs of entries that have already been read in this session.
  final Set<String> _readEntryIds = {};
  
  /// The entry currently being read.
  StuffEntry? _currentEntry;
  
  /// The list of candidates found in the current content that are available.
  final List<String> _candidatesFromContent = [];

  SessionManager(this._service);

  /// Updates the service being used by the manager.
  void setService(StuffService service) {
    print('Entering SessionManager.setService');
    _service = service;
    resetSession();
    print('Exiting SessionManager.setService');
  }

  /// The current entry.
  StuffEntry? get currentEntry => _currentEntry;

  /// Starts a new session or continues by picking a random first word.
  Future<StuffEntry?> pickRandomWord() async {
    print('Entering SessionManager.pickRandomWord');
    final available = await _service.getAvailableEntryIds();
    if (available.isEmpty) {
      print('Exiting SessionManager.pickRandomWord - no entries available');
      return null;
    }

    // Filter out already read entries if possible
    final unread = available.where((id) => !_readEntryIds.contains(id)).toList();
    
    final pool = unread.isNotEmpty ? unread : available;
    final selectionId = pool[_random.nextInt(pool.length)];
    
    final result = await _setCurrentEntry(selectionId);
    print('Exiting SessionManager.pickRandomWord - selected: ${result?.title}');
    return result;
  }

  /// Sets the current entry and parses its content for potential next items.
  Future<StuffEntry?> _setCurrentEntry(String id) async {
    print('Entering SessionManager._setCurrentEntry with id: $id');
    final entry = await _service.getEntryById(id);
    if (entry == null) {
      print('Exiting SessionManager._setCurrentEntry - entry not found');
      return null;
    }

    _currentEntry = entry;
    _readEntryIds.add(id);
    _candidatesFromContent.clear();

    // Find candidates in the content
    final foundIds = _service.findEntryIdsInText(entry.content);
    for (var matchId in foundIds) {
      if (!_readEntryIds.contains(matchId)) {
        _candidatesFromContent.add(matchId);
      }
    }

    print('Exiting SessionManager._setCurrentEntry - candidates found: ${_candidatesFromContent.length}');
    return entry;
  }

  /// Picks the next word based on the rules:
  /// 1. Randomly from unread items found in the current content.
  /// 2. If exhausted, randomly from all unread items in the service.
  Future<StuffEntry?> pickNextWord() async {
    print('Entering SessionManager.pickNextWord');
    StuffEntry? result;
    if (_candidatesFromContent.isNotEmpty) {
      final nextId = _candidatesFromContent[_random.nextInt(_candidatesFromContent.length)];
      result = await _setCurrentEntry(nextId);
    } else {
      result = await pickRandomWord();
    }
    print('Exiting SessionManager.pickNextWord - selected: ${result?.title}');
    return result;
  }

  /// Resets the session history.
  void resetSession() {
    print('Entering SessionManager.resetSession');
    _readEntryIds.clear();
    _currentEntry = null;
    _candidatesFromContent.clear();
    print('Exiting SessionManager.resetSession');
  }
}

