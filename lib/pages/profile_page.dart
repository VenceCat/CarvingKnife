import 'package:flutter/material.dart';
import '../models/habit.dart';
import 'backup_page.dart';
import 'theme_settings_page.dart';
import 'reminder_settings_page.dart';
import 'about_page.dart';
import 'achievement_page.dart';
import '../ui/app_surfaces.dart';
import '../ui/app_tokens.dart';
import '../ui/app_visuals.dart';

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

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final visuals = AppVisuals.resolve(context);

    final totalCheckIns = habits.fold(0, (sum, h) => sum + h.checkInTimes.length);
    final todayCheckIns = habits.where((h) => h.isTodayCompleted).length;

    return Scaffold(
      backgroundColor: visuals.pageBackgroundColor,
      extendBodyBehindAppBar: true,
      body: AppWallpaperBackground(
        visuals: visuals,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppPageTitleBar(
                title: '我的',
                visuals: visuals,
              ),
            ),
            Positioned.fill(
              top: MediaQuery.of(context).padding.top + 60,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        children: [
                          AppGlassCard(
                            padding: const EdgeInsets.all(AppSpacing.xxl),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _statItem('习惯数', habits.length.toString(), themeColor),
                                Container(width: 1, height: 40, color: Colors.grey[200]),
                                _statItem('今日完成', todayCheckIns.toString(), themeColor),
                                Container(width: 1, height: 40, color: Colors.grey[200]),
                                _statItem('累计打卡', totalCheckIns.toString(), themeColor),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          _menuItem(
                            context,
                            icon: Icons.emoji_events_outlined,
                            title: '打卡成就',
                            page: AchievementPage(habits: habits),
                            themeColor: themeColor,
                          ),
                          _menuItem(
                            context,
                            icon: Icons.notifications_none,
                            title: '提醒设置',
                            page: ReminderSettingsPage(habits: habits, onSave: onSave),
                            themeColor: themeColor,
                          ),
                          _menuItem(
                            context,
                            icon: Icons.color_lens_outlined,
                            title: '主题设置',
                            page: const ThemeSettingsPage(),
                            themeColor: themeColor,
                          ),
                          _menuItem(
                            context,
                            icon: Icons.cloud_outlined,
                            title: '数据备份',
                            page: BackupPage(habits: habits, onRestore: onRestore),
                            themeColor: themeColor,
                          ),
                          _menuItem(
                            context,
                            icon: Icons.info_outline,
                            title: '关于',
                            page: const AboutPage(),
                            themeColor: themeColor,
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
            fontWeight: FontWeight.w400,
            color: color,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget page,
    required Color themeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => page),
        ),
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: AppGlassCard(
          radius: AppRadii.md,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: themeColor, size: 22),
              const SizedBox(width: AppSpacing.lg),
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
