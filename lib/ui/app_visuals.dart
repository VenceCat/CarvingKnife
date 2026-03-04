import 'package:flutter/material.dart';
import '../app.dart';

class AppVisuals {
  final bool useWallpaper;
  final bool useGlassEffect;
  final BoxDecoration? wallpaperDecoration;
  final Color pageBackgroundColor;
  final Color cardColor;
  final Color softTextColor;
  final Color titleColor;
  final List<Shadow>? titleShadows;

  const AppVisuals({
    required this.useWallpaper,
    required this.useGlassEffect,
    required this.wallpaperDecoration,
    required this.pageBackgroundColor,
    required this.cardColor,
    required this.softTextColor,
    required this.titleColor,
    required this.titleShadows,
  });

  static AppVisuals resolve(BuildContext context) {
    final theme = Theme.of(context);
    final appState = HabitApp.of(context);
    final useWallpaper = appState?.useWallpaper ?? false;
    final useGlassEffect = appState?.glassEffectEnabled ?? false;

    return AppVisuals(
      useWallpaper: useWallpaper,
      useGlassEffect: useGlassEffect,
      wallpaperDecoration: appState?.wallpaperDecoration,
      pageBackgroundColor:
          useWallpaper ? Colors.transparent : theme.scaffoldBackgroundColor,
      cardColor: useGlassEffect
          ? Colors.white.withValues(alpha: useWallpaper ? 0.36 : 0.76)
          : useWallpaper
              ? Colors.white.withValues(alpha: 0.92)
              : Colors.white,
      softTextColor: useWallpaper ? Colors.white70 : Colors.grey.shade500,
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
    );
  }
}
