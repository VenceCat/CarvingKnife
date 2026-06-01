import 'package:flutter/material.dart';
import 'services/haptic_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'models/habit.dart';
import 'services/achievement_service.dart';
import 'services/auth_flow_service.dart';
import 'services/supabase_service.dart';
import 'services/update_service.dart';
import 'services/widget_service.dart';
import 'app.dart';
import 'pages/check_in_page.dart';
import 'pages/atomic_habit_page.dart';
import 'pages/reset_password_page.dart';
import 'pages/statistics_page.dart';
import 'pages/profile_page.dart';
import 'ui/app_surfaces.dart';
import 'ui/app_visuals.dart';
import 'widgets/update_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HapticService.init();
  await WidgetService.initialize();
  await SupabaseService.initialize();
  AuthFlowService.initialize();
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
  final CheckInPageController _checkInPageController = CheckInPageController();
  bool _isShowingResetPasswordPage = false;
  bool _isShowingAuthNotice = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AuthFlowService.passwordRecoveryPending
        .addListener(_handlePasswordRecoveryPending);
    AuthFlowService.notice.addListener(_handleAuthNotice);
    _loadData();
    _checkUpdateSilently();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePasswordRecoveryPending();
      _handleAuthNotice();
    });
  }

  @override
  void dispose() {
    AuthFlowService.passwordRecoveryPending
        .removeListener(_handlePasswordRecoveryPending);
    AuthFlowService.notice.removeListener(_handleAuthNotice);
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

  void _handlePasswordRecoveryPending() {
    if (!mounted ||
        _isShowingResetPasswordPage ||
        !AuthFlowService.passwordRecoveryPending.value) {
      return;
    }
    _openResetPasswordPage();
  }

  Future<void> _openResetPasswordPage() async {
    _isShowingResetPasswordPage = true;

    final result = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
    );

    AuthFlowService.clearPasswordRecovery();
    _isShowingResetPasswordPage = false;

    if (result == true && mounted) {
      _showAuthResultSheet(
        title: '\u5bc6\u7801\u5df2\u91cd\u7f6e',
        description: '\u8bf7\u4f7f\u7528\u65b0\u5bc6\u7801\u91cd\u65b0\u767b\u5f55\u3002',
        color: Colors.green,
        icon: Icons.check_circle,
      );
    }
  }

  void _handleAuthNotice() {
    if (!mounted || _isShowingAuthNotice) return;

    final notice = AuthFlowService.notice.value;
    if (notice == null) return;

    switch (notice) {
      case AuthFlowNotice.emailConfirmed:
        _showAuthResultSheet(
          title: '\u90ae\u7bb1\u9a8c\u8bc1\u6210\u529f',
          description: '\u8d26\u6237\u5df2\u5b8c\u6210\u9a8c\u8bc1\uff0c\u8bf7\u624b\u52a8\u767b\u5f55\u3002',
          color: Colors.green,
          icon: Icons.mark_email_read,
        );
        break;
    }
  }

  Future<void> _showAuthResultSheet({
    required String title,
    required String description,
    required Color color,
    required IconData icon,
  }) async {
    _isShowingAuthNotice = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AppBottomSheetSurface(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      '\u6211\u77e5\u9053\u4e86',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    AuthFlowService.clearNotice();
    _isShowingAuthNotice = false;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final visuals = AppVisuals.resolve(context);
    final bottomSafeInset = MediaQuery.of(context).padding.bottom;
    const navBarHeight = 64.0;
    const navOuterBottomPadding = 12.0;
    const fabGapAboveNav = 10.0;
    final navOverlayHeight = bottomSafeInset + navBarHeight + navOuterBottomPadding;
    final fabBottomOffset = navOverlayHeight + fabGapAboveNav;

    return Scaffold(
      backgroundColor: visuals.pageBackgroundColor,
      extendBody: true,
      body: AppWallpaperBackground(
        visuals: visuals,
        overlayOpacity: 0.05,
        child: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: [
                CheckInPage(
                  habits: habits,
                  onSave: _refreshAndSave,
                  onAdd: _addHabit,
                  onDelete: _removeHabit,
                  floatingButtonBottomOffset: fabBottomOffset,
                  controller: _checkInPageController,
                ),
                AtomicHabitPage(bottomPadding: navOverlayHeight + 18),
                StatisticsPage(habits: habits),
                ProfilePage(
                  habits: habits,
                  onSave: _refreshAndSave,
                  onRestore: _restoreHabits,
                ),
              ],
            ),
            if (_currentIndex == 0)
              Positioned(
                right: 22,
                bottom: fabBottomOffset,
                child: AppFloatingAddButton(
                  onTap: _checkInPageController.openAddHabitDialog,
                  themeColor: themeColor,
                  useWallpaper: visuals.useWallpaper,
                  useGlassEffect: visuals.useGlassEffect,
                ),
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
                    onDestinationSelected: (index) {
                      if (index != _currentIndex) {
                        HapticService.navigationDoublePulse();
                      }
                      setState(() => _currentIndex = index);
                    },
                    backgroundColor: Colors.transparent,
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.check_circle_outline),
                        selectedIcon: Icon(Icons.check_circle),
                        label: '\u6253\u5361',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.route_outlined),
                        selectedIcon: Icon(Icons.auto_awesome_motion),
                        label: '\u539f\u5b50',
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
