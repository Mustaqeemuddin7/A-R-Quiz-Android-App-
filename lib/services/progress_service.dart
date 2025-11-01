import 'package:flutter/material.dart';
import 'firestore_service.dart';

class ProgressService extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  // Badge thresholds
  static const int beginnerThreshold = 3;
  static const int intermediateThresholdPercent = 50;
  static const int proThresholdPercent = 100;
  
  // Calculate and award badges
  Future<void> checkAndAwardBadges(String email) async {
    final userData = _firestoreService.userData;
    if (userData == null) return;
    
    final currentBadges = List<String>.from(userData['badges'] ?? []);
    final progress = userData['progress'] as Map<String, dynamic>? ?? {};
    
    // Count completed topics (at least one level completed)
    int completedTopics = 0;
    progress.forEach((topic, levels) {
      if (levels is Map) {
        bool hasCompletedLevel = levels.values.any((completed) => completed == true);
        if (hasCompletedLevel) completedTopics++;
      }
    });
    
    // Get total progress percentage
    double progressPercent = _firestoreService.getProgressPercentage();
    
    List<String> newBadges = [...currentBadges];
    
    // Award Beginner badge
    if (completedTopics >= beginnerThreshold && !newBadges.contains('Beginner')) {
      newBadges.add('Beginner');
    }
    
    // Award Intermediate badge
    if (progressPercent >= intermediateThresholdPercent && !newBadges.contains('Intermediate')) {
      newBadges.add('Intermediate');
    }
    
    // Award Pro badge
    if (progressPercent >= proThresholdPercent && !newBadges.contains('Pro')) {
      newBadges.add('Pro');
    }
    
    // Update badges if changed
    if (newBadges.length != currentBadges.length) {
      await _firestoreService.updateBadges(email, newBadges);
    }
  }
  
  // Calculate score for a quiz
  int calculateScore(int correctAnswers, int totalQuestions, String level) {
    double baseScore = (correctAnswers / totalQuestions) * 100;
    
    // Multiplier based on difficulty
    double multiplier = 1.0;
    switch (level.toLowerCase()) {
      case 'easy':
        multiplier = 1.0;
        break;
      case 'medium':
        multiplier = 1.5;
        break;
      case 'hard':
        multiplier = 2.0;
        break;
    }
    
    return (baseScore * multiplier).round();
  }
  
  // Get badge icon based on badge name
  String getBadgeIcon(String badge) {
    switch (badge.toLowerCase()) {
      case 'beginner':
        return '🥉';
      case 'intermediate':
        return '🥈';
      case 'pro':
        return '🥇';
      default:
        return '🏅';
    }
  }
  
  // Get badge color
  Color getBadgeColor(String badge) {
    switch (badge.toLowerCase()) {
      case 'beginner':
        return const Color(0xFFCD7F32); // Bronze
      case 'intermediate':
        return const Color(0xFFC0C0C0); // Silver
      case 'pro':
        return const Color(0xFFFFD700); // Gold
      default:
        return Colors.grey;
    }
  }
  
  // Get highest badge
  String? getHighestBadge(List<String> badges) {
    if (badges.contains('Pro')) return 'Pro';
    if (badges.contains('Intermediate')) return 'Intermediate';
    if (badges.contains('Beginner')) return 'Beginner';
    return null;
  }
}