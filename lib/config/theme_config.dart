import 'package:flutter/material.dart';

class ThemeColorOption {
  final String name;
  final Color color;
  final Color backgroundColor;

  const ThemeColorOption({
    required this.name,
    required this.color,
    required this.backgroundColor,
  });
}

class ThemeConfig {
  static const List<ThemeColorOption> colorOptions = [
    ThemeColorOption(
      name: '默认灰',
      color: Color(0xFF78909C),
      backgroundColor: Color(0xFFFAFAFA),
    ),
    ThemeColorOption(
      name: '清新绿',
      color: Color(0xFF26A69A),
      backgroundColor: Color(0xFFF5FAF8),
    ),
    ThemeColorOption(
      name: '天空蓝',
      color: Color(0xFF42A5F5),
      backgroundColor: Color(0xFFF5F9FC),
    ),
    ThemeColorOption(
      name: '活力橙',
      color: Color(0xFFFF9800),
      backgroundColor: Color(0xFFFFFBF5),
    ),
    ThemeColorOption(
      name: '优雅紫',
      color: Color(0xFFAB47BC),
      backgroundColor: Color(0xFFFAF5FC),
    ),
    ThemeColorOption(
      name: '玫瑰粉',
      color: Color(0xFFEC407A),
      backgroundColor: Color(0xFFFCF5F7),
    ),
    ThemeColorOption(
      name: '薄荷青',
      color: Color(0xFF26C6DA),
      backgroundColor: Color(0xFFF5FBFC),
    ),
    ThemeColorOption(
      name: '新年红',
      color: Color(0xFFE53935),
      backgroundColor: Color(0xFFFFF8F7),
    ),
    ThemeColorOption(
      name: '沉稳黑',
      color: Color(0xFF455A64),
      backgroundColor: Color(0xFFF5F5F5),
    ),
  ];
}
