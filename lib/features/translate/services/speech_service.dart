import 'package:flutter_tts/flutter_tts.dart';

class SpeechService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    var languageConfigured = false;
    for (final language in const ['es-GT', 'es-US', 'es-ES']) {
      try {
        final available = await _tts.isLanguageAvailable(language);
        if (available == true) {
          await _tts.setLanguage(language);
          languageConfigured = true;
          break;
        }
      } catch (_) {
        continue;
      }
    }
    if (!languageConfigured) await _tts.setLanguage('es-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);
    _initialized = true;
  }

  Future<void> speak(String text) async {
    final value = text.trim();
    if (value.isEmpty) return;
    await initialize();
    await _tts.stop();
    await _tts.speak(value);
  }

  Future<void> stop() => _tts.stop();
}
