import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  Future<String> listen() async {
    if (!await _speech.initialize()) {
      return "Speech recognition not available";
    }

    String recognizedText = "";
    await _speech.listen(onResult: (result) {
      recognizedText = result.recognizedWords;
    });

    await Future.delayed(Duration(seconds: 2)); // Wait for recognition
    await _speech.stop();
    return recognizedText;
  }

  void stop() => _speech.stop();
}
