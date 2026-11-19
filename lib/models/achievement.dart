import 'package:flutter/material.dart';

class AchievementItem {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final int gemReward;
  final int currentCount;
  final int targetCount;
  final bool isClaimed;

  const AchievementItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.gemReward,
    required this.currentCount,
    required this.targetCount,
    required this.isClaimed,
  });

  bool get isUnlocked => currentCount >= targetCount;
  bool get canClaim => isUnlocked && !isClaimed;
  double get progress => targetCount <= 0 ? 1.0 : (currentCount / targetCount).clamp(0.0, 1.0);
}
