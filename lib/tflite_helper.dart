import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteHelper {
  late Interpreter _interpreter;
  static const int numClasses = 6; // Define number of emotion classes

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('emotion_model.tflite'); // Fixed path
    print("TFLite model loaded successfully! ✅");
  }

  String predict(String inputText) {
    List<double> inputTensor = textToTensor(inputText);

    var outputTensor = List.filled(numClasses, 0.0).reshape([1, numClasses]); // Fixed shape

    _interpreter.run(inputTensor, outputTensor);

    return getEmotionFromOutput(outputTensor[0]); // Pass the first row
  }

  List<double> textToTensor(String text) {
    // TODO: Implement actual tokenization (convert text to numbers)
    return List.filled(50, 0.0);  // Placeholder, adjust sequence length
  }

  String getEmotionFromOutput(List<double> output) {
    int predictedIndex = output.indexOf(output.reduce((a, b) => a > b ? a : b)); // Get max index
    List<String> emotions = ["Happy", "Sad", "Angry", "Neutral", "Fear", "Surprise"]; // Define labels

    return emotions[predictedIndex]; // Return predicted emotion
  }
}
