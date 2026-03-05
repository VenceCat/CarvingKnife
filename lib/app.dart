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
  late int _currentColorIndex;

  // ===== 新增：壁纸相关状态 =====
  WallpaperData? _wallpaperData;
  bool _useWallpaper = false;
  bool _glassEffectEnabled = false;
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

  @override
  Widget build(BuildContext context) {
    final themeColor = currentColor;
    final bgColor = currentBackgroundColor;

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
        // 壁纸模式下使用透明背景
        scaffoldBackgroundColor: useWallpaper ? Colors.transparent : bgColor,
        appBarTheme: AppBarTheme(
          // 壁纸模式下 AppBar 半透明
          backgroundColor: useWallpaper
              ? Colors.white.withValues(alpha: 0.9)
              : bgColor,
          foregroundColor: Colors.black87,
          elevation: useWallpaper ? 0.5 : 0,
        ),
      ),
      home: widget.home,
    );
  }
}
