import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final IconData icon;
  final String title;
  final String description;
  final bool isUnlocked;
  final double progress;
  final int current;
  final int target;
  final String category;

  const Achievement({
    this.id = '',
    required this.icon,
    required this.title,
    required this.description,
    required this.isUnlocked,
    required this.progress,
    required this.current,
    required this.target,
    required this.category,
  });
}