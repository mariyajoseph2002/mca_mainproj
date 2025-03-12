import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  // Load API key from .env file
  final String apiKey = dotenv.env['GEMINI_API_KEY']!;

  Future<String> recommendGoals(List<String> previousGoals) async {
    final Uri url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateText?key=$apiKey");

    // Create a structured prompt for better AI responses
    String prompt = """
    You are an AI life coach. Based on the user's previous goals, suggest 3 personalized self-improvement goals to help them grow. 
    Previous goals: ${previousGoals.join(", ")}
    Provide only the list of goals in simple sentences.
    """;

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "prompt": {"text": prompt},
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['candidates'][0]['content']; // Extract recommended goals
    } else {
      throw Exception("Failed to fetch AI recommendations: ${response.body}");
    }
  }
}
