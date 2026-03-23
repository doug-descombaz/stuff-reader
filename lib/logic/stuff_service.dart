/// Defines the common interface for "stuff" entries.
/// An entry represents a piece of content with a title and a body.
abstract class StuffEntry {
  /// Unique identifier for this entry within its service.
  String get id;

  /// The title of the entry (e.g., the word in a dictionary, or article title).
  String get title;

  /// The main content of the entry (e.g., the definition or article body).
  String get content;
}

/// Base class for all services that provide "stuff" to the crawler.
abstract class StuffService {
  /// A unique identifier for the service itself.
  String get serviceId;

  /// The canonical English title of the service.
  String get canonicalTitle;

  /// Initializes the service and its data source.
  Future<void> init();

  /// Closes any resources held by the service.
  Future<void> dispose();

  /// Retrieves a specific entry by its ID.
  Future<StuffEntry?> getEntryById(String id);

  /// Returns a list of all available entry IDs.
  Future<List<String>> getAvailableEntryIds();

  /// Finds potential entry IDs mentioned within a given text.
  /// Used for finding the next item to read.
  List<String> findEntryIdsInText(String text);
}
