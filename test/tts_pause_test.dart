import 'package:flutter_test/flutter_test.dart';
import 'package:stuff_crawler/services/tts_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateNiceMocks([MockSpec<FlutterTts>()])
import 'tts_pause_test.mocks.dart';

void main() {
  group('TtsService Pause Logic', () {
    late TtsService ttsService;
    late MockFlutterTts mockTts;

    setUp(() {
      mockTts = MockFlutterTts();
      ttsService = TtsService(flutterTts: mockTts);
    });

    test('splitTextForPauses should handle numbered lists with brief pauses', () {
      const text = 'This is a definition.\n1. First item.\n2. Second item.';
      final parts = ttsService.splitTextForPauses(text);

      expect(parts, equals([
        'This is a definition.',
        '\n',
        const Duration(milliseconds: 100),
        '1.',
        const Duration(milliseconds: 100),
        ' First item.',
        '\n',
        const Duration(milliseconds: 100),
        '2.',
        const Duration(milliseconds: 100),
        ' Second item.',
      ]));
    });

    test('splitTextForPauses should not add pauses for numbers mid-line', () {
      const text = 'The number 1. is not at the start.';
      final parts = ttsService.splitTextForPauses(text);
      expect(parts, equals([text]));
    });
    
    test('splitTextForPauses should handle single line with number correctly', () {
      const text = '1. Start with number.';
      final parts = ttsService.splitTextForPauses(text);
      expect(parts, equals([
        const Duration(milliseconds: 100),
        '1.',
        const Duration(milliseconds: 100),
        ' Start with number.',
      ]));
    });
  });
}
