import 'package:flutter/material.dart';
import 'speech_to_text_service.dart';
import '../tflite_helper.dart'; // Updated to use TFLite

class EmotionFinderScreen extends StatefulWidget {
  @override
  _EmotionFinderScreenState createState() => _EmotionFinderScreenState();
}

class _EmotionFinderScreenState extends State<EmotionFinderScreen> {
  final TextEditingController _textController = TextEditingController();
  final SpeechToTextService _speechService = SpeechToTextService(); // Speech-to-text service
  final TFLiteHelper _tfLiteHelper = TFLiteHelper(); // TFLite model helper

  bool _isListening = false;
  String? _predictedEmotion;

  @override
  void initState() {
    super.initState();
    _tfLiteHelper.loadModel(); // Load ML model when screen opens
  }

  // 🎤 Start listening & convert speech to text
  void _startListening() async {
    String result = await _speechService.listen();
    setState(() {
      _textController.text = result;
      _isListening = true;
    });
  }

  // ⏹ Stop listening
  void _stopListening() {
    _speechService.stop();
    setState(() {
      _isListening = false;
    });
  }

  // 🧠 Analyze Emotion using the LSTM Model
  void _analyzeEmotion() async {
    String text = _textController.text;
    if (text.isNotEmpty) {
      String detectedEmotion = await _tfLiteHelper.predict(text);
      setState(() {
        _predictedEmotion = "Detected Emotion: $detectedEmotion";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emotion Finder"),
        backgroundColor: const Color.fromARGB(255, 243, 173, 103),
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic_off : Icons.mic, size: 28),
            onPressed: _isListening ? _stopListening : _startListening,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Type or speak your emotions...",
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _analyzeEmotion,
              child: const Text("Find Emotion"),
            ),
            const SizedBox(height: 20),
            if (_predictedEmotion != null)
              Text(
                _predictedEmotion!,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
