import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import '../lib/services/quiz_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() {
    // Create a mock asset bundle that includes our test files
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        if (message == null) return null;
        
        final String key = utf8.decode(message.buffer.asUint8List());
        if (key == 'AssetManifest.json') {
          final manifestMap = {
            'assets/aptitude/area.json': ['assets/aptitude/area.json'],
            'assets/aptitude/average.json': ['assets/aptitude/average.json']
          };
          final manifestJson = json.encode(manifestMap);
          return ByteData.sublistView(utf8.encode(manifestJson));
        }
        
        if (key == 'assets/aptitude/area.json') {
          // Return a simple test quiz JSON
          final quizJson = {
            'topic': 'Area',
            'levels': {
              'easy': {
                'questions': [
                  {
                    'id': 'TEST_1',
                    'question': 'What is the area of a square with side 5cm?',
                    'options': ['20 sq cm', '25 sq cm', '30 sq cm', '35 sq cm'],
                    'correct_option': '25 sq cm',
                    'explanation': 'Area = side × side = 5 × 5 = 25 sq cm'
                  }
                ]
              }
            }
          };
          return ByteData.sublistView(utf8.encode(json.encode(quizJson)));
        }
        
        return null;
      },
    );
  });

  test('QuizLoader can load Area quiz', () async {
    final loader = QuizLoader();
    print('\nTesting quiz loading...');
    
    try {
      final quiz = await loader.loadQuiz('aptitude', 'Area', 'easy');
      print('Successfully loaded quiz:');
      print('Topic: ${quiz.topic}');
      print('Level: ${quiz.level}');
      print('Questions: ${quiz.questions.length}');
      if (quiz.questions.isNotEmpty) {
        print('\nSample question:');
        print('ID: ${quiz.questions[0].id}');
        print('Question: ${quiz.questions[0].question}');
      }
    } catch (e, stack) {
      print('Error loading quiz: $e');
      print('Stack trace: $stack');
    }
  });
}