import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import 'level_select_screen.dart';

class TopicListScreen extends StatelessWidget {
  final String category;

  const TopicListScreen({super.key, required this.category});

  static final Map<String, List<String>> topics = {
    'aptitude': [
      'Number System',
      'HCF & LCM',
      'Decimal Fractions',
      'Simplification',
      'Square & Cube Roots',
      'Average',
      'Problems on Ages',
      'Surds & Indices',
      'Percentage',
      'Profit & Loss',
      'Ratio & Proportion',
      'Time & Work',
      'Time & Distance',
      'Simple Interest & Compound Interest',
      'Area',
      'Volume & Surface Area',
      'Probability',
      'Calendar & Clocks',
      'Pie Chart',
      'Bar Graphs',
      'Line Graphs',
    ],
    'reasoning': [
      'Analogy',
      'Classification',
      'Series Completion',
      'Coding-Decoding',
      'Blood Relations',
      'Puzzle Test',
      'Direction Sense',
      'Venn Diagrams',
      'Alphabet Test',
      'Number/Ranking Test',
      'Data Sufficiency',
      'Statement-Arguments',
      'Statement-Conclusions',
      'Logical Deductions',
      'Mirror Images',
      'Embedded Figures',
      'Cubes & Dice',
      'Figure Matrix',
      'Paper Folding & Completion',
    ],
  };

  static final Map<String, String> topicEmojis = {
    'Number System': '🔢',
    'HCF & LCM': '➗',
    'Decimal Fractions': '🔸',
    'Simplification': '✨',
    'Square & Cube Roots': '√',
    'Average': '📊',
    'Problems on Ages': '👶👴',
    'Surds & Indices': '∛',
    'Percentage': '%',
    'Profit & Loss': '💰',
    'Ratio & Proportion': '⚖️',
    'Time & Work': '⏰',
    'Time & Distance': '🚗',
    'Simple Interest & Compound Interest': '💵',
    'Area': '📐',
    'Volume & Surface Area': '📦',
    'Probability': '🎲',
    'Calendar & Clocks': '📅',
    'Pie Chart': '🥧',
    'Bar Graphs': '📊',
    'Line Graphs': '📈',
    'Analogy': '🔗',
    'Classification': '📂',
    'Series Completion': '🔢',
    'Coding-Decoding': '🔐',
    'Blood Relations': '👨‍👩‍👧‍👦',
    'Puzzle Test': '🧩',
    'Direction Sense': '🧭',
    'Venn Diagrams': '⭕',
    'Alphabet Test': '🔤',
    'Number/Ranking Test': '🔢',
    'Data Sufficiency': '📋',
    'Statement-Arguments': '💭',
    'Statement-Conclusions': '✅',
    'Logical Deductions': '🧠',
    'Mirror Images': '🪞',
    'Embedded Figures': '🎨',
    'Cubes & Dice': '🎲',
    'Figure Matrix': '⬜',
    'Paper Folding & Completion': '📄',
  };

  @override
  Widget build(BuildContext context) {
    final categoryTopics = topics[category] ?? [];
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          category == 'aptitude' ? 'Aptitude Topics' : 'Reasoning Topics',
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categoryTopics.length,
        itemBuilder: (context, index) {
          final topic = categoryTopics[index];
          final emoji = topicEmojis[topic] ?? '📝';
          
          // Calculate topic progress
          int completedLevels = 0;
          for (String level in ['easy', 'medium', 'hard']) {
            if (firestoreService.isLevelCompleted(topic, level)) {
              completedLevels++;
            }
          }
          
          final progressPercent = (completedLevels / 3) * 100;
          final isCompleted = completedLevels == 3;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LevelSelectScreen(
                      category: category,
                      topic: topic,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xFF43A047)
                        : Colors.grey.withOpacity(0.2),
                    width: isCompleted ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: category == 'aptitude'
                                ? const Color(0xFF1E88E5).withOpacity(0.1)
                                : const Color(0xFF43A047).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                topic,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$completedLevels/3 levels completed',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF43A047),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '✓ Done',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                      ],
                    ),
                    if (completedLevels > 0) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressPercent / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            category == 'aptitude'
                                ? const Color(0xFF1E88E5)
                                : const Color(0xFF43A047),
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}