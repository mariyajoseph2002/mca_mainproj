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
//import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';


class EmotionFinderScreen extends StatefulWidget {
  @override
  final Widget drawer;
  const EmotionFinderScreen({super.key, required this.drawer});
  _EmotionFinderScreenState createState() => _EmotionFinderScreenState();
}

class _EmotionFinderScreenState extends State<EmotionFinderScreen> {
  Map<String, int> wordToIndex = {};
  final TextEditingController _textController = TextEditingController();
  
  //stt.SpeechToText _speech = stt.SpeechToText();
  Interpreter? _interpreter;
  bool _isListening = false;
  String? _predictedEmotion;
  Map<String, dynamic>? _recommendation; // Holds Firestore recommendation data
  bool _challengeCompleted = false; // Track if the daily challenge was completed
  int _streakDays = 0;
  List<String> _badges = [];
  String? _selfCareTip;


  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadTokenizer();
   // requestMicrophonePermission(); 
   // initSpeech();
  }

 /*  Future<void> requestMicrophonePermission() async {
    var status = await Permission.microphone.request();
    if (status.isDenied) {
      print("Microphone permission denied");
    }
  } */

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/emotio_model.tflite');
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

  /*  void initSpeech() async {
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
  } */

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
      await _fetchSelfCareTip(text);

      setState(() {
        _predictedEmotion = detectedEmotion;
        _challengeCompleted = false; // Reset challenge completion status
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
  Future<void> _fetchSelfCareTip(String userText) async {
  String tip = await _generateSelfCareTip(userText);
  setState(() {
    _selfCareTip = tip;
  });
}


Future<String> _generateSelfCareTip(String userText) async {
  //const String apiKey = "YOUR_GEMINI_API_KEY"; // Replace with your actual Gemini API key
  //const String geminiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateText";
  String apiKey = dotenv.env['GEMINI_API_KEY'] ?? ''; // Your API key from .env
  String apiUrl = "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro-002:generateContent?key=$apiKey";
  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "prompt": {
        "text": "Based on the following emotional text: \"$userText\", suggest a personalized self-care tip to help the user feel better."
      },
      "temperature": 0.7,
      "maxTokens": 50
    }),
  );

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    return data["candidates"]?[0]?["output"] ?? "Take some deep breaths and do something that makes you happy.";
  } else {
    print("❌ Error fetching self-care tip: ${response.body}");
    return "Take some deep breaths and do something that makes you happy.";
  }
}

 Future<void> _acceptGoal(String goal, BuildContext context) async {
  User? user = FirebaseAuth.instance.currentUser; // Get current user

  if (user != null) {
    String userEmail = user.email!; // Get user's email

    await FirebaseFirestore.instance.collection('goals').doc(userEmail).set({
      'goals': FieldValue.arrayUnion([goal])
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Goal added successfully!")),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: User not logged in.")),
    );
  }
}


Future<void> _checkInFeedback(bool isHelpful) async {
  User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userEmail = user.email!;

      await FirebaseFirestore.instance.collection('user_feedback').doc(userEmail).set({
        'feedback': FieldValue.arrayUnion([
          {'emotion': _predictedEmotion, 'helpful': isHelpful, 'timestamp': Timestamp.now()}
        ])
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isHelpful ? "Glad it helped! 😊" : "We'll improve the recommendations!")),
      );

      // Update streaks and badges
      _updateGamification();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: User not logged in.")),
      );
    }
  }

  void _updateGamification() {
    setState(() {
      _streakDays++;
      if (_streakDays == 3) _badges.add("3-Day Streak 🔥");
      if (_streakDays == 7) _badges.add("1-Week Consistency 🏅");
    });
  }


  void _markChallengeCompleted() {
    setState(() {
      _challengeCompleted = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Challenge completed! You earned a badge 🎖️")),
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
        backgroundColor:Color.fromARGB(255, 61, 93, 74),
        foregroundColor: const Color.fromARGB(255, 241, 250, 245),
        actions: [
         /* IconButton(
            icon: Icon(_isListening ? Icons.mic_off : Icons.mic, size: 28),
            onPressed: _isListening ? _stopListening : _startListening,
          ),  */
        ],
      ),
      body: SingleChildScrollView(child: 
       Padding(
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
              style: ElevatedButton.styleFrom(
                  backgroundColor:Color.fromARGB(255, 61, 93, 74),
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              onPressed: _analyzeEmotion,
              child: const Text("Find Emotion",style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            if (_predictedEmotion != null) ...[
              Text("💡 Detected Emotion: $_predictedEmotion", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
            ],
            if (_recommendation != null) ...[
              Text("✨ Affirmation: ${_recommendation!['affirmation'] ?? ''}", style: TextStyle(fontSize: 16)),
              Text("🧘 Self-Care Tip: ${_selfCareTip ?? 'Fetching tip...'}", style: TextStyle(fontSize: 16)),
              //Text("📝 Journaling Prompt: ${_recommendation!['journaling_prompt'] ?? ''}", style: TextStyle(fontSize: 16)),
              Text("🎯 Suggested Goal: ${_recommendation!['suggested_goal'] ?? ''}", style: TextStyle(fontSize: 16)),
              Text("🔥 Daily Challenge: ${_recommendation!['daily_challenge'] ?? ''}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _acceptGoal(_recommendation!['suggested_goal'],context),
                child: Text("Accept Goal"),
              ),
              const SizedBox(height: 10),
              if (!_challengeCompleted)
                ElevatedButton(
                  onPressed: _markChallengeCompleted,
                  child: Text("Complete Challenge 🎖️"),
                ),
                ElevatedButton(
  onPressed: () => _checkInFeedback(true),
  child: Text("✔ This Helped"),
),

ElevatedButton(
  onPressed: () => _checkInFeedback(false),
  child: Text("❌ Not Helpful"),
),

SizedBox(height: 20),

//Text("🏆 Your Streak: $_streakDays days", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//Text("🥇 Badges Earned: $_badges", style: TextStyle(fontSize: 16)),

            ]
            else
                SizedBox.shrink(),
          ],
        ),
      ),
      ),
    );
  }
}
