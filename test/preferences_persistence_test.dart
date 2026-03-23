import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stuff_crawler/views/preferences_view.dart';
import 'package:stuff_crawler/services/tts_service.dart';

class MockTtsService extends TtsService {
  Map? _mockVoice;
  String _mockLocale = 'en-US';
  double _mockRate = 0.5;

  @override
  Map? get currentVoice => _mockVoice;
  
  @override
  set currentVoice(Map? v) => _mockVoice = v;

  @override
  String get currentLocale => _mockLocale;

  @override
  set currentLocale(String l) => _mockLocale = l;

  @override
  double getSpeechRate() => _mockRate;

  @override
  Future<void> setSpeechRate(double rate) async {
    _mockRate = rate;
  }

  @override
  Future<List<dynamic>> getVoices() async {
    return [
      {'name': 'Voice A', 'locale': 'en-US', 'identifier': 'id_a'},
      {'name': 'Voice B', 'locale': 'en-GB', 'identifier': 'id_b'},
    ];
  }

  @override
  Future<void> setVoice(Map voice) async {
    _mockVoice = voice;
    if (voice.containsKey('locale')) {
      _mockLocale = voice['locale'];
    }
  }

  @override
  Future<void> resetVoice() async {
    _mockVoice = null;
    _mockLocale = 'en-US';
  }
  
  @override
  Future<void> stop() async {}
}

void main() {
  testWidgets('PreferencesView persists voice selection via TtsService', (WidgetTester tester) async {
    final mockService = MockTtsService();
    
    // Simulate initial state: no voice selected
    mockService.currentVoice = null;

    // 1. Load the view
    await tester.pumpWidget(MaterialApp(
      home: PreferencesView(ttsService: mockService),
    ));
    // LoadVoices is async, pump enough to let it finish
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Verify it stays null (System Default) unless the user manually changes it
    expect(mockService.currentVoice, isNull);

    // 2. Simulate "Exiting" and "Re-entering"
    await tester.pumpWidget(Container()); // Dispose
    await tester.pumpAndSettle();
    
    // mockService should still have null
    expect(mockService.currentVoice, isNull);

    await tester.pumpWidget(MaterialApp(
      home: PreferencesView(ttsService: mockService),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    
    // It should still be null
    expect(mockService.currentVoice, isNull);

    // 3. Manually set a voice and verify it's persisted
    final testVoice = (await mockService.getVoices()).first;
    mockService.currentVoice = testVoice;
    
    await tester.pumpWidget(MaterialApp(
      home: PreferencesView(ttsService: mockService),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    
    expect(mockService.currentVoice!['name'], 'Voice A');
  });
}
