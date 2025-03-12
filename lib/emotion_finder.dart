/* import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart'; 
import 'package:flutter/services.dart' show rootBundle;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import 'customer.dart';

class EmotionFinderScreen extends StatefulWidget {
  @override
  _EmotionFinderScreenState createState() => _EmotionFinderScreenState();
}

class _EmotionFinderScreenState extends State<EmotionFinderScreen> {
  Map<String, int> wordToIndex = {};
  final TextEditingController _textController = TextEditingController();
  
  stt.SpeechToText _speech = stt.SpeechToText();
  Interpreter? _interpreter;
  bool _isListening = false;
  String? _predictedEmotion;
  String? _suggestion;

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadTokenizer();
    requestMicrophonePermission(); 
    initSpeech();
  }

  Future<void> requestMicrophonePermission() async {
    var status = await Permission.microphone.request();
    if (status.isDenied) {
      print("Microphone permission denied");
    }
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/emotion_model.tflite');
      print("✅ Model loaded successfully!");
    } catch (e) {
      print("❌ Error loading model: $e");
    }
  }

  Future<void> _loadTokenizer() async {
    try {
      String jsonString = await rootBundle.loadString('assets/tokenizer.json');
      wordToIndex = Map<String, int>.from(json.decode(jsonString));
    } catch (e) {
      print("❌ Error loading tokenizer: $e");
    }
  }

  void initSpeech() async {
    bool available = await _speech.initialize();
    if (!available) {
      print("Speech recognition not available");
    }
  }

  void _startListening() async {
    if (!_speech.isAvailable) return;

    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (val) {
        setState(() {
          _textController.text = val.recognizedWords;
          _isListening = false;
        });
      },
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _analyzeEmotion() async {
    String text = _textController.text.trim();
    if (text.isEmpty || _interpreter == null) return;

    try {
      List<double> input = _preprocessText(text);
      var inputBuffer = Float32List.fromList(input).reshape([1, 66]);
      var output = List.filled(10, 0.0).reshape([1, 10]);

      _interpreter!.run(inputBuffer, output);
      int emotionIndex = _getPredictedIndex(output[0]);
      String detectedEmotion = _getEmotionLabel(emotionIndex);

      setState(() {
        _predictedEmotion = "Detected Emotion: $detectedEmotion";
        _suggestion = _getSuggestion(detectedEmotion);
      });
    } catch (e) {
      print("❌ Prediction error: $e");
    }
  }

  List<double> _preprocessText(String text) {
    List<String> words = text.toLowerCase().split(' ');
    List<double> tokenized = words.map((word) => wordToIndex[word]?.toDouble() ?? 0.0).toList();
    while (tokenized.length < 66) {
      tokenized.insert(0, 0.0);
    }
    return tokenized.sublist(0, 66);
  }

  int _getPredictedIndex(List<double> output) {
    double maxVal = output.reduce((a, b) => a > b ? a : b);
    return output.indexOf(maxVal);
  }

  String _getEmotionLabel(int index) {
    List<String> emotions = ["Anger", "Fear", "Guilt", "Hope", "Joy", "Loneliness", "Love", "Neutral", "Sadness", "Surprise"];
    return (index >= 0 && index < emotions.length) ? emotions[index] : "Unknown";
  }

  String _getSuggestion(String emotion) {
    Map<String, String> suggestions = {
      "Anger": "Take deep breaths and try mindfulness exercises.",
      "Fear": "Challenge your fears with positive affirmations.",
      "Guilt": "Forgive yourself and learn from past mistakes.",
      "Hope": "Keep believing in yourself and set small goals.",
      "Joy": "Spread positivity by sharing happiness with others.",
      "Loneliness": "Reach out to a friend or engage in a hobby.",
      "Love": "Express gratitude and cherish relationships.",
      "Neutral": "Take a moment to reflect on your emotions.",
      "Sadness": "Listen to uplifting music or talk to someone.",
      "Surprise": "Embrace unexpected moments and enjoy them!",
    };
    return suggestions[emotion] ?? "Stay positive and take care of yourself.";
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
        backgroundColor: Color.fromARGB(255, 238, 160, 233),
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
            if (_predictedEmotion != null) ...[
              Text(_predictedEmotion!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(_suggestion ?? "", style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            ],
          ],
        ),
      ),
    );
  }
}
 */
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart'; 
import 'package:flutter/services.dart' show rootBundle;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer.dart';

class EmotionFinderScreen extends StatefulWidget {
  @override
  _EmotionFinderScreenState createState() => _EmotionFinderScreenState();
}

