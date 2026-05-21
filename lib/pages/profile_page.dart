import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/habit.dart';
import '../services/auth_service.dart';
import '../services/haptic_service.dart';
import '../services/supabase_service.dart';
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
    final topInset = AppPageTitleBar.contentTopInset(context, visuals);

    final totalCheckIns = habits.fold(0, (sum, h) => sum + h.checkInTimes.length);
    final todayCheckIns = habits.where((h) => h.isTodayCompleted).length;

    return Scaffold(
      backgroundColor: visuals.pageBackgroundColor,
      extendBodyBehindAppBar: true,
      body: AppWallpaperBackground(
        visuals: visuals,
        child: Stack(
          children: [
            Positioned.fill(
              top: topInset,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        children: [
                          _buildAccountCard(context, themeColor),
                          const SizedBox(height: AppSpacing.lg),
                          AppGlassCard(
                            padding: const EdgeInsets.all(AppSpacing.xxl),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _statItem('\u4e60\u60ef\u6570', habits.length.toString(), themeColor),
                                Container(width: 1, height: 40, color: Colors.grey[200]),
                                _statItem('\u4eca\u65e5\u5b8c\u6210', todayCheckIns.toString(), themeColor),
                                Container(width: 1, height: 40, color: Colors.grey[200]),
                                _statItem('\u7d2f\u8ba1\u6253\u5361', totalCheckIns.toString(), themeColor),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          _menuItem(
                            context,
                            icon: Icons.emoji_events_outlined,
                            title: '\u6253\u5361\u6210\u5c31',
                            page: AchievementPage(habits: habits),
                            themeColor: themeColor,
                          ),
                          _menuItem(
                            context,
                            icon: Icons.notifications_none,
                            title: '\u63d0\u9192\u8bbe\u7f6e',
                            page: ReminderSettingsPage(habits: habits, onSave: onSave),
                            themeColor: themeColor,
                          ),
                          _menuItem(
                            context,
                            icon: Icons.color_lens_outlined,
                            title: '\u4e3b\u9898\u8bbe\u7f6e',
                            page: const ThemeSettingsPage(),
                            themeColor: themeColor,
                          ),
                          _menuItem(
                            context,
                            icon: Icons.tune_outlined,
                            title: '\u5176\u4ed6\u8bbe\u7f6e',
                            page: const OtherSettingsPage(),
                            themeColor: themeColor,
                          ),
                          _menuItem(
                            context,
                            icon: Icons.cloud_outlined,
                            title: '\u6570\u636e\u5907\u4efd',
                            page: BackupPage(habits: habits, onRestore: onRestore),
                            themeColor: themeColor,
                          ),
                          _menuItem(
                            context,
                            icon: Icons.info_outline,
                            title: '\u5173\u4e8e',
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
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppPageTitleBar(
                title: '\u6211\u7684',
                visuals: visuals,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, Color themeColor) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      initialData: AuthService.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isConfigured = SupabaseService.isConfigured;
        final hasInitError = SupabaseService.hasInitializationError;
        final title = !isConfigured
            ? '\u8d26\u6237'
            : hasInitError
                ? '\u8d26\u6237'
            : user == null
                ? '\u672a\u767b\u5f55'
                : _displayNameOf(user);
        final subtitle = !isConfigured
            ? '\u5f53\u524d\u6682\u65f6\u65e0\u6cd5\u4f7f\u7528\u8d26\u6237\u529f\u80fd'
            : hasInitError
                ? '\u8d26\u6237\u529f\u80fd\u6b63\u5728\u8c03\u6574\uff0c\u8bf7\u7a0d\u540e\u518d\u8bd5'
            : user == null
                ? '\u5f00\u542f\u65b0\u4e16\u754c'
                : user.email ?? '\u5df2\u767b\u5f55';
        final badge = !isConfigured
            ? '\u6682\u4e0d\u53ef\u7528'
            : hasInitError
                ? '\u7a0d\u540e\u518d\u8bd5'
            : user == null
                ? '\u53bb\u767b\u5f55'
                : user.emailConfirmedAt == null
                    ? '\u5f85\u9a8c\u8bc1'
                    : '\u5df2\u767b\u5f55';

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
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    user == null ? Icons.person_outline : Icons.verified_user_outlined,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: themeColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Icon(Icons.chevron_right, color: Colors.grey[300], size: 20),
                  ],
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
    return user.email?.split('@').first ?? '\u5df2\u767b\u5f55\u7528\u6237';
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
