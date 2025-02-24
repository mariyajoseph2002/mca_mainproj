import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  Future<String> listen() async {
    bool available = await _speech.initialize();
    if (!available) return "Speech recognition not available";

    String recognizedText = "";
    await _speech.listen(
      onResult: (result) {
        recognizedText = result.recognizedWords;
      },
    );

    return recognizedText;
  }

  void stop() {
    _speech.stop();
  }
}
