import 'dart:convert';
import 'package:flutter/services.dart';

class Question {
  final String id;
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
      // Important: Assets are relative to project root
      final path = 'assets/$category/$topicKey.json';
      
      print('DEBUG: Loading quiz from path: $path');
      print('DEBUG: Category=$category, Topic=$topic, Level=$level');
      print('DEBUG: Topic key (filename without .json)=$topicKey');
      
      // List available assets
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      print('DEBUG: Available assets:');
      manifestMap.keys.where((String key) => key.contains('.json')).forEach((String key) {
        print('  - $key');
      });
      
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
        .replaceAll('-', '_')
        .replaceAll('/', '_');
  }
  
  // Sample quiz data (fallback)
  QuizData _getSampleQuiz(String topic, String level) {
    final prefix = topic.split(' ').map((word) => word[0].toUpperCase()).join('');
    final levelPrefix = level.substring(0, 1).toUpperCase();
    
    return QuizData(
      topic: topic,
      level: level,
      questions: List.generate(5, (index) {
        final questionNumber = index + 1;
        return Question(
          id: '${prefix}_${levelPrefix}_$questionNumber',
          question: 'Sample Question $questionNumber for $topic ($level level)?',
          options: [
            'Option A - Sample answer',
            'Option B - Sample answer',
            'Option C - Sample answer',
            'Option D - Sample answer'
          ],
          correctOption: 'Option A - Sample answer',
          explanation: 'This is a sample question. Please add actual questions in the JSON file at assets/$_getTopicKey(topic).json',
        );
      }),
    );
  }
}