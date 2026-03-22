import '../logic/stuff_service.dart';

/// A concrete implementation of [StuffEntry] for a dictionary entry.
class WordEntry implements StuffEntry {
  /// The unique identifier from the database.
  final int idAsInt;
  
  @override
  String get id => idAsInt.toString();

  /// The word itself.
  final String word;

  @override
  String get title => word;

  /// The primary definition of the word.
  final String definition;

  @override
  String get content => definition;

  /// A version of the definition cleaned for text-to-speech.
  final String cleanDefinition;

  /// Creates a new [WordEntry].
  WordEntry({
    required this.idAsInt,
    required this.word,
    required this.definition,
    required this.cleanDefinition,
  });

  /// Factory to create a [WordEntry] from a database row map.
  factory WordEntry.fromMap(Map<String, dynamic> map) {
    return WordEntry(
      idAsInt: map['id'] as int,
      word: map['word'] as String,
      definition: map['definition'] as String? ?? '',
      cleanDefinition: map['clean_definition'] as String? ?? '',
    );
  }

  /// Converts the entry to a map for database operations.
  Map<String, dynamic> toMap() {
    return {
      'id': idAsInt,
      'word': word,
      'definition': definition,
      'clean_definition': cleanDefinition,
    };
  }

  @override
  String toString() => 'WordEntry(word: $word)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WordEntry && other.idAsInt == idAsInt;
  }

  @override
  int get hashCode => idAsInt.hashCode;
}

