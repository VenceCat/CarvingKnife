import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'models/habit.dart';
import 'services/achievement_service.dart';
import 'services/update_service.dart';
import 'services/widget_service.dart';
import 'app.dart';
import 'pages/check_in_page.dart';
import 'pages/statistics_page.dart';
import 'pages/profile_page.dart';
import 'ui/app_surfaces.dart';
import 'ui/app_visuals.dart';
import 'widgets/update_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WidgetService.initialize();
  final prefs = await SharedPreferences.getInstance();
  final colorIndex = prefs.getInt('theme_color_index') ?? 0;
  runApp(HabitApp(initialColorIndex: colorIndex, home: const MainPage()));
}


class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  List<Habit> habits = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _checkUpdateSilently();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reloadFromDisk();
    }
  }

  Future<void> _reloadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final String? data = prefs.getString('simple_habits');
    if (data != null && mounted) {
      setState(() => habits =
          (jsonDecode(data) as List).map((e) => Habit.fromJson(e)).toList());
    }
  }

  Future<void> _checkUpdateSilently() async {
    // 等界面渲染完成后再检测，避免 context 未就绪
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    try {
      final result = await UpdateService.checkUpdate();
      if (!mounted) return;
      if (result.hasUpdate && result.updateInfo != null) {
        await UpdateDialog.show(
          context,
          updateInfo: result.updateInfo!,
          currentVersion: result.currentVersion ?? '',
        );
      }
    } catch (_) {
      // 静默失败，不打扰用户
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('simple_habits');
    if (data != null) {
      setState(() => habits =
          (jsonDecode(data) as List).map((e) => Habit.fromJson(e)).toList());
      await WidgetService.updateWidget(habits);
      await AchievementService.initializeIfNeeded(habits);
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('simple_habits', jsonEncode(habits));
    await WidgetService.updateWidget(habits);
  }

  void _addHabit(Habit habit) {
    setState(() => habits.add(habit));
    _saveData();
  }

  void _removeHabit(Habit habit) {
    setState(() => habits.remove(habit));
    _saveData();
  }

  void _refreshAndSave() {
    setState(() {});
    _saveData();
  }

  void _restoreHabits(List<Habit> newHabits) {
    setState(() => habits = newHabits);
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final visuals = AppVisuals.resolve(context);

    return Scaffold(
      backgroundColor: visuals.pageBackgroundColor,
      extendBody: true,
      body: AppWallpaperBackground(
        visuals: visuals,
        overlayOpacity: 0.05,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            CheckInPage(
              habits: habits,
              onSave: _refreshAndSave,
              onAdd: _addHabit,
              onDelete: _removeHabit,
            ),
            StatisticsPage(habits: habits),
            ProfilePage(
              habits: habits,
              onSave: _refreshAndSave,
              onRestore: _restoreHabits,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: visuals.useGlassEffect
                    ? ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10)
                    : ui.ImageFilter.blur(sigmaX: 0.01, sigmaY: 0.01),
              child: Container(
                decoration: AppSurfaceDecoration.bottomBar(context).copyWith(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: visuals.useWallpaper
                        ? Colors.white.withValues(alpha: 0.45)
                        : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: NavigationBarTheme(
                  data: NavigationBarThemeData(
                    backgroundColor: Colors.transparent,
                    indicatorColor: themeColor.withValues(
                      alpha: visuals.useWallpaper ? 0.24 : 0.14,
                    ),
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    height: 64,
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      final isSelected = states.contains(WidgetState.selected);
                      return TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? themeColor : Colors.grey[600],
                      );
                    }),
                  ),
                  child: NavigationBar(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (index) =>
                        setState(() => _currentIndex = index),
                    backgroundColor: Colors.transparent,
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.check_circle_outline),
                        selectedIcon: Icon(Icons.check_circle),
                        label: '\u6253\u5361',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.bar_chart_outlined),
                        selectedIcon: Icon(Icons.bar_chart),
                        label: '\u7edf\u8ba1',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: '\u6211\u7684',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
