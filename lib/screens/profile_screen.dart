import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/progress_service.dart';
 
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);
    final progressService = Provider.of<ProgressService>(context);

    final userName = authService.getUserName() ?? 'User';
    final userEmail = authService.getUserEmail() ?? '';
    final totalScore = firestoreService.getTotalScore();
    final badges = firestoreService.getBadges();
    final progressPercent = firestoreService.getProgressPercentage();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final shouldSignOut = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
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
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );

              if (shouldSignOut == true && context.mounted) {
                await authService.signOut();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE53935),
                    const Color(0xFFD32F2F),
                  ],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: authService.getUserPhotoUrl() != null
                        ? NetworkImage(authService.getUserPhotoUrl()!, headers: const {
                            'Cache-Control': 'no-cache',
                          })
                        : null,
                    onBackgroundImageError: (exception, stackTrace) {
                      debugPrint('Error loading profile image: $exception');
                    },
                    child: Text(
                      userName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE53935),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '⭐',
                          style: TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$totalScore Points',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE53935),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Stats Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Statistics',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      // Streak Widget
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Text(
                              '${firestoreService.getCurrentStreak()} Day Streak',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE53935),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    progressService.getStreakMessage(firestoreService.getCurrentStreak()),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          '📊',
                          'Progress',
                          progressService.formatPercentage(progressPercent),
                          const Color(0xFF1E88E5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          '🏅',
                          'Badges',
                          '${badges.length} / 3',
                          const Color(0xFFFFD700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildProgressCard(
                    context,
                    progressPercent,
                  ),
                  const SizedBox(height: 16),
                  // Topic Progress Section
                  const Text(
                    'Topic Progress',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTopicProgressList(firestoreService, progressService),
                ],
              ),
            ),

            // Badges Section
            if (badges.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Badges',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: badges.map((badge) {
                        return _buildBadgeChip(
                          progressService.getBadgeIcon(badge),
                          badge,
                          progressService.getBadgeColor(badge),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '🏆',
                        style: TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No Badges Yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete topics to earn badges!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // About Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoTile(
                    Icons.quiz,
                    'Quiz Topics',
                    '40 topics (Aptitude + Reasoning)',
                  ),
                  _buildInfoTile(
                    Icons.layers,
                    'Difficulty Levels',
                    'Easy, Medium, Hard',
                  ),
                  _buildInfoTile(
                    Icons.info_outline,
                    'Version',
                    '1.0.0',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String emoji,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 36),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overall Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${progress.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE53935),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFE53935),
              ),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeChip(String emoji, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicProgressList(FirestoreService firestoreService, ProgressService progressService) {
    final topicProgress = firestoreService.getTopicProgress();
    
    return Column(
      children: [
        // Category sections
        _buildCategorySection('Aptitude', topicProgress, firestoreService, progressService),
        const SizedBox(height: 16),
        _buildCategorySection('Reasoning', topicProgress, firestoreService, progressService),
      ],
    );
  }

  Widget _buildCategorySection(String category, Map<String, double> topicProgress, 
      FirestoreService firestoreService, ProgressService progressService) {
    final topics = topicProgress.keys
        .where((topic) => topic.toLowerCase().startsWith(category.toLowerCase()))
        .toList()
      ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              progressService.getCategoryIcon(category),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              category,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...topics.map((topic) => _buildTopicProgressTile(
          topic,
          topicProgress[topic] ?? 0.0,
          firestoreService,
          progressService,
        )),
      ],
    );
  }

  Widget _buildTopicProgressTile(String topic, double progress, 
      FirestoreService firestoreService, ProgressService progressService) {
    final displayTopic = topic.split('/').last.split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
    
    final stats = firestoreService.getLevelStats(topic, 'easy');
    final hasStarted = stats != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  displayTopic,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                progressService.formatPercentage(progress),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: progress == 100 ? Colors.green : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 100 ? Colors.green : const Color(0xFFE53935),
              ),
              minHeight: 6,
            ),
          ),
          if (hasStarted) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${stats['correct_answers'] ?? 0}/${stats['questions_attempted'] ?? 0}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (stats['best_score'] != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.star_outline,
                        size: 16,
                        color: Color(0xFFFFD700),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${stats['best_score']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                if (stats['total_time_spent'] != null)
                  Text(
                    progressService.formatDuration(stats['total_time_spent'] as int),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFE53935),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}