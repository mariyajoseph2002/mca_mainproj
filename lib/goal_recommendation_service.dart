import 'package:cloud_firestore/cloud_firestore.dart';

class GoalRecommendationService {
  static Future<String> getAdaptiveRecommendation(String goalId) async {
    try {
      final today = DateTime.now();
      final oneWeekAgo = today.subtract(Duration(days: 7));

      // Fetch progress history for the last 7 days
      final progressDocs = await FirebaseFirestore.instance
          .collection('goals')
          .doc(goalId)
          .collection('progress_history')
          .where('date', isGreaterThanOrEqualTo: oneWeekAgo)
          .get();

      if (progressDocs.docs.isEmpty) {
        return "No recent progress data available.";
      }

      // Calculate total progress increase over the week
      double initialProgress = progressDocs.docs.first.data()['progress'] ?? 0;
      double finalProgress = progressDocs.docs.last.data()['progress'] ?? 0;
      double weeklyProgress = finalProgress - initialProgress;

      // Determine recommendation based on progress
      if (weeklyProgress >= 80) {
        return "Great job! Try setting a more challenging goal.";
      } else if (weeklyProgress >= 40) {
        return "You're doing well! Keep up the consistency.";
      } else {
        return "Struggling a bit? Consider breaking your goal into smaller steps.";
      }
    } catch (e) {
      return "Error fetching recommendations: $e";
    }
  }
}
