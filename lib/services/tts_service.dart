import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Service to handle text-to-speech with progress reporting for highlighting.
class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  /// The text currently being spoken.
  final ValueNotifier<String?> currentText = ValueNotifier(null);

  /// Callback when a word is being spoken.
  /// (startOffset, endOffset)
  final ValueNotifier<({int start, int end})?> speakingRange = ValueNotifier(
    null,
  );

  /// Currently selected voice.
  Map? currentVoice;

  /// Currently selected locale.
  String currentLocale = 'en-US';

  /// Callback when speaking is finished.
  VoidCallback? onCompletion;

  bool _isInternalRestart = false;
  double _speechRate = 0.5;

  Completer<void>? _completionCompleter;

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setProgressHandler((
      String text,
      int start,
      int end,
      String word,
    ) {
      speakingRange.value = (start: start, end: end);
    });

    _flutterTts.setCompletionHandler(() {
      speakingRange.value = null;
      if (!_isInternalRestart) {
        currentText.value = null;
        onCompletion?.call();
        _completionCompleter?.complete();
        _completionCompleter = null;
      }
    });

    _flutterTts.setErrorHandler((msg) {
      debugPrint('TTS Error: $msg');
      speakingRange.value = null;
      _completionCompleter?.completeError(msg);
      _completionCompleter = null;
    });

    _flutterTts.setCancelHandler(() {
      speakingRange.value = null;
      _completionCompleter?.complete();
      _completionCompleter = null;
    });
  }

  /// Speaks the given text and waits for completion if requested.
  Future<void> speak(String text, {bool awaitCompletion = false}) async {
    print('Entering TtsService.speak: $text');
    _isInternalRestart = false;
    
    // Stop any current speaking to clear state
    await _flutterTts.stop();
    speakingRange.value = null;
    currentText.value = text;
    
    // Complete previous completer if any
    if (_completionCompleter != null && !_completionCompleter!.isCompleted) {
      _completionCompleter!.complete();
    }
    
    if (awaitCompletion) {
      _completionCompleter = Completer<void>();
    }
    
    await _flutterTts.speak(text);
    
    if (awaitCompletion) {
      await _completionCompleter?.future;
    }
    print('Exiting TtsService.speak');
  }

  /// Stops current speaking.
  Future<void> stop() async {
    print('Entering TtsService.stop');
    // We only clear the text and complete the wait if it's NOT just a setting refresh
    if (!_isInternalRestart) {
      currentText.value = null;
      if (_completionCompleter != null && !_completionCompleter!.isCompleted) {
        _completionCompleter!.complete();
      }
      _completionCompleter = null;
    }
    
    await _flutterTts.stop();
    speakingRange.value = null;
    print('Exiting TtsService.stop');
  }

  /// Helper to restart speech internally without triggering session completion.
  Future<void> _internalRestart() async {
    if (currentText.value == null) return;
    
    print('Entering TtsService._internalRestart');
    _isInternalRestart = true;
    try {
      // Calling stop() here will not complete the _completionCompleter because _isInternalRestart is true
      await stop(); 
      await _flutterTts.speak(currentText.value!);
    } finally {
      // Give the engine some time to process its stop events
      await Future.delayed(const Duration(milliseconds: 200));
      _isInternalRestart = false;
      print('Exiting TtsService._internalRestart');
    }
  }

  /// Returns a list of available voices.
  Future<List<dynamic>> getVoices() async {
    print('Entering TtsService.getVoices');
    final voices = await _flutterTts.getVoices;
    print('Exiting TtsService.getVoices - found ${voices.length} voices');
    return voices;
  }

  /// Sets the voice to be used.
  Future<void> setVoice(Map voice) async {
    // Avoid redundant sets if it's the same voice map (compare identifiers)
    if (currentVoice != null && 
        currentVoice!['identifier'] == voice['identifier'] &&
        currentVoice!['name'] == voice['name']) {
      print('TtsService.setVoice: Voice already set, skipping.');
      return;
    }

    print('Entering TtsService.setVoice with: $voice');
    currentVoice = voice;
    final Map<String, String> voiceMap = voice.cast<String, String>();

    if (voiceMap.containsKey('locale')) {
      currentLocale = voiceMap['locale']!;
      await _flutterTts.setLanguage(currentLocale);
    } else if (voiceMap.containsKey('language')) {
      currentLocale = voiceMap['language']!;
      await _flutterTts.setLanguage(currentLocale);
    }

    print('Setting voice to: $voiceMap');
    await _flutterTts.setVoice(voiceMap);
    // Setting a voice can sometimes reset speech rate on some platforms,
    // so we re-apply settings just in case.
    print('Setting speech rate to: $_speechRate');
    await _flutterTts.setSpeechRate(_speechRate);

    // Restart if currently speaking to apply change live
    if (currentText.value != null) {
      print('Restarting TTS to apply voice change');
      await _internalRestart();
    }
    print('Exiting TtsService.setVoice');
  }

  /// Returns the current speech rate.
  double getSpeechRate() => _speechRate;

  /// Sets the speech rate.
  Future<void> setSpeechRate(double rate) async {
    print('Entering TtsService.setSpeechRate with: $rate');
    _speechRate = rate;
    await _flutterTts.setSpeechRate(_speechRate);

    // Restart if currently speaking to apply change live
    if (currentText.value != null) {
      print('Restarting TTS to apply speech rate change');
      await _internalRestart();
    }
    print('Exiting TtsService.setSpeechRate');
  }

  /// Resets to the default system voice.
  Future<void> resetVoice() async {
    print('Entering TtsService.resetVoice');
    currentVoice = null;
    currentLocale = 'en-US';
    await _flutterTts.setLanguage(currentLocale);
    await _flutterTts.setSpeechRate(_speechRate);

    // Restart if currently speaking to apply change live
    if (currentText.value != null) {
      print('Restarting TTS to apply voice reset');
      await _internalRestart();
    }
    print('Exiting TtsService.resetVoice');
  }
}
