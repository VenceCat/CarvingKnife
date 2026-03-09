import 'package:flutter/material.dart';
import '../app.dart';

class AppVisuals {
  final bool useWallpaper;
  final bool useGlassEffect;
  final BoxDecoration? wallpaperDecoration;
  final Color pageBackgroundColor;
  final Color cardColor;
  final Color secondaryTextColor;
  final Color mutedTextColor;
  final Color softTextColor;
  final Color titleColor;
  final List<Shadow>? titleShadows;
  final List<Shadow>? bodyTextShadows;

  const AppVisuals({
    required this.useWallpaper,
    required this.useGlassEffect,
    required this.wallpaperDecoration,
    required this.pageBackgroundColor,
    required this.cardColor,
    required this.secondaryTextColor,
    required this.mutedTextColor,
    required this.softTextColor,
    required this.titleColor,
    required this.titleShadows,
    required this.bodyTextShadows,
  });

  static AppVisuals resolve(BuildContext context) {
    final theme = Theme.of(context);
    final appState = HabitApp.of(context);
    final useWallpaper = appState?.useWallpaper ?? false;
    final useGlassEffect = appState?.glassEffectEnabled ?? false;
    final isGlassWallpaper = useWallpaper && useGlassEffect;

    return AppVisuals(
      useWallpaper: useWallpaper,
      useGlassEffect: useGlassEffect,
      wallpaperDecoration: appState?.wallpaperDecoration,
      pageBackgroundColor:
          useWallpaper ? Colors.transparent : theme.scaffoldBackgroundColor,
      cardColor: useGlassEffect
          ? Colors.white.withValues(alpha: useWallpaper ? 0.52 : 0.88)
          : useWallpaper
              ? Colors.white.withValues(alpha: 0.92)
              : Colors.white,
      secondaryTextColor: isGlassWallpaper
          ? const Color(0xFF42505C)
          : useGlassEffect
              ? Colors.grey.shade700
              : Colors.grey.shade600,
      mutedTextColor: isGlassWallpaper
          ? const Color(0xFF5F6D79)
          : useGlassEffect
              ? Colors.grey.shade600
              : Colors.grey.shade500,
      softTextColor: isGlassWallpaper
          ? const Color(0xFF5F6D79)
          : useWallpaper
              ? Colors.white70
              : Colors.grey.shade500,
      titleColor: useWallpaper ? Colors.white : theme.colorScheme.onSurface,
      titleShadows: useWallpaper
          ? [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 4,
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ]
          : null,
      bodyTextShadows: isGlassWallpaper
          ? [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 6,
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ]
          : null,
    );
  }
}
