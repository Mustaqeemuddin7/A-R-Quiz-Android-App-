import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/quiz_loader.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/progress_service.dart';
import 'level_complete_screen.dart';

class QuizScreen extends StatefulWidget {
  final String category;
  final String topic;
  final String level;

  const QuizScreen({
    super.key,
    required this.category,
    required this.topic,
    required this.level,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuizLoader _quizLoader = QuizLoader();
  QuizData? _quizData;
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  String? _selectedOption;
  bool _isAnswered = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      final quizData = await _quizLoader.loadQuiz(
        widget.category,
        widget.topic,
        widget.level,
      );
      setState(() {
        _quizData = quizData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading quiz: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectOption(String option) {
    if (_isAnswered) return;

    setState(() {
      _selectedOption = option;
      _isAnswered = true;

      if (option == _currentQuestion.correctOption) {
        _correctAnswers++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _quizData!.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = null;
        _isAnswered = false;
      });
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final progressService = Provider.of<ProgressService>(context, listen: false);

    final email = authService.getUserEmail();
    if (email == null) return;

    final totalQuestions = _quizData!.questions.length;
    final score = progressService.calculateScore(
      _correctAnswers,
      totalQuestions,
      widget.level,
    );

    // Update progress and score
    await firestoreService.updateProgress(
      email,
      widget.topic,
      widget.level.toLowerCase(),
      true,
    );
    await firestoreService.updateScore(email, score);

    // Check and award badges
    await progressService.checkAndAwardBadges(email);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LevelCompleteScreen(
            topic: widget.topic,
            level: widget.level,
            correctAnswers: _correctAnswers,
            totalQuestions: totalQuestions,
            score: score,
          ),
        ),
      );
    }
  }

  Question get _currentQuestion => _quizData!.questions[_currentQuestionIndex];

  Color _getOptionColor(String option) {
    if (!_isAnswered) {
      return _selectedOption == option
          ? const Color(0xFFE53935).withOpacity(0.1)
          : Colors.white;
    }

    if (option == _currentQuestion.correctOption) {
      return const Color(0xFF4CAF50).withOpacity(0.2);
    }

    if (option == _selectedOption && option != _currentQuestion.correctOption) {
      return const Color(0xFFE53935).withOpacity(0.2);
    }

    return Colors.white;
  }

  Color _getOptionBorderColor(String option) {
    if (!_isAnswered) {
      return _selectedOption == option
          ? const Color(0xFFE53935)
          : Colors.grey.withOpacity(0.3);
    }

    if (option == _currentQuestion.correctOption) {
      return const Color(0xFF4CAF50);
    }

    if (option == _selectedOption && option != _currentQuestion.correctOption) {
      return const Color(0xFFE53935);
    }

    return Colors.grey.withOpacity(0.3);
  }

  IconData? _getOptionIcon(String option) {
    if (!_isAnswered) return null;

    if (option == _currentQuestion.correctOption) {
      return Icons.check_circle;
    }

    if (option == _selectedOption && option != _currentQuestion.correctOption) {
      return Icons.cancel;
    }

    return null;
  }

  Color? _getOptionIconColor(String option) {
    if (!_isAnswered) return null;

    if (option == _currentQuestion.correctOption) {
      return const Color(0xFF4CAF50);
    }

    if (option == _selectedOption && option != _currentQuestion.correctOption) {
      return const Color(0xFFE53935);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.topic),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFE53935),
          ),
        ),
      );
    }

    if (_quizData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.topic),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFE53935),
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load quiz',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final totalQuestions = _quizData!.questions.length;
    final progress = (_currentQuestionIndex + 1) / totalQuestions;

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Quiz?'),
            content: const Text('Your progress will be lost if you exit now.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE53935),
                ),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.level} - ${widget.topic}'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Question Counter
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1}/$totalQuestions',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Score: $_correctAnswers',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE53935),
                      ),
                    ),
                  ],
                ),
              ),

              // Question Card
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Text(
                          _currentQuestion.question,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Options
                      ..._currentQuestion.options.asMap().entries.map((entry) {
                        final option = entry.value;
                        final index = entry.key;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _selectOption(option),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _getOptionColor(option),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getOptionBorderColor(option),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: _getOptionBorderColor(option).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + index), // A, B, C, D
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _getOptionBorderColor(option),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (_getOptionIcon(option) != null)
                                    Icon(
                                      _getOptionIcon(option),
                                      color: _getOptionIconColor(option),
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),

                      // Explanation (if answered)
                      if (_isAnswered && _currentQuestion.explanation != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue[200]!,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: Colors.blue[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Explanation',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _currentQuestion.explanation!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue[900],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Next Button
              if (_isAnswered)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: Text(
                      _currentQuestionIndex < totalQuestions - 1
                          ? 'Next Question'
                          : 'Finish Quiz',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}