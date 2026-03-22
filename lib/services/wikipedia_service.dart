import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../logic/stuff_service.dart';

/// Documentation for classes in this file:
/// 1. [WikipediaEntry]: A concrete implementation of [StuffEntry] for a Wikipedia article.
/// 2. [WikipediaStuffService]: A shell implementation of [StuffService] for Wikipedia.

/// A concrete implementation of [StuffEntry] for a Wikipedia article.
class WikipediaEntry implements StuffEntry {
  @override
  final String id;
  @override
  final String title;
  @override
  final String content;

  WikipediaEntry({
    required this.id,
    required this.title,
    required this.content,
  });
}

/// A shell implementation of [StuffService] for Wikipedia.
/// This implementation fetches real content from the Wikipedia API.
class WikipediaStuffService implements StuffService {
  @override
  String get serviceId => 'wikipedia';

  @override
  String get canonicalTitle => 'Wikipedia';

  bool _initialized = false;

  /// Discovered article titles from current and previous articles.
  final Set<String> _discoveredTitles = {};

  /// Cached entries to avoid redundant network calls within a session.
  final Map<String, WikipediaEntry> _cache = {};

  @override
  Future<void> init() async {
    print('Entering WikipediaStuffService.init');
    _initialized = true;
    print('Exiting WikipediaStuffService.init');
  }

  @override
  Future<void> dispose() async {
    print('Entering WikipediaStuffService.dispose');
    _initialized = false;
    _discoveredTitles.clear();
    _cache.clear();
    print('Exiting WikipediaStuffService.dispose');
  }

  @override
  Future<WikipediaEntry?> getEntryById(String id) async {
    print('Entering WikipediaStuffService.getEntryById with id: $id');
    if (!_initialized) await init();

    WikipediaEntry? result;
    if (id == 'random') {
      result = await _fetchRandomArticle();
    } else if (_cache.containsKey(id)) {
      result = _cache[id];
    } else {
      result = await _fetchArticleByTitle(id);
    }

    print(
      'Exiting WikipediaStuffService.getEntryById - found: ${result != null}',
    );
    return result;
  }

  Future<WikipediaEntry?> _fetchRandomArticle() async {
    print('Entering _fetchRandomArticle');
    try {
      final url = Uri.parse(
        // This is akin to: https://en.wikipedia.org/wiki/Wikipedia:Random
        'https://en.wikipedia.org/w/api.php?action=query&format=json&list=random&rnlimit=1&rnnamespace=0',
      );
      final response = await http.get(url);
      if (response.statusCode != 200) {
        print(
          'Exiting _fetchRandomArticle - status code ${response.statusCode}',
        );
        return null;
      }

      final data = json.decode(response.body);
      final random = data['query']['random'][0];
      final title = random['title'] as String;

      final result = await _fetchArticleByTitle(title);
      print('Exiting _fetchRandomArticle - title: $title');
      return result;
    } catch (e) {
      print('Exiting _fetchRandomArticle with error: $e');
      return null;
    }
  }

  Future<WikipediaEntry?> _fetchArticleByTitle(String title) async {
    print('Entering _fetchArticleByTitle with title: $title');
    try {
      // 1. Fetch HTML to extract links ONLY from the article body.
      // extracts prop (without explaintext) returns just the article content.
      final htmlUrl = Uri.parse(
        'https://en.wikipedia.org/w/api.php?action=query&format=json&prop=extracts&titles=${Uri.encodeComponent(title)}',
      );
      final htmlResponse = await http.get(htmlUrl);
      if (htmlResponse.statusCode != 200) {
        print('Exiting _fetchArticleByTitle (HTML fetch failed)');
        return null;
      }

      final htmlData = json.decode(htmlResponse.body);
      final htmlPages = htmlData['query']['pages'] as Map<String, dynamic>;
      if (htmlPages.isEmpty) {
        print('Exiting _fetchArticleByTitle (No HTML pages found)');
        return null;
      }
      final htmlPage = htmlPages.values.first;
      if (htmlPage['missing'] != null) {
        print('Exiting _fetchArticleByTitle (Page missing in HTML fetch)');
        return null;
      }

      final htmlContent = htmlPage['extract'] as String? ?? '';

      // 2. Extract links from HTML
      final document = html_parser.parse(htmlContent);
      final linkElements = document.getElementsByTagName('a');
      for (var element in linkElements) {
        final linkTitle = element.attributes['title'];
        if (linkTitle != null && !linkTitle.contains(':')) {
          _discoveredTitles.add(linkTitle);
        }
      }

      // 3. Fetch Plain Text for display and reading.
      final textUrl = Uri.parse(
        'https://en.wikipedia.org/w/api.php?action=query&format=json&prop=extracts&explaintext=1&titles=${Uri.encodeComponent(title)}',
      );
      final textResponse = await http.get(textUrl);
      if (textResponse.statusCode != 200) {
        print('Exiting _fetchArticleByTitle (Text fetch failed)');
        return null;
      }

      final textData = json.decode(textResponse.body);
      final textPages = textData['query']['pages'] as Map<String, dynamic>;
      final textPage = textPages.values.first;

      final plainContent = textPage['extract'] as String? ?? '';
      final entryTitle = textPage['title'] as String;

      final entry = WikipediaEntry(
        id: entryTitle,
        title: entryTitle,
        content: plainContent,
      );

      _cache[entryTitle] = entry;
      print('Exiting _fetchArticleByTitle - successfully fetched $entryTitle');
      return entry;
    } catch (e) {
      print('Exiting _fetchArticleByTitle with error: $e');
      return null;
    }
  }

  @override
  Future<List<String>> getAvailableEntryIds() async {
    print('Entering WikipediaStuffService.getAvailableEntryIds');
    final result = ['random', ..._discoveredTitles];
    print(
      'Exiting WikipediaStuffService.getAvailableEntryIds - count: ${result.length}',
    );
    return result;
  }

  @override
  List<String> findEntryIdsInText(String text) {
    print('Entering WikipediaStuffService.findEntryIdsInText');
    final result = _discoveredTitles
        .where((title) => text.toLowerCase().contains(title.toLowerCase()))
        .toList();
    print(
      'Exiting WikipediaStuffService.findEntryIdsInText - found: ${result.length}',
    );
    return result;
  }
}
