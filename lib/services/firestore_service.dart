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
  
  // Update user progress
  Future<void> updateProgress(String email, String topic, String level, bool completed) async {
    try {
      await _firestore.collection('users').doc(email).update({
        'progress.$topic.$level': completed,
      });
      await loadUserData(email);
    } catch (e) {
      print('Error updating progress: $e');
      rethrow;
    }
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
  
  // Get user progress percentage
  double getProgressPercentage() {
    if (_userData == null || _userData!['progress'] == null) return 0.0;
    
    final progress = _userData!['progress'] as Map<String, dynamic>;
    int completedCount = 0;
    int totalCount = 0;
    
    progress.forEach((topic, levels) {
      if (levels is Map) {
        levels.forEach((level, completed) {
          totalCount++;
          if (completed == true) completedCount++;
        });
      }
    });
    
    if (totalCount == 0) return 0.0;
    return (completedCount / totalCount) * 100;
  }
  
  // Check if topic level is completed
  bool isLevelCompleted(String topic, String level) {
    if (_userData == null || _userData!['progress'] == null) return false;
    
    final progress = _userData!['progress'] as Map<String, dynamic>;
    if (!progress.containsKey(topic)) return false;
    
    final topicProgress = progress[topic] as Map<String, dynamic>?;
    if (topicProgress == null) return false;
    
    return topicProgress[level] == true;
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