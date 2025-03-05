import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart'; 
import 'package:flutter/services.dart' show rootBundle;
import 'speech_to_text_service.dart';
import 'dart:typed_data';
import 'dart:convert'; // ✅ Required for JSON decoding
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
  final SpeechToTextService _speechService = SpeechToTextService();
  Interpreter? _interpreter;
  bool _isListening = false;
  String? _predictedEmotion;

  // ✅ Define wordToIndex map at class level (so it's accessible in all methods)
 

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadTokenizer();
    requestPermissions();
  }


  Future<void> requestPermissions() async {
    await Permission.microphone.request();
}

  // ✅ Load the TensorFlow Lite model
  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/emotionn_model.tflite');

      // Print input & output tensor details
      print("✅ Model loaded successfully!");
      print("🔹 INPUT DETAILS:");
      print(_interpreter!.getInputTensors());
      print("🔹 OUTPUT DETAILS:");
      print(_interpreter!.getOutputTensors());
    } catch (e) {
      print("❌ Error loading model: $e");
    }
  }
  List<double> adjustSoftmax(List<double> output, double temp) {
    List<double> expVals = output.map((o) => exp(o / temp)).toList();
    double sumExp = expVals.reduce((a, b) => a + b);
    return expVals.map((o) => o / sumExp).toList();
}


  Future<void> _loadTokenizer() async {
    

    try {
      String jsonString = await rootBundle.loadString('assets/tokenizer.json');
      wordToIndex = Map<String, int>.from(json.decode(jsonString));
      print("✅ First 10 words in tokenizer: ${wordToIndex.entries.take(10).toList()}");
      
      print("✅ Tokenizer Loaded: ${wordToIndex.length} words");
    } catch (e) {
      print("❌ Error loading tokenizer: $e");
    }
  }

  // 🎤 Start listening & convert speech to text

void _startListening() async {
  var status = await Permission.microphone.request();
  if (status.isGranted) {
    setState(() => _isListening = true);
    String result = await _speechService.listen();
    setState(() {
      _textController.text = result;  // 🎤 Display recognized text
      _isListening = false;
    });
  } else {
    print("❌ Microphone permission denied");
  }
}


  // ⏹ Stop listening
  void _stopListening() {
    _speechService.stop();
    setState(() {
      _isListening = false;
    });
  }

  // ✅ Check how the tokenizer processes the input
  void _checkTokenizer(String text) {
    List<String> words = text.toLowerCase().split(' ');
    List<double> tokenized = words.map((word) => wordToIndex[word]?.toDouble() ?? 0.0).toList();
    print("📌 Tokenized Input: $tokenized");
  }

  // 🧠 Analyze Emotion using the TFLite Model
  /* void _analyzeEmotion() async {
    String text = _textController.text.trim();
    if (text.isEmpty || _interpreter == null) return;

    try {
      // ✅ Check tokenizer output before running inference
      _checkTokenizer(text);

      // Process input
      List<double> input = _preprocessText(text);
      var inputBuffer = Float32List.fromList(input).reshape([1, 66]);

      // Create output buffer
      var output = List.filled(6, 0.0).reshape([1, 6]);

      // Run inference
      _interpreter!.run(inputBuffer, output);

      print("📝 Input: $text");
      print("🔮 Raw Output: $output");
      var adjustedOutput = adjustSoftmax(output[0], 0.5); // Adjust temperature



      // Find max index
      int emotionIndex = _getPredictedIndex(adjustedOutput);
      String detectedEmotion = _getEmotionLabel(emotionIndex);

      setState(() {
        _predictedEmotion = "Detected Emotion: $detectedEmotion";
      });

      print("🔮 Predicted Index: $emotionIndex -> Emotion: $detectedEmotion");
    } catch (e) {
      print("❌ Prediction error: $e");
    }
  }
 */
void _analyzeEmotion() async {
  String text = _textController.text.trim();
  if (text.isEmpty || _interpreter == null) return;

  try {
    // Convert input text to tokens
    List<double> input = _preprocessText(text);
    var inputBuffer = Float32List.fromList(input).reshape([1, 66]);

    // Create output buffer
    var output = List.filled(6, 0.0).reshape([1, 6]);

    // Run inference
    _interpreter!.run(inputBuffer, output);

    print("🔮 Flutter Raw Output: $output");  // ✅ Debugging step

    // Get predicted emotion
    int emotionIndex = _getPredictedIndex(output[0]);  // No need for softmax
    String detectedEmotion = _getEmotionLabel(emotionIndex);

    setState(() {
      _predictedEmotion = "Detected Emotion: $detectedEmotion";
    });

    print("🎭 Flutter Predicted Emotion: $detectedEmotion");

  } catch (e) {
    print("❌ Prediction error: $e");
  }
}


  // ✅ Convert text into a numerical format for the model (Tokenization + Padding)
/*   List<double> _preprocessText(String text) {
    List<String> words = text.toLowerCase().split(' ');  // Lowercase for consistency
    List<double> tokenized = words.map((word) => wordToIndex[word]?.toDouble() ?? 0.0).toList();

    print("📌 Tokenized Input: $tokenized");

    while (tokenized.length < 66) {
      tokenized.add(0.0);  // Padding
    }

    return tokenized.sublist(0, 66);
  }
 */
/* List<double> _preprocessText(String text) {
  List<String> words = text.toLowerCase().split(' ');  // Tokenization (basic)

  // ✅ Convert words to indices (equivalent to tokenizer.texts_to_sequences)
  List<double> tokenized = words.map((word) => wordToIndex[word]?.toDouble() ?? 0.0).toList();

  print("📌 Tokenized Input: $tokenized"); // Debugging

  // ✅ Pad sequence to max_length (equivalent to pad_sequences)
  int maxLength = 66;
  while (tokenized.length < maxLength) {
    tokenized.add(0.0);  // Padding with 0s
  }

  // ✅ Trim to max_length if needed
  return tokenized.sublist(0, maxLength);
} */
List<double> _preprocessText(String text) {
  List<String> words = text.toLowerCase().split(' ');

  // Convert words to indices
  List<double> tokenized = words.map((word) => wordToIndex[word]?.toDouble() ?? 0.0).toList();

  print("📌 Tokenized Input (Before Padding): $tokenized");

  // ✅ Apply pre-padding instead of post-padding
  int maxLength = 66;
  while (tokenized.length < maxLength) {
    tokenized.insert(0, 0.0);  // Pre-padding: Adds 0s at the beginning instead of the end
  }

  // Trim to max_length (if needed)
  tokenized = tokenized.sublist(0, maxLength);

  print("📌 Tokenized Input (After Pre-Padding): $tokenized");
  return tokenized;
}


  // ✅ Get predicted emotion index from output tensor
int _getPredictedIndex(List<double> output) {
  double maxVal = output.reduce((a, b) => a > b ? a : b);
  return output.indexOf(maxVal);  // Equivalent to np.argmax()
}


  // ✅ Convert model output index to an emotion label
String _getEmotionLabel(int index) {
  List<String> emotions = ["Anger", "Fear", "Joy", "Love", "Sadness", "Surprise"];
  return (index >= 0 && index < emotions.length) ? emotions[index] : "Unknown";
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
