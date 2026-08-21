import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/habit.dart';
import '../models/user_level.dart';
import '../services/auth_service.dart';
import '../services/haptic_service.dart';
import '../services/supabase_service.dart';
import '../services/level_service.dart';
import '../ui/app_surfaces.dart';
import '../ui/app_tokens.dart';
import '../ui/app_visuals.dart';
import 'about_page.dart';
import 'achievement_page.dart';
import 'account_page.dart';
import 'backup_page.dart';
import 'reminder_settings_page.dart';
import 'theme_settings_page.dart';
import 'other_settings_page.dart';
import 'level_detail_page.dart';

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
    final navBarHeight = MediaQuery.of(context).padding.top + 60;

    return Scaffold(
      backgroundColor: visuals.pageBackgroundColor,
      extendBodyBehindAppBar: true,
      body: AppWallpaperBackground(
        visuals: visuals,
        child: Stack(
          children: [
            // 内容区域
            ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                navBarHeight + AppSpacing.xl,
                AppSpacing.xl,
                100,
              ),
              children: [
                // 账户卡片（包含等级信息）
                _buildAccountCardWithLevel(context, themeColor),
                const SizedBox(height: AppSpacing.xxl),

                // 菜单项
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
                  icon: Icons.tune_outlined,
                  title: '其他设置',
                  page: const OtherSettingsPage(),
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

            // 标题栏
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppPageTitleBar(
                title: '我的',
                visuals: visuals,
                left: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 账户卡片（整合等级信息）
  Widget _buildAccountCardWithLevel(BuildContext context, Color themeColor) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      initialData: AuthService.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isConfigured = SupabaseService.isConfigured;
        final hasInitError = SupabaseService.hasInitializationError;

        final title = !isConfigured
            ? '账户'
            : hasInitError
                ? '账户'
                : user == null
                    ? '未登录'
                    : _displayNameOf(user);

        final subtitle = !isConfigured
            ? '当前暂时无法使用账户功能'
            : hasInitError
                ? '账户功能正在调整，请稍后再试'
                : user == null
                    ? '开启新世界'
                    : user.email ?? '已登录';

        return InkWell(
          onTap: () {
            HapticService.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const AccountPage()),
            );
          },
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: AppGlassCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                // 第一行：账户信息
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        user == null
                            ? Icons.person_outline
                            : Icons.verified_user_outlined,
                        color: themeColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey[300], size: 20),
                  ],
                ),

                // 分隔线
                const SizedBox(height: AppSpacing.lg),
                Divider(height: 1, color: Colors.grey[200]),
                const SizedBox(height: AppSpacing.lg),

                // 第二行：等级信息
                FutureBuilder<UserLevel>(
                  future: LevelService.getCurrentLevel(),
                  builder: (context, levelSnapshot) {
                    if (!levelSnapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final level = levelSnapshot.data!;

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LevelDetailPage(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            // 等级图标
                            Text(
                              level.icon,
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(width: 12),

                            // 等级信息
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        level.title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: themeColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Lv.${level.currentLevel}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // 经验进度条
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${level.currentExp} / ${level.expToNextLevel}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            '${(level.levelProgress * 100).toStringAsFixed(0)}%',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: themeColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: level.levelProgress,
                                          minHeight: 6,
                                          backgroundColor: Colors.grey[200],
                                          valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),
                            Icon(Icons.chevron_right, color: Colors.grey[300], size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _displayNameOf(User user) {
    final value = user.userMetadata?['display_name'];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return user.email?.split('@').first ?? '已登录用户';
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
        onTap: () {
          HapticService.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => page),
          );
        },
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: AppGlassCard(
          radius: AppRadii.md,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: 14),
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
