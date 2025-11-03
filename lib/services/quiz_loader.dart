import 'dart:convert';
import 'package:flutter/services.dart';

class Question {
  final String id;  // Changed from int to String to match new format (e.g., "NS_E_1")
  final String question;
  final List<String> options;
  final String correctOption;
  final String? explanation;

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOption,
    this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      question: json['question'],
      options: List<String>.from(json['options']),
      correctOption: json['correct_option'],
      explanation: json['explanation'],
    );
  }
}

class QuizData {
  final String topic;
  final String level;
  final List<Question> questions;

  QuizData({
    required this.topic,
    required this.level,
    required this.questions,
  });

  factory QuizData.fromJson(Map<String, dynamic> json, String selectedLevel) {
    // Get questions for the specific level from the new structure
    final levelData = json['levels'][selectedLevel.toLowerCase()];
    return QuizData(
      topic: json['topic'],
      level: selectedLevel,
      questions: (levelData['questions'] as List)
          .map((q) => Question.fromJson(q))
          .toList(),
    );
  }
}

class QuizLoader {
  // Load quiz from JSON file
  Future<QuizData> loadQuiz(String category, String topic, String level) async {
    try {
      final topicKey = _getTopicKey(topic);
      final path = 'lib/assets/$category/$topicKey.json';
      
      print('Loading quiz from: $path');
      print('Category: $category, Topic: $topic, Level: $level');
      print('Topic key: $topicKey');
      
      final String jsonString = await rootBundle.loadString(path);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      final quizData = QuizData.fromJson(jsonData, level);
      print('Successfully loaded ${quizData.questions.length} questions for $level level');
      return quizData;
    } catch (e) {
      print('Error loading quiz: $e');
      print('Category: $category, Topic: $topic, Level: $level');
      // Return sample data if file doesn't exist
      return _getSampleQuiz(topic, level);
    }
  }
  
  // Convert topic name to file key
  String _getTopicKey(String topic) {
    return topic.toLowerCase()
        .replaceAll(' & ', '_')
        .replaceAll(' ', '_')
        .replaceAll('-', '_');
  }
  
  // Sample quiz data (fallback)
  QuizData _getSampleQuiz(String topic, String level) {
    final prefix = topic.split(' ').map((word) => word[0].toUpperCase()).join('');
    return QuizData(
      topic: topic,
      level: level,
      questions: [
        Question(
          id: '${prefix}_${level[0].toUpperCase()}_1',
          question: 'Sample Question 1 for $topic ($level)?',
          options: ['Option A', 'Option B', 'Option C', 'Option D'],
          correctOption: 'Option A',
          explanation: 'This is a sample question. Please add actual questions in JSON files.',
        ),
        Question(
          id: '${prefix}_${level[0].toUpperCase()}_2',
          question: 'Sample Question 2 for $topic ($level)?',
          options: ['Choice 1', 'Choice 2', 'Choice 3', 'Choice 4'],
          correctOption: 'Choice 2',
          explanation: 'Another sample question for demonstration.',
        ),
        Question(
          id: '${prefix}_${level[0].toUpperCase()}_3',
          question: 'Sample Question 3 for $topic ($level)?',
          options: ['Answer 1', 'Answer 2', 'Answer 3', 'Answer 4'],
          correctOption: 'Answer 3',
        ),
      ],
    );
  }
}