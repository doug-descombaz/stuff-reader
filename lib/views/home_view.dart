import 'package:flutter/material.dart';
import '../logic/stuff_service.dart';
import '../services/dictionary_service.dart';
import '../services/wikipedia_service.dart';
import '../services/tts_service.dart';
import '../logic/session_manager.dart';

/// The primary view for the dictionary crawler application.
/// It displays the current item, its content, and handles session control.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<StuffService> _services = [
    DictionaryService(),
    WikipediaStuffService(),
  ];
  late StuffService _currentService;
  final TtsService _ttsService = TtsService();
  late SessionManager _sessionManager;
  
  bool _isLoading = true;
  bool _isPlaying = false;
  
  StuffEntry? _currentWord;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentService = _services.first;
    _sessionManager = SessionManager(_currentService);
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      await _currentService.init();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _error = 'Error loading service: $e');
    }
  }

  void _onServiceChanged(StuffService? newService) async {
    if (newService == null || newService == _currentService) return;
    
    await _ttsService.stop();
    
    setState(() {
      _isLoading = true;
      _currentService = newService;
      _currentWord = null;
      _isPlaying = false;
      _error = null;
    });

    try {
      await _currentService.init();
      _sessionManager.setService(_currentService);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Error switching service: $e';
        _isLoading = false;
      });
    }
  }

  /// Starts or stops the reading session.
  void _toggleSession() async {
    if (_isPlaying) {
      await _ttsService.stop();
      setState(() => _isPlaying = false);
    } else {
      _startSession();
    }
  }

  /// Handles the sequence of reading the word then its definitions.
  Future<void> _startSession() async {
    setState(() {
      _isPlaying = true;
      _error = null;
    });

    try {
      // Pick initial random word if none is selected
      if (_currentWord == null) {
        _currentWord = await _sessionManager.pickRandomWord();
        if (_currentWord == null) {
          setState(() {
            _error = 'No words available in dictionary.';
            _isPlaying = false;
          });
          return;
        }
      }
      
      _readCurrentWordSequence();
    } catch (e) {
      setState(() {
        _error = 'Error in session: $e';
        _isPlaying = false;
      });
    }
  }

  /// The core recursive sequence to read current word -> definition -> next word.
  Future<void> _readCurrentWordSequence() async {
    if (!_isPlaying || _currentWord == null) return;

    setState(() {}); // Update UI for the current word

    // 1. Read the title
    await _ttsService.speak(_currentWord!.title);
    
    // Set a completion handler to continue to the content
    _ttsService.onCompletion = () async {
      if (!_isPlaying || _currentWord == null) return;
      
      // Clear highlight and start reading content
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 2. Read the content
      await _ttsService.speak(_currentWord!.content);
      
      _ttsService.onCompletion = () async {
        if (!_isPlaying) return;

        // 3. Pick next word and continue
        await Future.delayed(const Duration(seconds: 1));
        final nextWord = await _sessionManager.pickNextWord();
        
        if (nextWord != null) {
          _currentWord = nextWord;
          _readCurrentWordSequence();
        } else {
          setState(() {
            _isPlaying = false;
            _error = 'Reached the end of the session.';
          });
        }
      };
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stuff Crawler'),
        elevation: 8,
        actions: [
          _buildServiceSelector(),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleSession,
        icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
        label: Text(_isPlaying ? 'Stop Session' : 'Random Session'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildServiceSelector() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<StuffService>(
        value: _currentService,
        items: _services.map((service) {
          return DropdownMenuItem<StuffService>(
            value: service,
            child: Text(
              service.canonicalTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
        onChanged: _onServiceChanged,
        dropdownColor: Theme.of(context).primaryColor,
        style: const TextStyle(color: Colors.white),
        iconEnabledColor: Colors.white,
      ),
    );
  }

  Widget _buildContent() {
    if (_currentWord == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              'Welcome to Stuff Crawler!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            const Text('Click "Random Session" to start reading words from the dictionary.'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HighlightableText(
            text: _currentWord!.title,
            style: Theme.of(context).textTheme.displayMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
            ttsService: _ttsService,
            isActive: true, // Word is always "active" for its own segment
          ),
          const Divider(height: 48, thickness: 2),
          Text(
            'CONTENT',
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  letterSpacing: 2,
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 16),
          _HighlightableText(
            text: _currentWord!.content,
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  height: 1.5,
                  fontWeight: FontWeight.normal,
                ),
            ttsService: _ttsService,
            isActive: true, 
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var service in _services) {
      service.dispose();
    }
    _ttsService.stop();
    super.dispose();
  }
}

/// A widget that handles word-level highlighting based on TTS progress.
class _HighlightableText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TtsService ttsService;
  final bool isActive;

  const _HighlightableText({
    required this.text,
    required this.style,
    required this.ttsService,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ttsService.currentText,
      builder: (context, speakingText, _) {
        final isThisTextBeingSpoken = speakingText == text;

        return ValueListenableBuilder(
          valueListenable: ttsService.speakingRange,
          builder: (context, range, _) {
            if (!isThisTextBeingSpoken || range == null) {
              return Text(text, style: style);
            }

            final start = range.start;
            final end = range.end;

            // Check if range is valid for this text
            if (start < 0 || end > text.length || start >= end) {
              return Text(text, style: style);
            }

            return RichText(
              text: TextSpan(
                style: style,
                children: [
                  TextSpan(text: text.substring(0, start)),
                  TextSpan(
                    text: text.substring(start, end),
                    style: const TextStyle(
                      backgroundColor: Colors.yellow,
                      color: Colors.black,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: text.substring(end)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
