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

  /// Callback when speaking is finished.
  VoidCallback? onCompletion;

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
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
      currentText.value = null;
      onCompletion?.call();
    });

    _flutterTts.setErrorHandler((msg) {
      debugPrint('TTS Error: $msg');
      speakingRange.value = null;
    });

    _flutterTts.setCancelHandler(() {
      speakingRange.value = null;
    });
  }

  /// Speaks the given text and reports progress.
  Future<void> speak(String text) async {
    speakingRange.value = null;
    currentText.value = text;
    await _flutterTts.speak(text);
  }

  /// Stops current speaking.
  Future<void> stop() async {
    currentText.value = null;
    await _flutterTts.stop();
    speakingRange.value = null;
  }
}
