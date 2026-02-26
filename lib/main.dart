import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'models/habit.dart';
import 'services/achievement_service.dart';
import 'services/update_service.dart';
import 'services/widget_service.dart';
import 'services/wallpaper_service.dart';
import 'app.dart';
import 'pages/check_in_page.dart';
import 'pages/statistics_page.dart';
import 'pages/profile_page.dart';
import 'widgets/update_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WidgetService.initialize();
  final prefs = await SharedPreferences.getInstance();
  final colorIndex = prefs.getInt('theme_color_index') ?? 0;
  runApp(HabitApp(initialColorIndex: colorIndex, home: const MainPage()));
}

// ========== 主页面 ==========
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  List<Habit> habits = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkUpdateSilently();
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
    final appState = HabitApp.of(context);
    final useWallpaper = appState?.useWallpaper ?? false;
    final wallpaperDecoration = appState?.wallpaperDecoration;

    return Scaffold(
      backgroundColor: useWallpaper ? Colors.transparent : null,
      body: Stack(
        children: [
          if (useWallpaper && wallpaperDecoration != null)
            Positioned.fill(
              child: Container(decoration: wallpaperDecoration),
            ),
          if (useWallpaper)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.05),
              ),
            ),
          IndexedStack(
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
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: useWallpaper
              ? Colors.white.withValues(alpha: 0.95)
              : Colors.white,
          border: Border(
            top: BorderSide(
              color: useWallpaper
                  ? Colors.grey[200]!.withValues(alpha: 0.5)
                  : Colors.grey[100]!,
              width: 1,
            ),
          ),
          boxShadow: useWallpaper
              ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ]
              : null,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: themeColor,
          unselectedItemColor: Colors.grey[400],
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline),
              activeIcon: Icon(Icons.check_circle),
              label: '打卡',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: '统计',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
}
