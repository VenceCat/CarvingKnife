import 'package:flutter/material.dart';
import '../models/habit.dart';
import 'backup_page.dart';
import 'theme_settings_page.dart';
import 'reminder_settings_page.dart';
import 'about_page.dart';
import 'achievement_page.dart';
import '../app.dart';

class ProfilePage extends StatelessWidget {
  final List<Habit> habits;
  final VoidCallback onSave;
  final Function(List<Habit>) onRestore;

  const ProfilePage({
    super.key,
    required this.habits,
    required this.onSave,
    required this.onRestore,
  });

  /// 统一的卡片装饰样式
  BoxDecoration _cardDecoration({
    required bool useWallpaper,
    Color? borderColor,
    double radius = 15,
  }) {
    return BoxDecoration(
      color: useWallpaper
          ? Colors.white.withValues(alpha: 0.95)
          : Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: borderColor != null ? Border.all(color: borderColor) : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: useWallpaper ? 0.08 : 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    // 获取壁纸状态
    final appState = HabitApp.of(context);
    final useWallpaper = appState?.useWallpaper ?? false;
    final wallpaperDecoration = appState?.wallpaperDecoration;

    int totalCheckIns = habits.fold(0, (sum, h) => sum + h.checkInTimes.length);
    int todayCheckIns = habits.where((h) => h.isTodayCompleted).length;

    return Scaffold(
      backgroundColor: useWallpaper ? Colors.transparent : backgroundColor,
      extendBodyBehindAppBar: true,

      body: Stack(
        children: [
          // 壁纸背景
          if (useWallpaper && wallpaperDecoration != null)
            Positioned.fill(child: Container(decoration: wallpaperDecoration)),

          // 遮罩层
          if (useWallpaper)
            Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.03))),

          // ===== 固定标题栏（居左对齐） =====
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                bottom: 16,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                gradient: useWallpaper
                    ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                )
                    : null,
                color: useWallpaper ? Colors.transparent : backgroundColor,
              ),
              child: Row(
                children: [
                  Text(
                    "我的",
                    style: TextStyle(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w300,
                      fontSize: 24,
                      color: useWallpaper ? Colors.white : null,
                      shadows: useWallpaper
                          ? [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                      ]
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== 内容层 =====
          Positioned.fill(
            top: MediaQuery.of(context).padding.top + 60,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // 统计卡片
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: _cardDecoration(useWallpaper: useWallpaper),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _statItem("习惯数", habits.length.toString(), themeColor),
                              Container(width: 1, height: 40, color: Colors.grey[200]),
                              _statItem("今日完成", todayCheckIns.toString(), themeColor),
                              Container(width: 1, height: 40, color: Colors.grey[200]),
                              _statItem("累计打卡", totalCheckIns.toString(), themeColor),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // 菜单项
                        _menuItem(
                          context,
                          Icons.emoji_events_outlined,
                          "打卡成就",
                          AchievementPage(habits: habits),
                          useWallpaper,
                          themeColor,
                        ),
                        _menuItem(
                          context,
                          Icons.notifications_none,
                          "提醒设置",
                          ReminderSettingsPage(habits: habits, onSave: onSave),
                          useWallpaper,
                          themeColor,
                        ),
                        _menuItem(
                          context,
                          Icons.color_lens_outlined,
                          "主题设置",
                          const ThemeSettingsPage(),
                          useWallpaper,
                          themeColor,
                        ),
                        _menuItem(
                          context,
                          Icons.cloud_outlined,
                          "数据备份",
                          BackupPage(habits: habits, onRestore: onRestore),
                          useWallpaper,
                          themeColor,
                        ),
                        _menuItem(
                          context,
                          Icons.info_outline,
                          "关于",
                          const AboutPage(),
                          useWallpaper,
                          themeColor,
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w300,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
        ),
      ],
    );
  }

  Widget _menuItem(
      BuildContext context,
      IconData icon,
      String title,
      Widget? page,
      bool useWallpaper,
      Color themeColor,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          if (page != null) {
            Navigator.push(context, MaterialPageRoute(builder: (c) => page));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("$title 功能开发中..."),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: _cardDecoration(
            useWallpaper: useWallpaper,
            radius: 12,
          ),
          child: Row(
            children: [
              Icon(icon, color: themeColor, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 15)),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[300], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
