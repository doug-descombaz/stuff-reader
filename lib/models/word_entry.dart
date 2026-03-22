class WordEntry {
  /// The unique identifier from the database.
  final int id;
  /// The word itself.
  final String word;
  /// The primary definition of the word.
  final String definition;
  /// A version of the definition cleaned for text-to-speech.
  final String cleanDefinition;

  /// Creates a new [WordEntry].
  WordEntry({
    required this.id,
    required this.word,
    required this.definition,
    required this.cleanDefinition,
  });

  /// Factory to create a [WordEntry] from a database row map.
  factory WordEntry.fromMap(Map<String, dynamic> map) {
    return WordEntry(
      id: map['id'] as int,
      word: map['word'] as String,
      definition: map['definition'] as String? ?? '',
      cleanDefinition: map['clean_definition'] as String? ?? '',
    );
  }

  /// Converts the entry to a map for database operations.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
    return other is WordEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
