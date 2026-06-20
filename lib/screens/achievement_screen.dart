// lib/screens/achievement_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/achievement_service.dart';
import '../models/achievement_model.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> 
    with SingleTickerProviderStateMixin {
  late Future<List<AchievementBadge>> _badgesFuture;
  late Future<AchievementStats> _statsFuture;
  late TabController _tabController;
  
  final AchievementService _achievementService = AchievementService();
  String _selectedFilter = 'all'; // all, unlocked, locked
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    setState(() {
      _badgesFuture = _achievementService.getAllBadgesWithProgress();
      _statsFuture = _achievementService.getAchievementStats();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Achievements',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events), text: 'Badges'),
            Tab(icon: Icon(Icons.analytics), text: 'Statistics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBadgesTab(),
          _buildStatisticsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        backgroundColor: Colors.deepPurple,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  // ==================== BADGES TAB ====================
  Widget _buildBadgesTab() {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: FutureBuilder<List<AchievementBadge>>(
            future: _badgesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              final badges = snapshot.data ?? [];
              final filteredBadges = _filterBadges(badges);
              
              if (filteredBadges.isEmpty) {
                return _buildEmptyState();
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8, // Adjusted for better fit
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: filteredBadges.length,
                itemBuilder: (context, index) {
                  return _buildBadgeCard(filteredBadges[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: isDark ? Colors.grey[900] : Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Icon(Icons.filter_list, color: isDark ? Colors.white70 : Colors.grey, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('All'), icon: Icon(Icons.apps)),
              ButtonSegment(value: 'unlocked', label: Text('Unlocked'), icon: Icon(Icons.check_circle)),
              ButtonSegment(value: 'locked', label: Text('Locked'), icon: Icon(Icons.lock)),
            ],
            selected: {_selectedFilter},
            onSelectionChanged: (Set<String> selection) {
              setState(() => _selectedFilter = selection.first);
            },
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith<Color>(
                (states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return isDark ? Colors.white70 : Colors.black87;
                },
              ),
              backgroundColor: WidgetStateProperty.resolveWith<Color>(
                (states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.deepPurple;
                  }
                  return isDark ? Colors.grey[800]! : Colors.grey[200]!;
                },
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildBadgeCard(AchievementBadge badge) {
  final isUnlocked = badge.isUnlocked;
  final progress = badge.progressPercentage;
  
  return Card(
    elevation: isUnlocked ? 2 : 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: isUnlocked
          ? BorderSide(color: badge.rarity.color, width: 1.5)
          : BorderSide.none,
    ),
    child: Container(
      padding: const EdgeInsets.all(8), // Reduced padding
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Important for preventing overflow
        children: [
          // Badge Icon
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? badge.rarity.color.withValues(alpha: .2)
                      : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  badge.icon,
                  size: 24, // Smaller icon
                  color: isUnlocked
                      ? badge.rarity.color
                      : Colors.grey[400],
                ),
              ),
              if (badge.isSecret && !isUnlocked)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.help,
                      size: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Badge Name
          Text(
            badge.name.length > 15 ? '${badge.name.substring(0, 15)}...' : badge.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isUnlocked 
                ? Theme.of(context).textTheme.bodyLarge?.color 
                : Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
         
          const SizedBox(height: 2),
        
          // Rarity Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: badge.rarity.color.withValues(alpha: .2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge.rarity.name,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: badge.rarity.color,
              ),
            ),
          ),
          
          // Progress Bar (if not unlocked and has progress)
          if (!isUnlocked && badge.maxProgress > 1)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      color: badge.rarity.color,
                      minHeight: 3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    badge.progressText,
                    style: TextStyle(
                      fontSize: 8,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          
          if (isUnlocked && badge.unlockedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                DateFormat('MMM d').format(badge.unlockedAt!),
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

  // ==================== STATISTICS TAB ====================
  Widget _buildStatisticsTab() {
    return FutureBuilder<AchievementStats>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final stats = snapshot.data!;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressOverview(stats),
              const SizedBox(height: 24),
              _buildBadgeCollection(stats),
              const SizedBox(height: 24),
              _buildRecentUnlocks(),
              const SizedBox(height: 24),
              _buildNextMilestones(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressOverview(AchievementStats stats) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade700,
              Colors.deepPurple.shade400,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Text(
              'Collection Progress',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: stats.completionPercentage / 100,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                    strokeWidth: 10,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${stats.unlockedBadges}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'of ${stats.totalBadges}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (stats.lastUnlock != null)
              Text(
                'Last unlocked: ${DateFormat('MMM d, y').format(stats.lastUnlock!)}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeCollection(AchievementStats stats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Badge Collection by Rarity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRarityIndicator(
                  'Bronze',
                  stats.bronzeBadges,
                  BadgeRarity.bronze.color,
                ),
                _buildRarityIndicator(
                  'Silver',
                  stats.silverBadges,
                  BadgeRarity.silver.color,
                ),
                _buildRarityIndicator(
                  'Gold',
                  stats.goldBadges,
                  BadgeRarity.gold.color,
                ),
                _buildRarityIndicator(
                  'Platinum',
                  stats.platinumBadges,
                  BadgeRarity.platinum.color,
                ),
                _buildRarityIndicator(
                  'Diamond',
                  stats.diamondBadges,
                  BadgeRarity.diamond.color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRarityIndicator(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                //fontSize: 11,
                fontSize: 10, 
                color: Theme.of(context).textTheme.bodyMedium?.color
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRecentUnlocks() {
    return FutureBuilder<List<AchievementBadge>>(
      future: _achievementService.getUnlockedBadges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final recentUnlocks = snapshot.data!.take(3).toList();

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Unlocks',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...recentUnlocks.map((badge) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: badge.rarity.color.withValues(alpha: .1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          badge.icon,
                          color: badge.rarity.color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              badge.name,
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Unlocked ${DateFormat('MMM d').format(badge.unlockedAt!)}',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badge.rarity.color.withValues(alpha: .2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badge.rarity.name,
                          style: TextStyle(
                            fontSize: 10,
                            color: badge.rarity.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNextMilestones() {
    return FutureBuilder<List<AchievementBadge>>(
      future: _achievementService.getAllBadgesWithProgress(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final nextMilestones = snapshot.data!
            .where((b) => !b.isUnlocked && b.progressPercentage > 0)
            .take(3)
            .toList();

        if (nextMilestones.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next Milestones',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...nextMilestones.map((badge) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            badge.icon,
                            size: 16,
                            color: badge.rarity.color,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              badge.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '${(badge.progressPercentage * 100).toInt()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: badge.progressPercentage,
                          backgroundColor: Colors.grey[200],
                          color: badge.rarity.color,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        badge.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== HELPER METHODS ====================
  List<AchievementBadge> _filterBadges(List<AchievementBadge> badges) {
    switch (_selectedFilter) {
      case 'unlocked':
        return badges.where((b) => b.isUnlocked).toList();
      case 'locked':
        return badges.where((b) => !b.isUnlocked).toList();
      default:
        return badges;
    }
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Failed to load achievements',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              size: 64,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Badges Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Complete exams to unlock achievements and badges!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}