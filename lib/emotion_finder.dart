import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart'; 
import 'package:flutter/services.dart' show rootBundle;
import 'speech_to_text_service.dart';
import 'dart:typed_data';

class EmotionFinderScreen extends StatefulWidget {
  @override
  _EmotionFinderScreenState createState() => _EmotionFinderScreenState();
}

class _EmotionFinderScreenState extends State<EmotionFinderScreen> {
  final TextEditingController _textController = TextEditingController();
  final SpeechToTextService _speechService = SpeechToTextService();

  Interpreter? _interpreter;
  bool _isListening = false;
  String? _predictedEmotion;

  @override
  void initState() {
    super.initState();
    _checkModelExists();
    _loadModel();
  }

  // ✅ Check if the model file exists (Debugging)
  Future<void> _checkModelExists() async {
    try {
      await rootBundle.load('assets/emotion_model.tflite');
      print("✅ Model exists and is accessible!");
    } catch (e) {
      print("❌ Model not found: $e");
    }
  }

  // ✅ Load the TensorFlow Lite model
  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/emotion_model.tflite');
      print("✅ Model loaded successfully!");
    } catch (e) {
      print("❌ Error loading model: $e");
    }
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

  // 🧠 Analyze Emotion using the TFLite Model
  void _analyzeEmotion() async {
    String text = _textController.text.trim();
    if (text.isEmpty || _interpreter == null) return;

    try {
      // ✅ Convert text into numerical format (Tokenized Input)
      List<List<double>> input = [_preprocessText(text)];

      // ✅ Prepare output buffer based on model's expected output shape
      var output = List.filled(1, 0.0).reshape([1, 1]);

      // ✅ Run inference
      _interpreter!.run(input, output);

      // ✅ Interpret the output
      double emotionIndex = output[0][0];
      String detectedEmotion = _getEmotionLabel(emotionIndex);

      setState(() {
        _predictedEmotion = "Detected Emotion: $detectedEmotion";
      });

      print("📝 Input: $text");
      print("🔮 Predicted Index: $emotionIndex -> Emotion: $detectedEmotion");
    } catch (e) {
      print("❌ Prediction error: $e");
    }
  }

  // ✅ Convert text into a numerical format for the model (Basic Tokenization)
  List<double> _preprocessText(String text) {
    List<double> tokenized = text
        .split(' ')
        .map((word) => (word.hashCode % 10000) / 10000.0) // Normalize hash values
        .toList();

    while (tokenized.length < 10) {
      tokenized.add(0.0); // Pad with zeros if needed
    }

    return tokenized.sublist(0, 10); // Ensure input matches expected model size
  }

  // ✅ Convert model output index to an emotion label
  String _getEmotionLabel(double index) {
    List<String> emotions = ["Happy", "Sad", "Angry", "Neutral"];
    int idx = index.round();
    return (idx >= 0 && idx < emotions.length) ? emotions[idx] : "Unknown";
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
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
