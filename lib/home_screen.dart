// lib/screens/home_screen.dart - Dark mode fixes

import 'package:cs_exit_exam_app/screens/achievement_screen.dart';
import 'package:cs_exit_exam_app/screens/history_screen.dart';
import 'package:cs_exit_exam_app/screens/performance_dashboard_screen.dart';
import 'package:cs_exit_exam_app/screens/resource_library_screen.dart';
import 'package:cs_exit_exam_app/screens/settings_screen.dart';
import 'package:cs_exit_exam_app/screens/subject_list_screen.dart';
import 'package:cs_exit_exam_app/services/achievement_service.dart';
import 'package:cs_exit_exam_app/services/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import '../models/achievement_model.dart';
import '../utils/json_loader.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  String? _userName;
  String? _avatarPath;
  late AnimationController _controller;
  
  // Stats variables
  int _totalAttempts = 0;
  int _totalTime = 0;
  double _averageScore = 0.0;
  int _subjectsCount = 0;
  
  // Debug mode (optional - remove if not needed)
  bool _showDebugButton = false;
  int _tapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _loadUserData();
    _loadStats();
    _loadSubjectsCount();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Student';
      _avatarPath = prefs.getString('avatarPath');

    });
  }

  Future<void> _loadStats() async {
    try {
      final results = await DatabaseHelper.getAllResults();
      
      if (results.isNotEmpty) {
        setState(() {
          _totalAttempts = results.length;
          
          double totalScore = 0;
          _totalTime = 0;
          
          for (final result in results) {
            totalScore += result['score'] as double;
            _totalTime += result['time_spent'] as int;
          }
          
          _averageScore = totalScore / _totalAttempts;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }
  Future<void> _launchTelegram() async {
    final Uri url = Uri.parse('https://t.me/cs_exit_exams'); // Replace with your actual link
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _loadSubjectsCount() async {
    try {
      final subjects = await JsonLoader.loadSubjects();
      setState(() {
        _subjectsCount = subjects.length;
      });
    } catch (e) {
      debugPrint('Error loading subjects count: $e');
      setState(() {
        _subjectsCount = 28; // Default fallback
      });
    }
  }

  Future<void> _refreshStats() async {
    await _loadStats();
    await _loadSubjectsCount();
  }

  void _onAvatarTap() {
    final now = DateTime.now();
    if (_lastTapTime == null || now.difference(_lastTapTime!) < const Duration(seconds: 2)) {
      _tapCount++;
    } else {
      _tapCount = 1;
    }
    _lastTapTime = now;
    
    if (_tapCount >= 5) {
      setState(() {
        _showDebugButton = !_showDebugButton;
      });
      _tapCount = 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_showDebugButton ? 'Debug mode enabled' : 'Debug mode disabled'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  // Determine if we are on a wide screen
  final double screenWidth = MediaQuery.of(context).size.width;
  final bool isWeb = screenWidth > 600;

  return Scaffold(
    appBar: AppBar(
      title: const Text("CS Exit Exam", style: TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: isWeb, // Center title on web for a cleaner look
      actions: [
        if (_showDebugButton) IconButton(icon: const Icon(Icons.bug_report), onPressed: () => Navigator.pushNamed(context, '/debug')),
        IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshStats),
      ],
    ),
    body: Stack(
      children: [
        const AnimatedBackground(),
        Center( // 1. Keeps everything centered on wide screens
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWeb ? 1000 : double.infinity), // 2. Max width 1000px
            child: RefreshIndicator(
              onRefresh: _refreshStats,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWeb ? 40 : 16, 
                  vertical: 16
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    const SizedBox(height: 20),
                    
                    // 3. Dynamic Grid Logic
                    _buildDashboardCards(screenWidth), 
                    
                    const SizedBox(height: 20),
                    _buildQuickStats(),
                    const SizedBox(height: 16),
                    
                    // On Web, we can put Recent Activity and Achievements side-by-side
                    isWeb 
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildRecentActivity()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildAchievementsPreview()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildRecentActivity(),
                            const SizedBox(height: 16),
                            _buildAchievementsPreview(),
                          ],
                        ),
                        
                    if (_showDebugButton) _buildDebugSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    bottomNavigationBar: isWeb ? null : _buildBottomNavigationBar(), // Hide bottom bar on web if you prefer a sidebar later
  );
}

  Widget _buildWelcomeCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: _onAvatarTap,
        hoverColor: Colors.white10, // Slight highlight on hover
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: _avatarPath != null
                    ? Image.asset(_avatarPath!).image
                    : const AssetImage('assets/images/default_avatar.png'),
              ),
              
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome to CS Exit Exam",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                    Text(
                      _userName ?? 'Student',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Computer Science",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

 // Updated Grid with dynamic column count
Widget _buildDashboardCards(double width) {
  // Dynamic column count: 2 for mobile, 3 for tablets, 4 for desktops
  int crossAxisCount = width < 600 ? 2 : (width < 900 ? 3 : 4);
  
  // Adjust aspect ratio based on width
  // Higher number = shorter cards
  double aspectRatio = width < 600 ? 1.1 : 1.5;
  return GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: crossAxisCount, // Dynamic columns
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
    childAspectRatio: aspectRatio, 
    children: [
      _buildDashboardCard(
        icon: Icons.quiz,
        title: 'Start Exam',
        subtitle: 'Practice',
        color: Colors.deepPurple,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SubjectListScreen())),
      ),
      _buildDashboardCard(
        icon: Icons.analytics,
        title: 'Analytics',
        subtitle: 'Progress',
        color: Colors.green,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PerformanceDashboardScreen())),
      ),
      _buildDashboardCard(
        icon: Icons.history,
        title: 'History',
        subtitle: 'Past Exams',
        color: Colors.blueAccent,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())),
      ),
      _buildDashboardCard(
        icon: Icons.settings,
        title: 'Settings',
        subtitle: 'Preferences',
        color: Colors.orange,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
      ),
      _buildDashboardCard(
        icon: Icons.groups,
        title: 'Community',
        subtitle: 'Chat with Testers',
        color: Colors.blueAccent,
        onTap: _launchTelegram,
      ),
      _buildDashboardCard(
        icon: Icons.library_books,
        title: 'Resources',
        subtitle: 'Study Materials',
        color: Colors.blueGrey,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ResourceLibraryScreen())),
      ),
    ],
  );
}

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.7)],
            ),
          ),
          child: Padding(
            //padding: const EdgeInsets.all(12.0),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Add this!
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 24, color: Colors.white),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                //const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Quick Stats",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.deepPurple,
                  ),
                ),
                Text(
                  'Updated: ${_formatLastUpdated()}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.subject, "$_subjectsCount", "Subjects"),
                _buildStatItem(Icons.quiz, "$_totalAttempts", "Exams"),
                _buildStatItem(Icons.timer, _formatTotalTime(), "Time"),
                _buildStatItem(Icons.percent, "${_averageScore.toStringAsFixed(1)}%", "Avg"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Icon(icon, size: 22, color: isDark ? Colors.white70 : Colors.deepPurple),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white60 : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.getAllResults(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final recentResults = snapshot.data ?? [];
        final recent = recentResults.take(3).toList();

        if (recent.isEmpty) return const SizedBox.shrink();

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Recent",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 12),
                ...recent.map((result) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildRecentItem(result),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentItem(Map<String, dynamic> result) {
  final score = result['score'] as double;
  final subject = result['subject_name'] as String;
  
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        // The Icon Indicator
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _getScoreColor(score).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.quiz,
            color: _getScoreColor(score),
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        // The Text - Now truly responsive
        Expanded(
          child: Text(
            subject,
            style: const TextStyle(fontSize: 13),
            maxLines: 1, // Keeps it on one line
            overflow: TextOverflow.ellipsis, // Adds "..." automatically if it's too long
          ),
        ),
        const SizedBox(width: 8),
        // The Score Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _getScoreColor(score),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${score.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildAchievementsPreview() {
  final isDark = Theme.of(context).brightness == Brightness.dark;
    return FutureBuilder<AchievementStats>(
      future: AchievementService().getAchievementStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final stats = snapshot.data!;
        final unlocked = stats.unlockedBadges;
        final total = stats.totalBadges;
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AchievementScreen()),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.deepPurple.withValues(alpha: 0.2) : Colors.deepPurple.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: Colors.deepPurple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Achievements',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$unlocked/$total badges',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDebugSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                const Text(
                  "Debug Mode",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 16),
                  onPressed: () {
                    setState(() {
                      _showDebugButton = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('DB'),
                  backgroundColor: Colors.blue,
                  labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
                  onPressed: () => Navigator.pushNamed(context, '/debug'),
                ),
                ActionChip(
                  label: const Text('Clear'),
                  backgroundColor: Colors.red,
                  labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
                  onPressed: _showClearAllDataDialog,
                ),
                ActionChip(
                  label: const Text('Test'),
                  backgroundColor: Colors.green,
                  labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
                  onPressed: _testSubjectsLoad,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Exams'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
      currentIndex: 0,
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        switch (index) {
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SubjectListScreen()),
            );
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            );
            break;
          case 3:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
            break;
        }
      },
    );
  }

  // Helper Methods
  String _formatTotalTime() {
    if (_totalTime == 0) return '0m';
    final hours = _totalTime ~/ 3600;
    final minutes = (_totalTime % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatLastUpdated() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  // Debug Methods
  Future<void> _showClearAllDataDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text('This will delete all exam results, progress, and settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await DatabaseHelper.clearAllResults();
        await _refreshStats();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared'), backgroundColor: Colors.green),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _testSubjectsLoad() async {
    try {
      final subjects = await JsonLoader.loadSubjects();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Loaded ${subjects.length} subjects'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return CustomPaint(
          painter: WavePainter(_controller.value),
          child: Container(),
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double value;

  WavePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepPurple.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final path = Path();
    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height * 0.9 +
            math.sin((i / size.width * 2 * math.pi) + (value * 2 * math.pi)) * 15,
      );
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}