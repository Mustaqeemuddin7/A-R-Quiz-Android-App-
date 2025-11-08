import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? get userData => _userData;
  
  // Create or update user document
  Future<void> createOrUpdateUser(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.email);
      final docSnapshot = await userDoc.get();
      
      if (!docSnapshot.exists) {
        // Create new user
        await userDoc.set({
          'name': user.displayName ?? 'User',
          'email': user.email,
          'last_login': FieldValue.serverTimestamp(),
          'total_score': 0,
          'progress': {},
          'badges': [],
          'created_at': FieldValue.serverTimestamp(),
        });
      } else {
        // Update last login
        await userDoc.update({
          'last_login': FieldValue.serverTimestamp(),
        });
      }
      
      await loadUserData(user.email!);
    } catch (e) {
      print('Error creating/updating user: $e');
      rethrow;
    }
  }
  
  // Load user data
  Future<void> loadUserData(String email) async {
    try {
      final doc = await _firestore.collection('users').doc(email).get();
      if (doc.exists) {
        _userData = doc.data();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user data: $e');
      rethrow;
    }
  }
  
  // Update user progress with detailed tracking
  Future<void> updateProgress(String email, String topic, String level, bool completed, {
    int? score,
    int? timeSpent,
    int? questionsAttempted,
    int? correctAnswers,
  }) async {
    try {
      final now = FieldValue.serverTimestamp();
      
      // First, get current progress data
      final docSnapshot = await _firestore.collection('users').doc(email).get();
      final currentProgress = docSnapshot.data()?['progress'] as Map<String, dynamic>? ?? {};
      
      // Get current level data if it exists
      final currentLevelData = ((currentProgress[topic] as Map<String, dynamic>?)?[level] 
          as Map<String, dynamic>?) ?? {};
      
      // Prepare the new level data
      final newLevelData = {
        'completed': completed,
        'last_attempt': now,
        'completed_at': completed ? now : currentLevelData['completed_at'],
        'best_score': score != null ? 
            (score > (currentLevelData['best_score'] ?? 0) ? score : currentLevelData['best_score']) :
            currentLevelData['best_score'],
        'total_time_spent': timeSpent != null ?
            FieldValue.increment(timeSpent) :
            currentLevelData['total_time_spent'] ?? 0,
        'questions_attempted': questionsAttempted != null ?
            FieldValue.increment(questionsAttempted) :
            currentLevelData['questions_attempted'] ?? 0,
        'correct_answers': correctAnswers != null ?
            FieldValue.increment(correctAnswers) :
            currentLevelData['correct_answers'] ?? 0,
      };
      
      final updates = {
        'progress.$topic.$level': newLevelData,
        'last_activity': now,
      };

      // Update current streak if completed
      if (completed) {
        final currentStreak = getCurrentStreak();
        updates['current_streak'] = currentStreak + 1;
        if ((currentStreak + 1) > (_userData?['best_streak'] ?? 0)) {
          updates['best_streak'] = currentStreak + 1;
        }
      }

      await _firestore.collection('users').doc(email).update(updates);
      await loadUserData(email);
    } catch (e) {
      print('Error updating progress: $e');
      rethrow;
    }
  }
  
  // Get level statistics
  Map<String, dynamic>? getLevelStats(String topic, String level) {
    if (_userData == null || _userData!['progress'] == null) return null;
    
    final progress = _userData!['progress'] as Map<String, dynamic>;
    final topicProgress = progress[topic] as Map<String, dynamic>?;
    final levelData = topicProgress?[level];
    
    if (levelData == null) return null;
    
    // Handle old format (boolean)
    if (levelData is bool) {
      return {
        'completed': levelData,
        'questions_attempted': 0,
        'correct_answers': 0,
        'total_time_spent': 0,
        'best_score': 0,
      };
    }
    
    // Handle new format (Map)
    if (levelData is Map) {
      return levelData as Map<String, dynamic>;
    }
    
    return null;
  }
  
  // Update total score
  Future<void> updateScore(String email, int scoreToAdd) async {
    try {
      await _firestore.collection('users').doc(email).update({
        'total_score': FieldValue.increment(scoreToAdd),
      });
      await loadUserData(email);
    } catch (e) {
      print('Error updating score: $e');
      rethrow;
    }
  }
  
  // Update badges
  Future<void> updateBadges(String email, List<String> badges) async {
    try {
      await _firestore.collection('users').doc(email).update({
        'badges': badges,
      });
      await loadUserData(email);
    } catch (e) {
      print('Error updating badges: $e');
      rethrow;
    }
  }
  
  // Get user progress percentage with weighted levels
  double getProgressPercentage() {
    if (_userData == null || _userData!['progress'] == null) return 0.0;
    
    final progress = _userData!['progress'] as Map<String, dynamic>;
    double weightedScore = 0.0;
    double totalPossibleScore = 0.0;
    
    // Define weights for different difficulty levels
    const Map<String, double> levelWeights = {
      'easy': 1.0,
      'medium': 1.5,
      'hard': 2.0,
    };
    
    progress.forEach((topic, levels) {
      if (levels is Map) {
        levels.forEach((level, value) {
          double weight = levelWeights[level.toLowerCase()] ?? 1.0;
          totalPossibleScore += weight;
          
          bool isCompleted = false;
          if (value is bool) {
            isCompleted = value;
          } else if (value is Map) {
            isCompleted = value['completed'] == true;
          }
          
          if (isCompleted) {
            weightedScore += weight;
          }
        });
      }
    });
    
    if (totalPossibleScore == 0) return 0.0;
    return (weightedScore / totalPossibleScore) * 100;
  }
  
  // Get topic-wise progress percentage
  Map<String, double> getTopicProgress() {
    if (_userData == null || _userData!['progress'] == null) return {};
    
    final progress = _userData!['progress'] as Map<String, dynamic>;
    final Map<String, double> topicProgress = {};
    
    progress.forEach((topic, levels) {
      if (levels is Map) {
        int completed = 0;
        int total = 0;
        
        levels.forEach((level, value) {
          total++;
          if (value is bool && value) {
            completed++;
          } else if (value is Map && value['completed'] == true) {
            completed++;
          }
        });
        
        topicProgress[topic] = total > 0 ? (completed / total) * 100 : 0.0;
      }
    });
    
    return topicProgress;
  }
  
  // Check if topic level is completed
  bool isLevelCompleted(String topic, String level) {
    if (_userData == null || _userData!['progress'] == null) return false;
    
    final progress = _userData!['progress'] as Map<String, dynamic>;
    if (!progress.containsKey(topic)) return false;
    
    final topicProgress = progress[topic] as Map<String, dynamic>?;
    if (topicProgress == null) return false;
    
    final levelData = topicProgress[level];
    if (levelData is bool) return levelData;
    if (levelData is Map) return levelData['completed'] == true;
    return false;
  }
  
  // Get completion timestamp for a level
  DateTime? getLevelCompletionTime(String topic, String level) {
    if (_userData == null || _userData!['progress'] == null) return null;
    
    final progress = _userData!['progress'] as Map<String, dynamic>;
    final topicProgress = progress[topic] as Map<String, dynamic>?;
    final levelProgress = topicProgress?[level] as Map<String, dynamic>?;
    
    if (levelProgress?['completed_at'] != null) {
      return (levelProgress!['completed_at'] as Timestamp).toDate();
    }
    return null;
  }
  
  // Get current streak
  int getCurrentStreak() {
    if (_userData == null) return 0;
    
    final lastActivity = _userData!['last_activity'] as Timestamp?;
    final streak = _userData!['current_streak'] as int? ?? 0;
    
    if (lastActivity == null) return 0;
    
    final now = DateTime.now();
    final lastActivityDate = lastActivity.toDate();
    final difference = now.difference(lastActivityDate).inDays;
    
    // If more than 1 day has passed, streak is broken
    if (difference > 1) {
      // Reset streak
      updateStreak(0);
      return 0;
    }
    
    return streak;
  }
  
  // Update streak
  Future<void> updateStreak(int newStreak) async {
    if (_userData == null) return;
    
    try {
      final email = _userData!['email'];
      await _firestore.collection('users').doc(email).update({
        'current_streak': newStreak,
        'last_activity': FieldValue.serverTimestamp(),
        if (newStreak > (_userData!['best_streak'] ?? 0))
          'best_streak': newStreak,
      });
      await loadUserData(email);
    } catch (e) {
      print('Error updating streak: $e');
      rethrow;
    }
  }
  
  // Get total score
  int getTotalScore() {
    if (_userData == null) return 0;
    return (_userData!['total_score'] ?? 0) as int;
  }
  
  // Get badges
  List<String> getBadges() {
    if (_userData == null || _userData!['badges'] == null) return [];
    return List<String>.from(_userData!['badges']);
  }
}