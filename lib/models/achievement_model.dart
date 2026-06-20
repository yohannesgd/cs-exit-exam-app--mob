// lib/models/achievement_model.dart

import 'package:flutter/material.dart';

enum BadgeRarity {
  bronze,
  silver,
  gold,
  platinum,
  diamond;

  Color get color {
    switch (this) {
      case BadgeRarity.bronze:
        return const Color(0xFFCD7F32); // Bronze
      case BadgeRarity.silver:
        return const Color(0xFFC0C0C0); // Silver
      case BadgeRarity.gold:
        return const Color(0xFFFFD700); // Gold
      case BadgeRarity.platinum:
        return const Color(0xFFE5E4E2); // Platinum
      case BadgeRarity.diamond:
        return const Color(0xFFB9F2FF); // Diamond
    }
  }

  String get name {
    switch (this) {
      case BadgeRarity.bronze:
        return 'Bronze';
      case BadgeRarity.silver:
        return 'Silver';
      case BadgeRarity.gold:
        return 'Gold';
      case BadgeRarity.platinum:
        return 'Platinum';
      case BadgeRarity.diamond:
        return 'Diamond';
    }
  }
}

enum BadgeCategory {
  excellence(Icons.emoji_events),
  consistency(Icons.trending_up),
  speed(Icons.speed),
  mastery(Icons.psychology),
  dedication(Icons.favorite),
  milestone(Icons.stars);

  const BadgeCategory(this.icon);

  final IconData icon;

  String get displayName {
    switch (this) {
      case BadgeCategory.excellence:
        return 'Excellence';
      case BadgeCategory.consistency:
        return 'Consistency';
      case BadgeCategory.speed:
        return 'Speed';
      case BadgeCategory.mastery:
        return 'Mastery';
      case BadgeCategory.dedication:
        return 'Dedication';
      case BadgeCategory.milestone:
        return 'Milestone';
    }
  }
}

class AchievementBadge {
  final String id;
  final String name;
  final String description;
  final BadgeCategory category;
  final BadgeRarity rarity;
  final IconData icon;
  final double threshold;
  final String metric;
  final bool isSecret;
  final DateTime? unlockedAt;
  final int maxProgress;
  final int currentProgress;

  AchievementBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.rarity,
    required this.icon,
    required this.threshold,
    required this.metric,
    this.isSecret = false,
    this.unlockedAt,
    this.maxProgress = 1,
    this.currentProgress = 0,
  });

  bool get isUnlocked => unlockedAt != null;
  
  double get progressPercentage => (currentProgress / maxProgress).clamp(0.0, 1.0);
  
  String get progressText => '$currentProgress/$maxProgress';

  factory AchievementBadge.fromJson(Map<String, dynamic> json) {
  final category = BadgeCategory.values.firstWhere(
    (e) => e.toString() == 'BadgeCategory.${json['category']}',
    orElse: () => BadgeCategory.milestone,
  );
    return AchievementBadge(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: category,  // ✅ store category
      rarity: BadgeRarity.values.firstWhere(
        (e) => e.toString() == 'BadgeRarity.${json['rarity']}',
        orElse: () => BadgeRarity.bronze,
      ), 
      icon: category.icon,  // Use category's constant icon
      threshold: json['threshold'].toDouble(),
      metric: json['metric'],
      isSecret: json['isSecret'] ?? false,
      maxProgress: json['maxProgress'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.toString().split('.').last,
      'rarity': rarity.toString().split('.').last,
      'icon': icon.codePoint,
      'threshold': threshold,
      'metric': metric,
      'isSecret': isSecret,
      'maxProgress': maxProgress,
    };
  }
}

class UserAchievement {
  final String badgeId;
  final DateTime unlockedAt;
  final double progress;
  final Map<String, dynamic> metadata;

  UserAchievement({
    required this.badgeId,
    required this.unlockedAt,
    required this.progress,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'badgeId': badgeId,
      'unlockedAt': unlockedAt.toIso8601String(),
      'progress': progress,
      'metadata': metadata,
    };
  }

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      badgeId: json['badgeId'],
      unlockedAt: DateTime.parse(json['unlockedAt']),
      progress: json['progress'],
      metadata: json['metadata'] ?? {},
    );
  }
}

class AchievementStats {
  final int totalBadges;
  final int unlockedBadges;
  final int bronzeBadges;
  final int silverBadges;
  final int goldBadges;
  final int platinumBadges;
  final int diamondBadges;
  final DateTime? lastUnlock;

  AchievementStats({
    required this.totalBadges,
    required this.unlockedBadges,
    required this.bronzeBadges,
    required this.silverBadges,
    required this.goldBadges,
    required this.platinumBadges,
    required this.diamondBadges,
    this.lastUnlock,
  });

  double get completionPercentage => 
      totalBadges > 0 ? (unlockedBadges / totalBadges * 100) : 0;
}