import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'services/wallpaper_service.dart';
import 'config/theme_config.dart';

class _NoStretchScrollBehavior extends MaterialScrollBehavior {
  const _NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class HabitApp extends StatefulWidget {
  final int initialColorIndex;
  final Widget home;
  const HabitApp({super.key, this.initialColorIndex = 0, required this.home});

  @override
  State<HabitApp> createState() => HabitAppState();

  static HabitAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<HabitAppState>();
  }
}

class HabitAppState extends State<HabitApp> {
  static const String _glassEffectKey = 'glass_effect_enabled';
  static const String _floatingNavGlassKey = 'floating_nav_glass_enabled';
  late int _currentColorIndex;

  // ===== 新增：壁纸相关状态 =====
  WallpaperData? _wallpaperData;
  bool _useWallpaper = false;
  bool _glassEffectEnabled = false;
  bool _floatingNavGlassEnabled = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _currentColorIndex = widget.initialColorIndex;
    _loadWallpaper(); // 新增：加载壁纸
  }

  // ===== 新增：加载壁纸 =====
  Future<void> _loadWallpaper() async {
    final prefs = await SharedPreferences.getInstance();
    _wallpaperData = await WallpaperService.getSavedWallpaper();
    _useWallpaper = _wallpaperData != null;
    _glassEffectEnabled = prefs.getBool(_glassEffectKey) ?? false;
    _floatingNavGlassEnabled = prefs.getBool(_floatingNavGlassKey) ?? false;
    setState(() {
      _isInitialized = true;
    });
  }

  // ===== 现有的主题相关 =====
  ThemeColorOption get currentTheme =>
      ThemeConfig.colorOptions[_currentColorIndex];

  Future<void> setThemeColor(int index) async {
    setState(() {
      _currentColorIndex = index;
      _useWallpaper = false; // 切换主题时关闭壁纸
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_color_index', index);
    await prefs.setBool('use_wallpaper', false);
  }

  // ===== 新增：壁纸相关 Getters =====
  WallpaperData? get wallpaperData => _wallpaperData;
  bool get useWallpaper => _useWallpaper && _wallpaperData != null;
  bool get glassEffectEnabled => _glassEffectEnabled;
  bool get floatingNavGlassEnabled => _floatingNavGlassEnabled;

  /// 当前使用的主题色（优先壁纸提取色）
  Color get currentColor {
    if (useWallpaper && _wallpaperData != null) {
      return _wallpaperData!.vibrantColor ?? _wallpaperData!.dominantColor;
    }
    return currentTheme.color;
  }

  /// 当前使用的背景色
  Color get currentBackgroundColor {
    if (useWallpaper && _wallpaperData != null) {
      return WallpaperService.generateBackgroundColor(
          _wallpaperData!.dominantColor);
    }
    return currentTheme.backgroundColor;
  }

  /// 壁纸背景装饰
  BoxDecoration? get wallpaperDecoration {
    if (!useWallpaper || _wallpaperData == null) return null;
    return BoxDecoration(
      image: DecorationImage(
        image: FileImage(File(_wallpaperData!.path)),
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
      ),
    );
  }

  // ===== 新增：壁纸方法 =====

  /// 设置壁纸
  Future<bool> setWallpaper(BuildContext context) async {
    try {
      final file = await WallpaperService.pickAndCropImage(context);
      if (file == null) return false;

      final data = await WallpaperService.extractColors(file.path);
      if (data == null) return false;

      setState(() {
        _wallpaperData = data;
        _useWallpaper = true;
      });
      return true;
    } catch (e) {
      debugPrint('设置壁纸失败: $e');
      return false;
    }
  }

  /// 清除壁纸
  Future<void> clearWallpaper() async {
    await WallpaperService.clearWallpaper();
    setState(() {
      _wallpaperData = null;
      _useWallpaper = false;
    });
  }

  Future<void> setGlassEffectEnabled(bool enabled) async {
    setState(() {
      _glassEffectEnabled = enabled;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_glassEffectKey, enabled);
  }

  Future<void> setFloatingNavGlassEnabled(bool enabled) async {
    setState(() {
      _floatingNavGlassEnabled = enabled;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_floatingNavGlassKey, enabled);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = currentColor;
    final bgColor = currentBackgroundColor;
    final elevatedBackgroundColor = glassEffectEnabled
        ? themeColor.withValues(alpha: useWallpaper ? 0.74 : 0.9)
        : themeColor;
    final elevatedDisabledBackgroundColor = glassEffectEnabled
        ? themeColor.withValues(alpha: useWallpaper ? 0.42 : 0.56)
        : themeColor.withValues(alpha: 0.6);
    final outlinedBackgroundColor = glassEffectEnabled
        ? Colors.white.withValues(alpha: useWallpaper ? 0.34 : 0.84)
        : Colors.grey.shade50;
    final outlinedDisabledBackgroundColor = glassEffectEnabled
        ? Colors.white.withValues(alpha: useWallpaper ? 0.18 : 0.52)
        : Colors.grey.shade100;
    final textButtonBackgroundColor = glassEffectEnabled
        ? themeColor.withValues(alpha: useWallpaper ? 0.18 : 0.1)
        : Colors.transparent;
    final bodyColor = glassEffectEnabled && useWallpaper
        ? const Color(0xFF24313C)
        : Colors.black87;
    final secondaryBodyColor = glassEffectEnabled && useWallpaper
        ? const Color(0xFF52606D)
        : Colors.grey.shade700;

    return MaterialApp(
      title: '雕刀',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _NoStretchScrollBehavior(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeColor,
          primary: themeColor,
          brightness: Brightness.light,
        ),
        textTheme: ThemeData.light()
            .textTheme
            .apply(
              bodyColor: bodyColor,
              displayColor: bodyColor,
            )
            .copyWith(
              bodySmall: ThemeData.light().textTheme.bodySmall?.copyWith(
                    color: secondaryBodyColor,
                    fontWeight: FontWeight.w500,
                  ),
              labelMedium: ThemeData.light().textTheme.labelMedium?.copyWith(
                    color: secondaryBodyColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
        // 壁纸模式下使用透明背景
        scaffoldBackgroundColor: useWallpaper ? Colors.transparent : bgColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          elevation: 0,
          scrolledUnderElevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: elevatedBackgroundColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: elevatedDisabledBackgroundColor,
            disabledForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: themeColor,
            backgroundColor: outlinedBackgroundColor,
            disabledBackgroundColor: outlinedDisabledBackgroundColor,
            disabledForegroundColor: themeColor.withValues(alpha: 0.42),
            side: const BorderSide(color: Colors.transparent),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: themeColor,
            backgroundColor: textButtonBackgroundColor,
            disabledForegroundColor: themeColor.withValues(alpha: 0.42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      home: widget.home,
    );
  }
}