class _EmotionFinderScreenState extends State<EmotionFinderScreen> {
  Map<String, int> wordToIndex = {};
  final TextEditingController _textController = TextEditingController();
  
  stt.SpeechToText _speech = stt.SpeechToText();
  Interpreter? _interpreter;
  bool _isListening = false;
  String? _predictedEmotion;
  Map<String, dynamic>? _recommendation; // Holds Firestore recommendation data

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadTokenizer();
    requestMicrophonePermission(); 
    initSpeech();
  }

  Future<void> requestMicrophonePermission() async {
    var status = await Permission.microphone.request();
    if (status.isDenied) {
      print("Microphone permission denied");
    }
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/emotion_model.tflite');
      print("✅ Model loaded successfully!");
    } catch (e) {
      print("❌ Error loading model: $e");
    }
  }

  Future<void> _loadTokenizer() async {
    try {
      String jsonString = await rootBundle.loadString('assets/tokenizer.json');
      wordToIndex = Map<String, int>.from(json.decode(jsonString));
    } catch (e) {
      print("❌ Error loading tokenizer: $e");
    }
  }

  void initSpeech() async {
    bool available = await _speech.initialize();
    if (!available) {
      print("Speech recognition not available");
    }
  }

  void _startListening() async {
    if (!_speech.isAvailable) return;

    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (val) {
        setState(() {
          _textController.text = val.recognizedWords;
          _isListening = false;
        });
      },
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _analyzeEmotion() async {
    String text = _textController.text.trim();
    if (text.isEmpty || _interpreter == null) return;

    try {
      List<double> input = _preprocessText(text);
      var inputBuffer = Float32List.fromList(input).reshape([1, 66]);
      var output = List.filled(10, 0.0).reshape([1, 10]);

      _interpreter!.run(inputBuffer, output);
      int emotionIndex = _getPredictedIndex(output[0]);
      String detectedEmotion = _getEmotionLabel(emotionIndex);

      // Fetch recommendation from Firestore
      _fetchRecommendation(detectedEmotion);

      setState(() {
        _predictedEmotion = detectedEmotion;
      });
    } catch (e) {
      print("❌ Prediction error: $e");
    }
  }

  List<double> _preprocessText(String text) {
    List<String> words = text.toLowerCase().split(' ');
    List<double> tokenized = words.map((word) => wordToIndex[word]?.toDouble() ?? 0.0).toList();
    while (tokenized.length < 66) {
      tokenized.insert(0, 0.0);
    }
    return tokenized.sublist(0, 66);
  }

  int _getPredictedIndex(List<double> output) {
    double maxVal = output.reduce((a, b) => a > b ? a : b);
    return output.indexOf(maxVal);
  }

  String _getEmotionLabel(int index) {
    List<String> emotions = ["Anger", "Fear", "Guilt", "Hope", "Joy", "Loneliness", "Love", "Neutral", "Sadness", "Surprise"];
    return (index >= 0 && index < emotions.length) ? emotions[index] : "Unknown";
  }

  Future<void> _fetchRecommendation(String emotion) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('recommendations')
          .doc(emotion)
          .get();

      if (doc.exists) {
        setState(() {
          _recommendation = doc.data() as Map<String, dynamic>?;
        });
      } else {
        setState(() {
          _recommendation = null;
        });
      }
    } catch (e) {
      print("❌ Firestore fetch error: $e");
    }
  }

  Future<void> _acceptGoal(String goal) async {
    String userId = "user123"; // Replace with actual user ID from auth
    await FirebaseFirestore.instance.collection('user_goals').doc(userId).set({
      'goals': FieldValue.arrayUnion([goal])
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Goal added successfully!")),
    );
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
        backgroundColor: Color.fromARGB(255, 238, 160, 233),
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
            if (_predictedEmotion != null) ...[
              Text("💡 Detected Emotion: $_predictedEmotion", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
            ],
            if (_recommendation != null) ...[
              Text("✨ Affirmation: ${_recommendation!['affirmation'] ?? ''}", style: TextStyle(fontSize: 16)),
              Text("🧘 Self-Care Tip: ${_recommendation!['self_care_tip'] ?? ''}", style: TextStyle(fontSize: 16)),
              Text("📝 Journaling Prompt: ${_recommendation!['journaling_prompt'] ?? ''}", style: TextStyle(fontSize: 16)),
              Text("🎯 Suggested Goal: ${_recommendation!['suggested_goal'] ?? ''}", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _acceptGoal(_recommendation!['suggested_goal']),
                child: Text("Accept Goal"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
