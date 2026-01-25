import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:math';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'models/achievement.dart';
import 'services/achievement_service.dart';
import 'widgets/achievement_dialog.dart';
import 'models/habit.dart';
import 'services/widget_service.dart';
import 'services/habit_icons.dart';
import 'services/update_service.dart';
import 'widgets/update_dialog.dart';
import 'services/wallpaper_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await WidgetService.initialize();

  final prefs = await SharedPreferences.getInstance();
  final colorIndex = prefs.getInt('theme_color_index') ?? 0;
  runApp(HabitApp(initialColorIndex: colorIndex));
}

// 主题颜色配置
class ThemeConfig {
  static const List<ThemeColorOption> colorOptions = [
    ThemeColorOption(
      name: '默认灰',
      color: Color(0xFF78909C),
      backgroundColor: Color(0xFFFAFAFA),
    ),
    ThemeColorOption(
      name: '清新绿',
      color: Color(0xFF26A69A),
      backgroundColor: Color(0xFFF5FAF8),
    ),
    ThemeColorOption(
      name: '天空蓝',
      color: Color(0xFF42A5F5),
      backgroundColor: Color(0xFFF5F9FC),
    ),
    ThemeColorOption(
      name: '活力橙',
      color: Color(0xFFFF9800),
      backgroundColor: Color(0xFFFFFBF5),
    ),
    ThemeColorOption(
      name: '优雅紫',
      color: Color(0xFFAB47BC),
      backgroundColor: Color(0xFFFAF5FC),
    ),
    ThemeColorOption(
      name: '玫瑰粉',
      color: Color(0xFFEC407A),
      backgroundColor: Color(0xFFFCF5F7),
    ),
    ThemeColorOption(
      name: '薄荷青',
      color: Color(0xFF26C6DA),
      backgroundColor: Color(0xFFF5FBFC),
    ),
    ThemeColorOption(
      name: '新年红',
      color: Color(0xFFE53935),
      backgroundColor: Color(0xFFFFF8F7),
    ),
    ThemeColorOption(
      name: '沉稳黑',
      color: Color(0xFF455A64),
      backgroundColor: Color(0xFFF5F5F5),
    ),
  ];
}

// 分类图标选择器组件
class IconSelector extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onSelect;
  final Color themeColor;

  const IconSelector({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.themeColor,
  });

  @override
  State<IconSelector> createState() => _IconSelectorState();
}

class _IconSelectorState extends State<IconSelector> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late IconData _selectedIcon;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: HabitIcons.categories.length,
      vsync: this,
    );
    _selectedIcon = HabitIcons.getIcon(widget.selectedIndex);

    // 定位到选中图标所在的分类
    _scrollToSelectedCategory();
  }

  void _scrollToSelectedCategory() {
    for (int i = 0; i < HabitIcons.categories.length; i++) {
      if (HabitIcons.categories[i].icons.contains(_selectedIcon)) {
        _tabController.animateTo(i);
        break;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 165,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 分类标签栏
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: widget.themeColor,
              unselectedLabelColor: Colors.grey[500],
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
              indicatorColor: widget.themeColor,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              tabs: HabitIcons.categories.map((category) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(category.icon, size: 16),
                      const SizedBox(width: 4),
                      Text(category.name),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          // 图标网格
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: HabitIcons.categories.map((category) {
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: category.icons.length,
                  itemBuilder: (context, index) {
                    final icon = category.icons[index];
                    final isSelected = icon == _selectedIcon;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedIcon = icon);
                        final globalIndex = HabitIcons.getIconIndex(icon);
                        widget.onSelect(globalIndex);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? widget.themeColor.withValues(alpha: 0.15)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          // 移除了未选中状态的边框
                          border: isSelected
                              ? Border.all(color: widget.themeColor, width: 2)
                              : null,
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color: widget.themeColor.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                              : null,
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? widget.themeColor : Colors.grey[600],
                          size: 22,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class ThemeColorOption {
  final String name;
  final Color color;
  final Color backgroundColor;

  const ThemeColorOption({
    required this.name,
    required this.color,
    required this.backgroundColor,
  });
}

class HabitApp extends StatefulWidget {
  final int initialColorIndex;
  const HabitApp({super.key, this.initialColorIndex = 0});

  @override
  State<HabitApp> createState() => HabitAppState();

  static HabitAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<HabitAppState>();
  }
}

class HabitAppState extends State<HabitApp> {
  late int _currentColorIndex;

  // ===== 新增：壁纸相关状态 =====
  WallpaperData? _wallpaperData;
  bool _useWallpaper = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _currentColorIndex = widget.initialColorIndex;
    _loadWallpaper(); // 新增：加载壁纸
  }

  // ===== 新增：加载壁纸 =====
  Future<void> _loadWallpaper() async {
    _wallpaperData = await WallpaperService.getSavedWallpaper();
    _useWallpaper = _wallpaperData != null;
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

  @override
  Widget build(BuildContext context) {
    final themeColor = currentColor;
    final bgColor = currentBackgroundColor;

    return MaterialApp(
      title: '雕刀',
      debugShowCheckedModeBanner: false,
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
      home: const MainPage(),
    );
  }
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
      // 关键：壁纸模式下背景透明
      backgroundColor: useWallpaper ? Colors.transparent : null,

      // 使用 Stack 实现壁纸背景
      body: Stack(
        children: [
          // ===== 壁纸背景层 =====
          if (useWallpaper && wallpaperDecoration != null)
            Positioned.fill(
              child: Container(
                decoration: wallpaperDecoration,
              ),
            ),

          // ===== 半透明遮罩层（可选，让内容更易读） =====
          if (useWallpaper)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.05),
              ),
            ),

          // ===== 内容层 =====
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

      // ===== 底部导航栏（适配壁纸模式） =====
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          // 壁纸模式下使用半透明白色
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
          // 壁纸模式下添加阴影
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

// ========== 打卡页面 ==========
class CheckInPage extends StatefulWidget {
  final List<Habit> habits;
  final VoidCallback onSave;
  final Function(Habit) onAdd;
  final Function(Habit) onDelete;

  const CheckInPage({
    super.key,
    required this.habits,
    required this.onSave,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  final List<String> quotes = [
    "静以修身，俭以养德。",
    "日拱一卒，功不唐捐。",
    "千里之行，始于足下。",
    "锲而不舍，金石可镂。",
    "今日宜休",
    "天道酬勤，力耕不欺。",
    "今日事，今日毕。",
    "宝剑锋从磨砺出。",
    "慢慢来，比较快。",
    "自律即自由。",
    "每次坚持都算数。",
    "活在当下。",
    "不忘初心，方得始终。",
    "事已至此，先玩会吧",
  ];

  late String currentQuote;

  /// ===== 统一的SnackBar显示方法 =====
  void _showSnackBar(
      BuildContext context, {
        required IconData icon,
        required String message,
        required Color backgroundColor,
        Duration duration = const Duration(seconds: 2),
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: duration,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    currentQuote = quotes[Random().nextInt(quotes.length)];
  }

  void _toggleCheckIn(Habit habit) {
    final now = DateTime.now();

    // 获取今日打卡次数
    final todayCount = habit.todayCheckInCount;

    // 如果已完成所有目标，询问是否取消打卡
    if (todayCount >= habit.dailyTarget) {
      _showCancelCheckInDialog(habit);
    } else {
      // 还可以继续打卡，添加记录并弹出备注对话框
      final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      final record = CheckInRecord(time: timeStr);
      habit.checkInRecords.add(record);
      widget.onSave();

      // 始终弹出备注对话框
      _showCheckInNoteDialog(habit, record);
    }
  }

  /// 打卡成功后的备注对话框
  void _showCheckInNoteDialog(Habit habit, CheckInRecord record) {
    final noteController = TextEditingController();
    final themeColor = Theme.of(context).colorScheme.primary;
    final todayCount = habit.todayCheckInCount;
    final isCompleted = todayCount >= habit.dailyTarget;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
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
                      color: isCompleted
                          ? Colors.green.withValues(alpha: 0.1)
                          : themeColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted ? Icons.celebration : Icons.check_circle,
                      color: isCompleted ? Colors.green : themeColor,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isCompleted ? "太棒了！目标完成 🎉" : "打卡成功！",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    habit.dailyTarget > 1
                        ? "「${habit.title}」 $todayCount/${habit.dailyTarget} 次"
                        : "「${habit.title}」已完成",
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                  // 多次打卡进度条
                  if (habit.dailyTarget > 1) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: todayCount / habit.dailyTarget,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted ? Colors.green : themeColor,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    maxLength: 100,
                    decoration: InputDecoration(
                      hintText: "写点什么记录一下吧...",
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeColor, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      counterStyle: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (noteController.text.trim().isNotEmpty) {
                          record.note = noteController.text.trim();
                          widget.onSave();
                        }
                        Navigator.pop(ctx);
                        await WidgetService.updateWidget(widget.habits);
                        await _checkAndShowAchievements();
                      },
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text("完成", style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCompleted ? Colors.green : themeColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCancelCheckInDialog(Habit habit) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    // 获取今日所有打卡记录
    final todayRecords = habit.checkInRecords
        .where((r) => r.time.startsWith(todayStr))
        .toList();

    if (todayRecords.isEmpty) return;

    // 获取最后一次打卡记录
    final lastRecord = todayRecords.last;
    final checkInTime = DateTime.parse(lastRecord.time);
    final timeStr = DateFormat('HH:mm').format(checkInTime);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
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
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.undo, color: Colors.orange, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "取消打卡",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            habit.dailyTarget > 1
                                ? "取消最后一次打卡？"
                                : "确定要取消今日的打卡吗？",
                            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 18, color: Colors.grey[500]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: themeColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          HabitIcons.getIcon(habit.iconIndex),
                          color: themeColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.title,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 14, color: Colors.grey[400]),
                                const SizedBox(width: 4),
                                Text(
                                  "今日 $timeStr 打卡",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey[500]),
                                ),
                                if (habit.dailyTarget > 1) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: themeColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "${todayRecords.length}/${habit.dailyTarget}次",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: themeColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (lastRecord.note != null && lastRecord.note!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.format_quote, size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lastRecord.note!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.orange[700]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          habit.dailyTarget > 1
                              ? "将取消最后一次打卡记录"
                              : "取消后今日的打卡记录和备注将被删除",
                          style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("保留打卡", style: TextStyle(fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await AchievementService.recordCancelledCheckIn();

                          setState(() {
                            // 移除最后一条今日打卡记录
                            final index = habit.checkInRecords.indexOf(lastRecord);
                            if (index != -1) {
                              habit.checkInRecords.removeAt(index);
                            }
                          });
                          widget.onSave();
                          Navigator.pop(ctx);
                          await WidgetService.updateWidget(widget.habits);

                          _showSnackBar(
                            context,
                            icon: Icons.undo,
                            message: "已取消「${habit.title}」的打卡",
                            backgroundColor: Colors.orange,
                          );

                          await _checkAndShowAchievements();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text("取消打卡", style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkAndShowAchievements() async {
    final newAchievements =
    await AchievementService.checkNewAchievements(widget.habits);

    if (newAchievements.isNotEmpty && mounted) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        await AchievementUnlockDialog.showMultiple(context, newAchievements);
      }
    }
  }

  void _showEncouragementDialog(Habit habit, CheckInRecord record) {
    final noteController = TextEditingController();
    final themeColor = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
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
                      color: themeColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.celebration, color: themeColor, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "打卡成功！",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "「${habit.title}」已完成",
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    maxLength: 100,
                    decoration: InputDecoration(
                      hintText: "写点什么记录一下吧...",
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeColor, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      counterStyle: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (noteController.text.trim().isNotEmpty) {
                          record.note = noteController.text.trim();
                          widget.onSave();
                        }
                        Navigator.pop(ctx);
                        await _checkAndShowAchievements();
                      },
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text("完成", style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final themeColor = Theme.of(context).colorScheme.primary;
    String? errorText;
    int selectedIconIndex = 0;
    int dailyTarget = 1; // 新增：每日目标次数

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
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
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(HabitIcons.getIcon(selectedIconIndex),
                                color: themeColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "新计划",
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "开启一个新习惯",
                                  style:
                                  TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close,
                                  size: 18, color: Colors.grey[500]),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "选择图标",
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 10),
                      IconSelector(
                        selectedIndex: selectedIconIndex,
                        themeColor: themeColor,
                        onSelect: (index) {
                          setModalState(() => selectedIconIndex = index);
                        },
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: titleController,
                        onChanged: (value) {
                          if (errorText != null && value.trim().isNotEmpty) {
                            errorText = null;
                            setModalState(() {});
                          }
                        },
                        decoration: InputDecoration(
                          labelText: "习惯名称",
                          hintText: "例如：喝水",
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                            BorderSide(color: themeColor, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                            BorderSide(color: Colors.red[300]!, width: 1.5),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                            BorderSide(color: Colors.red[300]!, width: 1.5),
                          ),
                          errorText: errorText,
                          errorStyle: TextStyle(color: Colors.red[400]),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descController,
                        maxLines: 2,
                        maxLength: 100,
                        decoration: InputDecoration(
                          labelText: "描述（选填）",
                          hintText: "例如：每天喝8杯水",
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                            BorderSide(color: themeColor, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                          counterStyle: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ===== 新增：每日目标次数选择器 =====
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.repeat, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "每日目标",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "每天需要完成的次数",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 减少按钮
                            GestureDetector(
                              onTap: () {
                                if (dailyTarget > 1) {
                                  setModalState(() => dailyTarget--);
                                }
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: dailyTarget > 1
                                      ? themeColor.withValues(alpha: 0.1)
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.remove,
                                  size: 20,
                                  color: dailyTarget > 1
                                      ? themeColor
                                      : Colors.grey[400],
                                ),
                              ),
                            ),
                            // 次数显示
                            Container(
                              width: 50,
                              alignment: Alignment.center,
                              child: Text(
                                '$dailyTarget',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: themeColor,
                                ),
                              ),
                            ),
                            // 增加按钮
                            GestureDetector(
                              onTap: () {
                                if (dailyTarget < 99) {
                                  setModalState(() => dailyTarget++);
                                }
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: themeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 20,
                                  color: themeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (titleController.text.trim().isEmpty) {
                              errorText = "习惯名称不能为空";
                              setModalState(() {});
                            } else {
                              final habitTitle = titleController.text.trim();
                              widget.onAdd(Habit(
                                id: DateTime.now().toString(),
                                title: habitTitle,
                                description: descController.text.trim(),
                                iconIndex: selectedIconIndex,
                                dailyTarget: dailyTarget, // 新增
                              ));
                              Navigator.pop(ctx);
                              await WidgetService.updateWidget(widget.habits);

                              _showSnackBar(
                                context,
                                icon: Icons.check_circle,
                                message: "已添加「$habitTitle」",
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 1),
                              );

                              await _checkAndShowAchievements();
                            }
                          },
                          icon: const Icon(Icons.check, size: 20),
                          label:
                          const Text("创建习惯", style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _deleteHabit(Habit habit) {
    final themeColor = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
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
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.delete_outline,
                          color: Colors.red[400], size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "删除习惯",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "确定要删除这个习惯吗？",
                            style:
                            TextStyle(fontSize: 13, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child:
                        Icon(Icons.close, size: 18, color: Colors.grey[500]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(HabitIcons.getIcon(habit.iconIndex),
                            color: themeColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.title,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "已打卡 ${habit.checkInRecords.length} 次",
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.red[400], size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "删除后所有打卡记录将一并清除，此操作不可撤销！",
                          style: TextStyle(
                              color: Colors.red[700], fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("保留", style: TextStyle(fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await AchievementService.recordDeletedHabit();

                          final habitTitle = habit.title;
                          widget.onDelete(habit);
                          Navigator.pop(ctx);
                          await WidgetService.updateWidget(widget.habits);

                          // ===== 统一SnackBar样式：删除习惯成功 =====
                          _showSnackBar(
                            context,
                            icon: Icons.delete_outline,
                            message: "已删除「$habitTitle」",
                            backgroundColor: Colors.red[400]!,
                          );

                          await _checkAndShowAchievements();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text("删除", style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    // ===== 获取壁纸状态 =====
    final appState = HabitApp.of(context);
    final useWallpaper = appState?.useWallpaper ?? false;
    final wallpaperDecoration = appState?.wallpaperDecoration;

    return Scaffold(
      backgroundColor: useWallpaper ? Colors.transparent : backgroundColor,
      extendBodyBehindAppBar: true, // 始终让内容延伸到AppBar下面

      body: Stack(
        children: [
          // ===== 壁纸背景层 =====
          if (useWallpaper && wallpaperDecoration != null)
            Positioned.fill(
              child: Container(decoration: wallpaperDecoration),
            ),

          // ===== 半透明遮罩层 =====
          if (useWallpaper)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.03),
              ),
            ),

          // ===== 固定标题栏 =====
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 应用名称
                  Text(
                    "雕刀",
                    style: TextStyle(
                      letterSpacing: 4,
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
                  // 可以在这里添加其他标题栏按钮
                ],
              ),
            ),
          ),

          // ===== 内容层 =====
          Positioned.fill(
            top: MediaQuery.of(context).padding.top + 60, // 标题栏高度 + 状态栏高度
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                return false;
              },
              child: CustomScrollView(
                slivers: [
                  // ===== 名言区域 =====
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.only(
                        top: 8,
                        left: 20,
                        right: 20,
                        bottom: 16,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() =>
                        currentQuote = quotes[Random().nextInt(quotes.length)]),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 40),
                          decoration: BoxDecoration(
                            color: useWallpaper
                                ? Colors.white.withValues(alpha: 0.85)
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: useWallpaper
                                ? null
                                : Border.all(color: Colors.grey[200]!),
                            boxShadow: useWallpaper
                                ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                                : null,
                          ),
                          child: Text(
                            currentQuote,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: themeColor.withValues(alpha: 0.8),
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ===== 习惯列表（分组式） =====
                  ..._buildGroupedHabitList(themeColor, useWallpaper),

                  // ===== 底部空白占位 =====
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        ],
      ),

      // ===== 浮动按钮 =====
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        elevation: useWallpaper ? 4 : 2,
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 构建分组习惯列表
  List<Widget> _buildGroupedHabitList(Color themeColor, bool useWallpaper) {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    // 分组：待办 vs 已完成（使用新的判断逻辑）
    final todoHabits = widget.habits.where((h) => !h.isTodayCompleted).toList();
    final doneHabits = widget.habits.where((h) => h.isTodayCompleted).toList();

    return [
      // ===== 今日待办 =====
      if (todoHabits.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: _buildSectionHeader(
              icon: Icons.radio_button_unchecked,
              title: "今日待办",
              count: todoHabits.length,
              color: themeColor,
              useWallpaper: useWallpaper,
            ),
          ),
        ),

      if (todoHabits.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: useWallpaper
                    ? Colors.white.withValues(alpha: 0.95)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: useWallpaper
                    ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
                    : [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: todoHabits.asMap().entries.map((entry) {
                  final index = entry.key;
                  final habit = entry.value;
                  return _buildTodoHabitItem(
                    habit,
                    themeColor,
                    isFirst: index == 0,
                    isLast: index == todoHabits.length - 1,
                  );
                }).toList(),
              ),
            ),
          ),
        ),

      // ===== 今日已完成 =====
      if (doneHabits.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: _buildSectionHeader(
              icon: Icons.check_circle_outline,
              title: "今日已完成",
              count: doneHabits.length,
              color: Colors.green,
              useWallpaper: useWallpaper,
            ),
          ),
        ),

      if (doneHabits.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: useWallpaper
                    ? Colors.white.withValues(alpha: 0.95)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: useWallpaper
                    ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
                    : [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: doneHabits.asMap().entries.map((entry) {
                  final index = entry.key;
                  final habit = entry.value;
                  return _buildDoneHabitItem(
                    habit,
                    themeColor,
                    isFirst: index == 0,
                    isLast: index == doneHabits.length - 1,
                  );
                }).toList(),
              ),
            ),
          ),
        ),

      // ===== 空状态 =====
      if (widget.habits.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: useWallpaper ? Colors.white54 : Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  "还没有习惯",
                  style: TextStyle(
                    fontSize: 16,
                    color: useWallpaper ? Colors.white70 : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "点击右下角 + 创建你的第一个习惯",
                  style: TextStyle(
                    fontSize: 13,
                    color: useWallpaper ? Colors.white54 : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),

      // ===== 全部完成提示 =====
      if (widget.habits.isNotEmpty && todoHabits.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeColor.withValues(alpha: 0.1),
                    Colors.green.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.celebration,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "太棒了！今日目标已全部完成 🎉",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "坚持就是胜利，明天继续加油！",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ];
  }

  /// 构建分组标题
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
    required bool useWallpaper,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: useWallpaper ? Colors.white : Colors.grey[800],
            shadows: useWallpaper
                ? [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 3,
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ]
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建待办习惯项（大卡片样式）
  Widget _buildTodoHabitItem(
      Habit habit,
      Color themeColor, {
        bool isFirst = false,
        bool isLast = false,
      }) {
    final streak = _calculateStreak(habit);
    final todayCount = habit.todayCheckInCount;
    final dailyTarget = habit.dailyTarget;
    final progress = todayCount / dailyTarget;

    // 根据位置确定圆角
    BorderRadius itemRadius;
    if (isFirst && isLast) {
      itemRadius = BorderRadius.circular(16);
    } else if (isFirst) {
      itemRadius = const BorderRadius.vertical(top: Radius.circular(16));
    } else if (isLast) {
      itemRadius = const BorderRadius.vertical(bottom: Radius.circular(16));
    } else {
      itemRadius = BorderRadius.zero;
    }

    return ClipRRect(
      borderRadius: itemRadius,
      child: Dismissible(
        key: Key('todo_${habit.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          _showSwipeActions(habit, hasTodayRecord: todayCount > 0);
          return false;
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.red.withValues(alpha: 0.1),
                Colors.red.withValues(alpha: 0.2),
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (todayCount > 0) ...[
                Icon(Icons.undo, color: Colors.orange[400], size: 22),
                const SizedBox(width: 16),
              ],
              Icon(Icons.delete_outline, color: Colors.red[400], size: 22),
              const SizedBox(width: 8),
            ],
          ),
        ),
        // ===== 移除内部的 Container 背景色，使用透明 =====
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => DetailPage(
                  habit: habit,
                  allHabits: widget.habits,
                  onSave: widget.onSave,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // 图标
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          HabitIcons.getIcon(habit.iconIndex),
                          color: themeColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // 内容
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  habit.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (dailyTarget > 1) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: themeColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "$todayCount/$dailyTarget",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: themeColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (streak > 0) ...[
                                  Icon(
                                    Icons.local_fire_department,
                                    size: 14,
                                    color: Colors.orange[400],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$streak天连续',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange[400],
                                    ),
                                  ),
                                ] else if (habit.description.isNotEmpty) ...[
                                  Expanded(
                                    child: Text(
                                      habit.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    '待完成',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      // 打卡按钮
                      GestureDetector(
                        onTap: () => _toggleCheckIn(habit),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: themeColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: themeColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, size: 16, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                '打卡',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 多次打卡进度条
                  if (dailyTarget > 1 && todayCount > 0) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          themeColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建已完成习惯项（紧凑样式）
  Widget _buildDoneHabitItem(
      Habit habit,
      Color themeColor, {
        bool isFirst = false,
        bool isLast = false,
      }) {
    final streak = _calculateStreak(habit);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayCount = habit.todayCheckInCount;

    // 获取今日打卡记录
    final todayRecords = habit.checkInRecords
        .where((r) => r.time.startsWith(todayStr))
        .toList();

    // 获取最后一次打卡时间
    final lastRecord = todayRecords.isNotEmpty ? todayRecords.last : null;
    final checkInTime = lastRecord != null
        ? DateFormat('HH:mm').format(DateTime.parse(lastRecord.time))
        : '--:--';

    // 根据位置确定圆角
    BorderRadius itemRadius;
    if (isFirst && isLast) {
      itemRadius = BorderRadius.circular(16);
    } else if (isFirst) {
      itemRadius = const BorderRadius.vertical(top: Radius.circular(16));
    } else if (isLast) {
      itemRadius = const BorderRadius.vertical(bottom: Radius.circular(16));
    } else {
      itemRadius = BorderRadius.zero;
    }

    return ClipRRect(
      borderRadius: itemRadius,
      child: Dismissible(
        key: Key('done_${habit.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          _showSwipeActions(habit, hasTodayRecord: true);
          return false;
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.orange.withValues(alpha: 0.1),
                Colors.orange.withValues(alpha: 0.2),
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.undo, color: Colors.orange[400], size: 22),
              const SizedBox(width: 16),
              Icon(Icons.delete_outline, color: Colors.red[400], size: 22),
              const SizedBox(width: 8),
            ],
          ),
        ),
        // ===== 移除内部的 Container 背景色，使用透明 =====
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => DetailPage(
                  habit: habit,
                  allHabits: widget.habits,
                  onSave: widget.onSave,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
              ),
              child: Row(
                children: [
                  // 完成图标
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      HabitIcons.getIcon(habit.iconIndex),
                      color: Colors.green,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 习惯名称
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          habit.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[700],
                          ),
                        ),
                        if (habit.dailyTarget > 1) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "$todayCount/${habit.dailyTarget}",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 打卡时间
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.green[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        checkInTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // 连续天数
                  if (streak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 12,
                            color: Colors.orange[400],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$streak天',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 计算连续打卡天数
  int _calculateStreak(Habit habit) {
    if (habit.checkInRecords.isEmpty) return 0;

    final dates = habit.checkInRecords
        .map((r) => DateFormat('yyyy-MM-dd').format(DateTime.parse(r.time)))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (dates.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(checkDate);
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(
      checkDate.subtract(const Duration(days: 1)),
    );

    if (!dates.contains(todayStr) && !dates.contains(yesterdayStr)) {
      return 0;
    }

    if (!dates.contains(todayStr)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    for (int i = 0; i < 365; i++) {
      final dateStr = DateFormat('yyyy-MM-dd').format(
        checkDate.subtract(Duration(days: i)),
      );
      if (dates.contains(dateStr)) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /// 显示左滑操作选项
  void _showSwipeActions(Habit habit, {required bool hasTodayRecord}) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayRecords = habit.checkInRecords
        .where((r) => r.time.startsWith(todayStr))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 拖动指示条
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // 习惯信息
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        HabitIcons.getIcon(habit.iconIndex),
                        color: themeColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (hasTodayRecord) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.check_circle,
                                    size: 14, color: Colors.green[400]),
                                const SizedBox(width: 4),
                                Text(
                                  "今日已打卡 ${todayRecords.length}${habit.dailyTarget > 1 ? '/${habit.dailyTarget}' : ''} 次",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 18, color: Colors.grey[500]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // 操作选项
                if (hasTodayRecord) ...[
                  // 取消打卡选项（显示今日所有打卡记录）
                  _buildSwipeActionItem(
                    icon: Icons.undo,
                    title: "取消打卡",
                    subtitle: habit.dailyTarget > 1
                        ? "选择要取消的打卡记录"
                        : "取消今日的打卡记录",
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(ctx);
                      if (todayRecords.length == 1) {
                        // 只有一条记录，直接确认取消
                        _confirmCancelSingleCheckIn(habit, todayRecords.first);
                      } else {
                        // 多条记录，显示选择列表
                        _showCancelCheckInList(habit, todayRecords);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                // 删除习惯选项
                _buildSwipeActionItem(
                  icon: Icons.delete_outline,
                  title: "删除习惯",
                  subtitle: "删除后所有打卡记录将一并清除",
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteHabit(habit);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建左滑操作项
  Widget _buildSwipeActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }

  /// 确认取消单条打卡记录
  void _confirmCancelSingleCheckIn(Habit habit, CheckInRecord record) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final checkInTime = DateTime.parse(record.time);
    final timeStr = DateFormat('HH:mm').format(checkInTime);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
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
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.undo, color: Colors.orange, size: 30),
                ),
                const SizedBox(height: 16),
                const Text(
                  "确认取消打卡？",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  "「${habit.title}」今日 $timeStr 的打卡记录",
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                if (record.note != null && record.note!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.format_quote, size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            record.note!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("保留", style: TextStyle(fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await AchievementService.recordCancelledCheckIn();

                          setState(() {
                            habit.checkInRecords.remove(record);
                          });
                          widget.onSave();
                          Navigator.pop(ctx);
                          await WidgetService.updateWidget(widget.habits);

                          _showSnackBar(
                            context,
                            icon: Icons.undo,
                            message: "已取消打卡",
                            backgroundColor: Colors.orange,
                          );

                          await _checkAndShowAchievements();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text("取消打卡", style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 显示取消打卡列表（多条记录时）
  void _showCancelCheckInList(Habit habit, List<CheckInRecord> records) {
    final themeColor = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题栏
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.undo, color: Colors.orange, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "选择要取消的打卡",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "「${habit.title}」今日共 ${records.length} 次打卡",
                                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, size: 18, color: Colors.grey[500]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 打卡记录列表
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    final checkInTime = DateTime.parse(record.time);
                    final timeStr = DateFormat('HH:mm:ss').format(checkInTime);
                    final isMakeUp = record.note?.contains("[补卡于") ?? false;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _confirmCancelSingleCheckIn(habit, record);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isMakeUp
                                      ? Colors.orange.withValues(alpha: 0.1)
                                      : themeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    "${index + 1}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isMakeUp ? Colors.orange : themeColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          timeStr,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (isMakeUp) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              "补卡",
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (record.note != null && record.note!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        _extractDisplayNote(record.note!),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red[300],
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 提取显示用的备注（去除补卡标记）
  String _extractDisplayNote(String note) {
    final regex = RegExp(r'\[补卡于.+?\]\s*');
    return note.replaceAll(regex, '').trim();
  }
}

// ========== 统计页面 ==========
class StatisticsPage extends StatefulWidget {
  final List<Habit> habits;

  const StatisticsPage({super.key, required this.habits});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {

  // 计算总打卡次数
  int get totalCheckIns {
    return widget.habits.fold(0, (sum, h) => sum + h.checkInRecords.length);
  }

  // 计算当前连续天数最长的习惯
  int get currentStreak {
    if (widget.habits.isEmpty) return 0;

    int maxStreak = 0;
    for (final habit in widget.habits) {
      final streak = _calculateHabitStreak(habit);
      if (streak > maxStreak) {
        maxStreak = streak;
      }
    }
    return maxStreak;
  }

  // ===== 修改：计算历史最长总打卡天数 =====
  int get maxTotalDays {
    if (widget.habits.isEmpty) return 0;

    int maxDays = 0;
    for (final habit in widget.habits) {
      final days = _calculateTotalDays(habit);
      if (days > maxDays) {
        maxDays = days;
      }
    }
    return maxDays;
  }

// 计算总打卡天数（去重）
  int _calculateTotalDays(Habit habit) {
    final dates = <String>{};
    for (final record in habit.checkInRecords) {
      if (record.time.length >= 10) {
        dates.add(record.time.substring(0, 10));
      }
    }
    return dates.length;
  }

  // ===== 新增：计算某个习惯的历史最长连续天数 =====
  int _calculateMaxStreakEver(Habit habit) {
    if (habit.checkInRecords.isEmpty) return 0;

    // 获取所有打卡日期（去重）
    final dates = <String>{};
    for (final record in habit.checkInRecords) {
      if (record.time.length >= 10) {
        dates.add(record.time.substring(0, 10));
      }
    }

    if (dates.isEmpty) return 0;

    // 将日期排序
    final sortedDates = dates.toList()..sort();

    int maxStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      final prevDate = DateTime.parse(sortedDates[i - 1]);
      final currDate = DateTime.parse(sortedDates[i]);
      final difference = currDate.difference(prevDate).inDays;

      if (difference == 1) {
        // 连续
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else if (difference > 1) {
        // 中断
        currentStreak = 1;
      }
      // difference == 0 表示同一天，忽略
    }

    return maxStreak;
  }

  // 计算今日完成率
  double get todayCompletionRate {
    if (widget.habits.isEmpty) return 0;

    int completed = 0;
    for (final habit in widget.habits) {
      // ===== 修改：使用 isTodayCompleted 判断是否完成全部目标 =====
      if (habit.isTodayCompleted) {
        completed++;
      }
    }
    return completed / widget.habits.length;
  }

  // 计算本周完成率
  double get weekCompletionRate {
    if (widget.habits.isEmpty) return 0;

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    int totalPossible = widget.habits.length * now.weekday;
    int totalCompleted = 0;

    for (int i = 0; i < now.weekday; i++) {
      final date = DateFormat('yyyy-MM-dd').format(weekStart.add(Duration(days: i)));
      for (final habit in widget.habits) {
        if (habit.checkInTimes.any((t) => t.startsWith(date))) {
          totalCompleted++;
        }
      }
    }

    return totalPossible > 0 ? totalCompleted / totalPossible : 0;
  }

  // 计算本月完成率
  double get monthCompletionRate {
    if (widget.habits.isEmpty) return 0;

    final now = DateTime.now();
    int totalPossible = widget.habits.length * now.day;
    int totalCompleted = 0;

    for (int i = 1; i <= now.day; i++) {
      final date = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, i));
      for (final habit in widget.habits) {
        if (habit.checkInTimes.any((t) => t.startsWith(date))) {
          totalCompleted++;
        }
      }
    }

    return totalPossible > 0 ? totalCompleted / totalPossible : 0;
  }

  // 获取习惯排行（按连续天数）
  List<Map<String, dynamic>> get habitRanking {
    final ranking = <Map<String, dynamic>>[];

    for (final habit in widget.habits) {
      final streak = _calculateHabitStreak(habit);
      final maxStreak = _calculateMaxStreakEver(habit);
      // 计算总打卡天数（去重）
      final totalDays = _calculateTotalDays(habit);
      ranking.add({
        'habit': habit,
        'streak': streak,
        'maxStreak': maxStreak,
        'totalDays': totalDays,
        'total': habit.checkInRecords.length,
      });
    }

    ranking.sort((a, b) => (b['streak'] as int).compareTo(a['streak'] as int));
    return ranking;
  }

  int _calculateHabitStreak(Habit habit) {
    if (habit.checkInRecords.isEmpty) return 0;

    final dates = <String>{};
    for (final record in habit.checkInRecords) {
      if (record.time.length >= 10) {
        dates.add(record.time.substring(0, 10));
      }
    }

    int streak = 0;
    DateTime date = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');

    String todayStr = dateFormat.format(date);
    if (!dates.contains(todayStr)) {
      date = date.subtract(const Duration(days: 1));
    }

    while (dates.contains(dateFormat.format(date))) {
      streak++;
      date = date.subtract(const Duration(days: 1));
    }

    return streak;
  }

  // 获取最近30天的打卡数据（用于热力图）
  List<Map<String, dynamic>> get heatmapData {
    final data = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      int count = 0;

      for (final habit in widget.habits) {
        if (habit.checkInTimes.any((t) => t.startsWith(dateStr))) {
          count++;
        }
      }

      data.add({
        'date': date,
        'dateStr': dateStr,
        'count': count,
        'total': widget.habits.length,
      });
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    // 获取壁纸状态
    final appState = HabitApp.of(context);
    final useWallpaper = appState?.useWallpaper ?? false;
    final wallpaperDecoration = appState?.wallpaperDecoration;

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

          // ===== 固定标题栏 =====
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
                    "统计",
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
                // 概览卡片
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        _buildStatCard(
                          "习惯数",
                          "${widget.habits.length}",
                          Icons.flag_outlined,
                          themeColor,
                          useWallpaper,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          "打卡数",
                          "$totalCheckIns",
                          Icons.check_circle_outline,
                          themeColor,
                          useWallpaper,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          "连续中",
                          "$currentStreak天",
                          Icons.local_fire_department_outlined,
                          Colors.orange,
                          useWallpaper,
                        ),
                        const SizedBox(width: 12),
                        // ===== 修改：最长连续天数 =====
                        _buildStatCard(
                          "最长",
                          "$maxTotalDays天",
                          Icons.emoji_events_outlined,
                          Colors.amber,
                          useWallpaper,
                        ),
                      ],
                    ),
                  ),
                ),

                // 完成率卡片
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: _buildCard(
                      useWallpaper: useWallpaper,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.pie_chart_outline, size: 20, color: themeColor),
                              const SizedBox(width: 8),
                              Text(
                                "完成率",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildProgressRing("今日", todayCompletionRate, themeColor),
                              _buildProgressRing("本周", weekCompletionRate, Colors.blue),
                              _buildProgressRing("本月", monthCompletionRate, Colors.purple),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 打卡热力图
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: _buildCard(
                      useWallpaper: useWallpaper,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_month_outlined, size: 20, color: themeColor),
                              const SizedBox(width: 8),
                              Text(
                                "最近30天",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildHeatmap(themeColor),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text("少", style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                              const SizedBox(width: 4),
                              ...List.generate(
                                5,
                                    (i) => Container(
                                  width: 12,
                                  height: 12,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: themeColor.withValues(alpha: 0.2 + i * 0.2),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text("多", style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 习惯排行
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: _buildCard(
                      useWallpaper: useWallpaper,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.leaderboard_outlined, size: 20, color: themeColor),
                              const SizedBox(width: 8),
                              Text(
                                "习惯排行",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (habitRanking.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text("暂无数据", style: TextStyle(color: Colors.grey[400])),
                              ),
                            )
                          else
                            ...habitRanking.take(5).toList().asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final habit = item['habit'] as Habit;
                              final streak = item['streak'] as int;
                              final maxStreak = item['maxStreak'] as int;
                              final totalDays = item['totalDays'] as int;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    // 排名
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: index == 0
                                            ? Colors.amber[100]
                                            : index == 1
                                            ? Colors.grey[200]
                                            : index == 2
                                            ? Colors.orange[100]
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "${index + 1}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: index == 0
                                                ? Colors.amber[800]
                                                : index == 1
                                                ? Colors.grey[600]
                                                : index == 2
                                                ? Colors.orange[800]
                                                : Colors.grey[500],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // 图标
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: themeColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        HabitIcons.getIcon(habit.iconIndex),
                                        color: themeColor,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // 名称和统计
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            habit.title,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Text(
                                                "共 $totalDays 天",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[400],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.emoji_events,
                                                size: 12,
                                                color: Colors.amber[600],
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                "最长 $maxStreak 天",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.amber[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // 当前连续天数
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: streak > 0
                                            ? Colors.orange[50]
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.local_fire_department,
                                            size: 14,
                                            color: streak > 0
                                                ? Colors.orange[600]
                                                : Colors.grey[400],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "$streak天",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: streak > 0
                                                  ? Colors.orange[700]
                                                  : Colors.grey[400],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
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

  // ===== 新增：统一的卡片样式 =====
  Widget _buildCard({
    required bool useWallpaper,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: useWallpaper
            ? Colors.white.withValues(alpha: 0.95)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: useWallpaper ? 0.08 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // 构建统计卡片
  Widget _buildStatCard(
      String label,
      String value,
      IconData icon,
      Color color,
      bool useWallpaper,
      ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: useWallpaper
              ? Colors.white.withValues(alpha: 0.95)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: useWallpaper ? 0.08 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  // 构建进度环
  Widget _buildProgressRing(String label, double progress, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              Center(
                child: Text(
                  "${(progress * 100).toInt()}%",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }

  // 构建热力图
  Widget _buildHeatmap(Color themeColor) {
    final data = heatmapData;
    final habitCount = widget.habits.length;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: data.map((item) {
        final count = item['count'] as int;
        final date = item['date'] as DateTime;
        final opacity = habitCount > 0 ? (count / habitCount).clamp(0.0, 1.0) : 0.0;

        return Tooltip(
          message: "${DateFormat('M/d').format(date)}: $count/$habitCount",
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: count > 0
                  ? themeColor.withValues(alpha: 0.2 + opacity * 0.8)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                "${date.day}",
                style: TextStyle(
                  fontSize: 10,
                  color: count > 0 ? Colors.white : Colors.grey[400],
                  fontWeight: count > 0 ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ========== 我的页面 ==========
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

// ========== 数据备份页面 ==========
class BackupPage extends StatefulWidget {
  final List<Habit> habits;
  final Function(List<Habit>) onRestore;

  const BackupPage({
    super.key,
    required this.habits,
    required this.onRestore,
  });

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool _isExporting = false;
  bool _isImporting = false;

  /// 统一的卡片装饰样式
  BoxDecoration _cardDecoration({
    required bool useWallpaper,
    Color? borderColor,
    double radius = 12,
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

  String _generateFileName() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);
    return 'habit_backup_$dateStr.json';
  }

  Future<Map<String, dynamic>> _generateBackupData() async {
    final achievementStatus = await AchievementService.exportAchievementStatus();

    return {
      'version': '1.8.5',
      'appName': '雕刀',
      'backupTime': DateTime.now().toIso8601String(),
      'habitsCount': widget.habits.length,
      'habits': widget.habits.map((h) => h.toJson()).toList(),
      'achievementStatus': achievementStatus,
    };
  }

  Future<void> _exportToLocal() async {
    setState(() => _isExporting = true);

    try {
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
          if (!status.isGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("需要存储权限才能导出文件")),
              );
            }
            return;
          }
        }
      }

      final backupData = await _generateBackupData();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(backupData);

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) throw Exception("无法获取存储目录");

      final fileName = _generateFileName();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonStr);

      if (mounted) {
        _showExportSuccessDialog(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("导出失败：$e")),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _showExportSuccessDialog(String filePath) {
    final themeColor = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
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
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 40),
                ),
                const SizedBox(height: 16),
                const Text(
                  "导出成功",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  "备份文件已保存到本地",
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.folder_outlined, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            "文件位置",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        filePath,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text("我知道了", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareBackup() async {
    setState(() => _isExporting = true);

    try {
      final backupData = await _generateBackupData();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(backupData);

      final tempDir = await getTemporaryDirectory();
      final fileName = _generateFileName();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonStr);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '雕刀 - 习惯数据备份',
        text: '这是我的习惯打卡数据备份文件',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("分享失败：$e")),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _importBackup() async {
    setState(() => _isImporting = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final jsonStr = await file.readAsString();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      if (!data.containsKey('habits')) {
        throw Exception("无效的备份文件格式");
      }

      final habitsList = data['habits'] as List;
      final habits = habitsList.map((h) => Habit.fromJson(h)).toList();

      final achievementStatus = data['achievementStatus'] as Map<String, dynamic>?;

      if (mounted) {
        final backupTime = data['backupTime'] != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(data['backupTime']))
            : '未知';

        _showImportConfirmDialog(habits, backupTime, achievementStatus);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("导入失败：$e")),
        );
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }

  void _showImportConfirmDialog(
      List<Habit> habits,
      String backupTime,
      Map<String, dynamic>? achievementStatus,
      ) {
    final themeColor = Theme.of(context).colorScheme.primary;
    int totalCheckIns = habits.fold(0, (sum, h) => sum + h.checkInRecords.length);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
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
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.restore, color: Colors.orange, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "确认恢复数据",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "备份于 $backupTime",
                            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 18, color: Colors.grey[500]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: themeColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDialogStatItem("习惯数量", "${habits.length} 个", themeColor),
                      Container(width: 1, height: 40, color: themeColor.withValues(alpha: 0.2)),
                      _buildDialogStatItem("打卡记录", "$totalCheckIns 次", themeColor),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "恢复将覆盖当前所有数据，此操作不可撤销！",
                          style: TextStyle(color: Colors.orange[800], fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("取消", style: TextStyle(fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await AchievementService.importAchievementStatus(achievementStatus);
                          widget.onRestore(habits);
                          await AchievementService.resyncAfterImport(habits);
                          _showRestoreSuccessDialog(habits.length);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text("确认恢复", style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRestoreSuccessDialog(int count) {
    final themeColor = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
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
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 40),
                ),
                const SizedBox(height: 16),
                const Text(
                  "恢复成功",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  "已恢复 $count 个习惯",
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text("我知道了", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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

          // ===== 内容层 =====
          Positioned.fill(
            top: MediaQuery.of(context).padding.top + 60,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 当前数据卡片
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: useWallpaper
                        ? themeColor.withValues(alpha: 0.15)
                        : themeColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: useWallpaper ? 0.08 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.folder_outlined, size: 40, color: themeColor),
                      const SizedBox(height: 12),
                      Text(
                        "当前数据",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${widget.habits.length} 个习惯",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: themeColor,
                        ),
                      ),
                      Text(
                        "${widget.habits.fold(0, (sum, h) => sum + h.checkInTimes.length)} 次打卡记录",
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "导出备份",
                  style: TextStyle(
                    fontSize: 14,
                    color: useWallpaper ? Colors.grey[700] : Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  icon: Icons.download_outlined,
                  title: "保存到本地",
                  subtitle: "将备份文件保存到下载目录",
                  color: themeColor,
                  isLoading: _isExporting,
                  onTap: _exportToLocal,
                  useWallpaper: useWallpaper,
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  icon: Icons.share_outlined,
                  title: "分享备份文件",
                  subtitle: "通过微信、邮件等方式分享",
                  color: themeColor,
                  isLoading: _isExporting,
                  onTap: _shareBackup,
                  useWallpaper: useWallpaper,
                ),
                const SizedBox(height: 24),
                Text(
                  "导入备份",
                  style: TextStyle(
                    fontSize: 14,
                    color: useWallpaper ? Colors.grey[700] : Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  icon: Icons.upload_outlined,
                  title: "从文件恢复",
                  subtitle: "选择备份文件恢复数据",
                  color: Colors.orange,
                  isLoading: _isImporting,
                  onTap: _importBackup,
                  useWallpaper: useWallpaper,
                ),
                const SizedBox(height: 24),
                // 备份说明卡片
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(
                    useWallpaper: useWallpaper,
                  ).copyWith(
                    color: useWallpaper
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.grey[50],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            "备份说明",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTip("• 备份文件包含所有习惯和打卡记录"),
                      _buildTip("• 建议定期备份，防止数据丢失"),
                      _buildTip("• 恢复数据会覆盖当前所有数据"),
                      _buildTip("• 备份文件可以跨设备使用"),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),

          // ===== 固定标题栏 =====
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                bottom: 16,
                left: 16,
                right: 20,
              ),
              child: Row(
                children: [
                  // 返回按钮
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: useWallpaper
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: useWallpaper ? 0.1 : 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: useWallpaper ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 页面标题
                  Text(
                    "数据备份",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
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
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isLoading,
    required VoidCallback onTap,
    required bool useWallpaper,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(useWallpaper: useWallpaper),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: isLoading
                  ? Padding(
                padding: const EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
                  : Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[300], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
    );
  }
}

// ========== 主题设置页面 ==========
class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  bool _isLoading = false;

  /// 统一的卡片装饰样式
  BoxDecoration _cardDecoration({
    required bool useWallpaper,
    Color? borderColor,
    double radius = 16,
    bool isSelected = false,
    Color? selectedColor,
  }) {
    return BoxDecoration(
      color: useWallpaper
          ? Colors.white.withValues(alpha: 0.95)
          : Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: borderColor != null ? Border.all(
        color: borderColor,
        width: isSelected ? 2 : 1,
      ) : null,
      boxShadow: [
        BoxShadow(
          color: isSelected && selectedColor != null
              ? selectedColor.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: useWallpaper ? 0.08 : 0.05),
          blurRadius: isSelected ? 8 : 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// 统一的SnackBar显示方法
  void _showSnackBar(
      BuildContext context, {
        required IconData icon,
        required String message,
        required Color backgroundColor,
        Duration duration = const Duration(seconds: 2),
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: duration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    // 获取壁纸状态
    final appState = HabitApp.of(context);
    final currentTheme = appState?.currentTheme;
    final wallpaperData = appState?.wallpaperData;
    final useWallpaper = appState?.useWallpaper ?? false;
    final wallpaperDecoration = appState?.wallpaperDecoration;

    return Scaffold(
      backgroundColor: useWallpaper ? Colors.transparent : backgroundColor,
      extendBodyBehindAppBar: true,

      body: Stack(
        children: [
          // ===== 壁纸背景层 =====
          if (useWallpaper && wallpaperDecoration != null)
            Positioned.fill(
              child: Container(decoration: wallpaperDecoration),
            ),

          // ===== 半透明遮罩 =====
          if (useWallpaper)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.03),
              ),
            ),

          // ===== 内容层 =====
          Positioned.fill(
            top: MediaQuery.of(context).padding.top + 60,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ===== 壁纸设置卡片 =====
                  _buildWallpaperCard(
                    context,
                    appState,
                    wallpaperData,
                    useWallpaper,
                    themeColor,
                  ),

                  const SizedBox(height: 24),

                  // ===== 预览效果 =====
                  _buildPreviewCard(
                    wallpaperData,
                    useWallpaper,
                    themeColor,
                  ),

                  // ===== 预设主题颜色 =====
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        "选择主题颜色",
                        style: TextStyle(
                          fontSize: 14,
                          color: useWallpaper ? Colors.white70 : Colors.grey[500],
                          fontWeight: FontWeight.w500,
                          shadows: useWallpaper
                              ? [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 2,
                            ),
                          ]
                              : null,
                        ),
                      ),
                      if (useWallpaper) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "壁纸模式",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 遍历所有主题选项
                  ...ThemeConfig.colorOptions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isSelected =
                        !useWallpaper && currentTheme?.name == option.name;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildThemeOption(
                        appState,
                        index,
                        option,
                        isSelected,
                        useWallpaper,
                      ),
                    );
                  }),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // ===== 固定标题栏 =====
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                bottom: 16,
                left: 16,
                right: 20,
              ),
              child: Row(
                children: [
                  // 返回按钮
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: useWallpaper
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: useWallpaper ? 0.1 : 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: useWallpaper ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 页面标题
                  Text(
                    "主题设置",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
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

          // 加载遮罩
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  /// 壁纸设置卡片
  Widget _buildWallpaperCard(
      BuildContext context,
      HabitAppState? appState,
      WallpaperData? wallpaperData,
      bool useWallpaper,
      Color themeColor,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(useWallpaper: useWallpaper),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.wallpaper, color: themeColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "壁纸背景",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "上传壁纸作为全局背景",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 壁纸内容
          if (useWallpaper && wallpaperData != null) ...[
            // 已有壁纸：显示预览
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(wallpaperData.path),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          "使用中",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: _buildButton(
                    icon: Icons.refresh,
                    label: "更换壁纸",
                    color: themeColor,
                    onTap: () => _pickWallpaper(context, appState),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildButton(
                    icon: Icons.delete_outline,
                    label: "移除壁纸",
                    color: Colors.red[400]!,
                    isOutlined: true,
                    onTap: () => _removeWallpaper(context, appState),
                  ),
                ),
              ],
            ),
          ] else ...[
            // 无壁纸：显示上传按钮
            Center(
              child: InkWell(
                onTap: () => _pickWallpaper(context, appState),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "点击上传壁纸",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "支持 JPG、PNG 格式",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 预览卡片
  Widget _buildPreviewCard(
      WallpaperData? wallpaperData,
      bool useWallpaper,
      Color themeColor,
      ) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: useWallpaper ? 0.15 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: useWallpaper
                  ? null
                  : Theme.of(context).scaffoldBackgroundColor,
              image: useWallpaper && wallpaperData != null
                  ? DecorationImage(
                image: FileImage(File(wallpaperData.path)),
                fit: BoxFit.cover,
              )
                  : null,
            ),
          ),
          if (useWallpaper)
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          Container(
            height: 180,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "预览效果",
                  style: TextStyle(
                    fontSize: 12,
                    color: useWallpaper ? Colors.white70 : Colors.grey[500],
                    shadows: useWallpaper
                        ? [Shadow(color: Colors.black38, blurRadius: 2)]
                        : null,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: useWallpaper ? 0.95 : 1),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          color: themeColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "每日运动",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "已坚持 30 天",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: themeColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 主题选项
  Widget _buildThemeOption(
      HabitAppState? appState,
      int index,
      ThemeColorOption option,
      bool isSelected,
      bool useWallpaper,
      ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await appState?.setThemeColor(index);
          if (mounted) setState(() {});
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(
            useWallpaper: useWallpaper,
            radius: 14,
            // ===== 修改：只有选中时才显示边框 =====
            borderColor: isSelected ? option.color : null,
            isSelected: isSelected,
            selectedColor: option.color,
          ),
          child: Opacity(
            opacity: useWallpaper ? 0.6 : 1.0,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: option.color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: option.color.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 24)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? option.color : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(5, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isSelected ? 28 : 24,
                            height: 8,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: option.color.withValues(alpha: 0.2 + i * 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSelected ? 1 : 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: option.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: option.color,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return Material(
      color: isOutlined ? Colors.transparent : color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: isOutlined
              ? BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color),
          )
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isOutlined ? color : Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isOutlined ? color : Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black38,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("处理中..."),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickWallpaper(BuildContext context, HabitAppState? appState) async {
    if (appState == null) return;

    setState(() => _isLoading = true);
    try {
      final success = await appState.setWallpaper(context);
      if (success && mounted) {
        setState(() {});
        _showSnackBar(
          context,
          icon: Icons.check_circle,
          message: "壁纸设置成功",
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          context,
          icon: Icons.error,
          message: "设置失败: $e",
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 移除壁纸确认弹窗
  Future<void> _removeWallpaper(BuildContext context, HabitAppState? appState) async {
    final themeColor = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
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
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.delete_outline,
                          color: Colors.red[400], size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "移除壁纸",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "确定要移除当前壁纸吗？",
                            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 18, color: Colors.grey[500]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 18, color: Colors.red[700]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "移除后所有页面将恢复默认背景样式",
                          style: TextStyle(
                              color: Colors.red[700], fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("保留壁纸", style: TextStyle(fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          setState(() => _isLoading = true);
                          await appState?.clearWallpaper();
                          if (mounted) setState(() => _isLoading = false);

                          _showSnackBar(
                            context,
                            icon: Icons.check_circle,
                            message: "壁纸已移除",
                            backgroundColor: Colors.green,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text("移除", style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========== 提醒设置页面 ==========
class ReminderSettingsPage extends StatefulWidget {
  final List<Habit> habits;
  final VoidCallback onSave;

  const ReminderSettingsPage({
    super.key,
    required this.habits,
    required this.onSave,
  });

  @override
  State<ReminderSettingsPage> createState() => _ReminderSettingsPageState();
}

class _ReminderSettingsPageState extends State<ReminderSettingsPage> {
  /// 统一的卡片装饰样式
  BoxDecoration _cardDecoration({
    required bool useWallpaper,
    Color? borderColor,
    double radius = 12,
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

  /// 统一的SnackBar显示方法
  void _showSnackBar(
      BuildContext context, {
        required IconData icon,
        required String message,
        required Color backgroundColor,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
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
            Positioned.fill(
                child: Container(color: Colors.black.withValues(alpha: 0.03))),

          // ===== 内容层 =====
          Positioned.fill(
            top: MediaQuery.of(context).padding.top + 60,
            child: widget.habits.isEmpty
                ? Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.all(20),
                decoration: _cardDecoration(useWallpaper: useWallpaper),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_off_outlined,
                        size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text("暂无习惯",
                        style: TextStyle(color: Colors.grey[400])),
                  ],
                ),
              ),
            )
                : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 顶部说明
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: useWallpaper
                        ? themeColor.withValues(alpha: 0.15)
                        : themeColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                            alpha: useWallpaper ? 0.08 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: themeColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "设置提醒后将添加到系统日历，每天定时提醒你打卡",
                          style: TextStyle(fontSize: 13, color: themeColor),
                        ),
                      ),
                    ],
                  ),
                ),
                // 习惯列表
                ...widget.habits.map(
                        (habit) => _buildHabitCard(habit, themeColor, useWallpaper)),
                const SizedBox(height: 100),
              ],
            ),
          ),

          // ===== 固定标题栏 =====
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                bottom: 16,
                left: 16,
                right: 20,
              ),
              child: Row(
                children: [
                  // 返回按钮
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: useWallpaper
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                                alpha: useWallpaper ? 0.1 : 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: useWallpaper ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 页面标题
                  Text(
                    "提醒设置",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
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
        ],
      ),
    );
  }

  Widget _buildHabitCard(Habit habit, Color themeColor, bool useWallpaper) {
    final hasReminder = habit.reminderTime != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardDecoration(
        useWallpaper: useWallpaper,
        borderColor: hasReminder ? themeColor.withValues(alpha: 0.3) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSetReminderFlow(habit),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 左侧图标
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasReminder
                        ? themeColor.withValues(alpha: 0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasReminder
                        ? Icons.notifications_active
                        : Icons.notifications_none,
                    color: hasReminder ? themeColor : Colors.grey[400],
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                // 中间内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasReminder
                            ? "每天 ${habit.reminderTime} 提醒"
                            : "点击设置打卡提醒",
                        style: TextStyle(
                          fontSize: 13,
                          color: hasReminder ? themeColor : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                // 右侧箭头或时间标签
                if (hasReminder)
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: 14, color: themeColor),
                        const SizedBox(width: 4),
                        Text(
                          habit.reminderTime!,
                          style: TextStyle(
                            fontSize: 13,
                            color: themeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Icon(Icons.chevron_right, color: Colors.grey[300], size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 设置提醒的完整流程
  void _showSetReminderFlow(Habit habit) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final hasReminder = habit.reminderTime != null;

    // 解析已有的时间
    TimeOfDay initialTime = TimeOfDay.now();
    if (hasReminder) {
      final parts = habit.reminderTime!.split(':');
      initialTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 拖动指示条
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // 标题行
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.notifications_active,
                          color: themeColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasReminder ? "修改提醒时间" : "设置打卡提醒",
                            style:
                            TextStyle(fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child:
                        Icon(Icons.close, size: 18, color: Colors.grey[500]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // 时间选择按钮
                _TimePickerButton(
                  initialTime: initialTime,
                  themeColor: themeColor,
                  onConfirm: (time) {
                    Navigator.pop(ctx);
                    _confirmAndAddToCalendar(habit, time);
                  },
                ),
                // 如果已有提醒，显示删除按钮
                if (hasReminder) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showDeleteReminderDialog(habit);
                    },
                    child: Text(
                      "删除提醒",
                      style: TextStyle(color: Colors.red[400], fontSize: 14),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 确认并添加到日历
  void _confirmAndAddToCalendar(Habit habit, TimeOfDay time) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    final now = DateTime.now();
    final tomorrow =
    DateTime(now.year, now.month, now.day + 1, time.hour, time.minute);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.calendar_month, color: themeColor, size: 28),
            ),
            const SizedBox(height: 12),
            const Text("添加到日历", style: TextStyle(fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "将「${habit.title}」的每日提醒添加到系统日历？",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time, color: themeColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "每天 $timeStr",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: themeColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("取消"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    // 保存提醒时间
                    setState(() => habit.reminderTime = timeStr);
                    widget.onSave();
                    // 打开日历
                    _openCalendarIntent(habit, tomorrow);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text("确认添加"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 删除提醒确认
  void _showDeleteReminderDialog(Habit habit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 拖动指示条
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                // 警告图标
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.notifications_off_outlined,
                      color: Colors.red[400], size: 36),
                ),
                const SizedBox(height: 20),
                // 标题
                const Text(
                  "删除提醒",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  "确定要删除「${habit.title}」的提醒吗？",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // 提示信息
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border:
                    Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "日历中的事件需要手动删除",
                          style:
                          TextStyle(color: Colors.orange[800], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // 按钮区域
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child:
                        const Text("取消", style: TextStyle(fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => habit.reminderTime = null);
                          widget.onSave();
                          Navigator.pop(ctx);
                          _showSnackBar(
                            context,
                            icon: Icons.check_circle,
                            message: "已删除提醒",
                            backgroundColor: Colors.green,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text("确认删除",
                            style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCalendarIntent(Habit habit, DateTime startDate) async {
    if (Platform.isAndroid) {
      final intent = AndroidIntent(
        action: 'android.intent.action.INSERT',
        data: 'content://com.android.calendar/events',
        arguments: <String, dynamic>{
          'title': '${habit.title} - 打卡提醒',
          'description': '来自「雕刀」App',
          'beginTime': startDate.millisecondsSinceEpoch,
          'endTime':
          startDate.add(const Duration(minutes: 30)).millisecondsSinceEpoch,
          'allDay': false,
          'rrule': 'FREQ=DAILY;COUNT=365',
        },
      );
      try {
        await intent.launch();
        if (mounted) {
          _showSnackBar(
            context,
            icon: Icons.check_circle,
            message: "已为「${habit.title}」设置提醒",
            backgroundColor: Colors.green,
          );
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar(
            context,
            icon: Icons.error,
            message: "打开日历失败: $e",
            backgroundColor: Colors.red,
          );
        }
      }
    }
  }
}

// 时间选择器组件
class _TimePickerButton extends StatefulWidget {
  final TimeOfDay initialTime;
  final Color themeColor;
  final Function(TimeOfDay) onConfirm;

  const _TimePickerButton({
    required this.initialTime,
    required this.themeColor,
    required this.onConfirm,
  });

  @override
  State<_TimePickerButton> createState() => _TimePickerButtonState();
}

class _TimePickerButtonState extends State<_TimePickerButton> {
  late int _selectedHour;
  late int _selectedMinute;

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;
    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController =
        FixedExtentScrollController(initialItem: _selectedMinute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 时间选择器
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: widget.themeColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.themeColor.withValues(alpha: 0.2),
            ),
          ),
          child: Stack(
            children: [
              // 选中行高亮背景
              Center(
                child: Container(
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: widget.themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // 滚轮选择器
              Row(
                children: [
                  // 小时
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: _hourController,
                      itemExtent: 44,
                      perspective: 0.005,
                      diameterRatio: 1.5,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setState(() => _selectedHour = index);
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 24,
                        builder: (context, index) {
                          final isSelected = index == _selectedHour;
                          return Center(
                            child: Text(
                              '${index.toString().padLeft(2, '0')} 时',
                              style: TextStyle(
                                fontSize: isSelected ? 20 : 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? widget.themeColor
                                    : Colors.grey[400],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // 分隔符
                  Text(
                    ":",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: widget.themeColor,
                    ),
                  ),
                  // 分钟
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: _minuteController,
                      itemExtent: 44,
                      perspective: 0.005,
                      diameterRatio: 1.5,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setState(() => _selectedMinute = index);
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 60,
                        builder: (context, index) {
                          final isSelected = index == _selectedMinute;
                          return Center(
                            child: Text(
                              '${index.toString().padLeft(2, '0')} 分',
                              style: TextStyle(
                                fontSize: isSelected ? 20 : 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? widget.themeColor
                                    : Colors.grey[400],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // 确认按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => widget.onConfirm(
              TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
            ),
            icon: const Icon(Icons.calendar_month, size: 20),
            label: const Text("设置打卡提醒", style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.themeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}

// ========== 关于页面 ==========
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _currentVersion = '';
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
  }

  /// 统一的卡片装饰样式
  BoxDecoration _cardDecoration({
    required bool useWallpaper,
    Color? borderColor,
    double radius = 12,
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

  Future<void> _loadCurrentVersion() async {
    final version = await UpdateService.getCurrentVersion();
    if (mounted) {
      setState(() => _currentVersion = version);
    }
  }

  Future<void> _checkUpdate() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);

    try {
      final result = await UpdateService.checkUpdate();

      if (!mounted) return;

      if (result.error != null) {
        _showSnackBar(
          context,
          icon: Icons.error,
          message: result.error!,
          backgroundColor: Colors.red,
        );
      } else if (result.hasUpdate && result.updateInfo != null) {
        await UpdateDialog.show(
          context,
          updateInfo: result.updateInfo!,
          currentVersion: result.currentVersion ?? _currentVersion,
        );
      } else {
        _showSnackBar(
          context,
          icon: Icons.check_circle,
          message: "当前已是最新版本 v${result.currentVersion ?? _currentVersion}",
          backgroundColor: Colors.green,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  void _showSnackBar(
      BuildContext context, {
        required IconData icon,
        required String message,
        required Color backgroundColor,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
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

          // ===== 内容层 =====
          Positioned.fill(
            top: MediaQuery.of(context).padding.top + 60,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Logo 卡片容器
                  Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: _cardDecoration(
                      useWallpaper: useWallpaper,
                      radius: 20,
                    ),
                    child: Column(
                      children: [
                        // Logo
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: themeColor.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/ic_launcher.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // 应用名称
                        const Text(
                          "雕刀",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 版本号
                        Text(
                          "版本 ${_currentVersion.isNotEmpty ? _currentVersion : '...'}",
                          style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 20),
                        // Slogan
                        Text(
                          "用极简的方式，雕刻更好的自己",
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 检查更新按钮
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: _cardDecoration(
                          useWallpaper: useWallpaper,
                          radius: 12,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isChecking ? null : _checkUpdate,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _isChecking
                                      ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: themeColor,
                                    ),
                                  )
                                      : Icon(Icons.refresh, size: 18, color: themeColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isChecking ? "正在检查..." : "检查更新",
                                    style: TextStyle(
                                      color: themeColor,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 信息卡片
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDecoration(
                      useWallpaper: useWallpaper,
                      radius: 12,
                    ),
                    child: Column(
                      children: [
                        _infoRow("开发者", "Vence的猫"),
                        const Divider(height: 20),
                        _infoRow("联系邮箱", "vence_cat@163.com"),
                        const Divider(height: 20),
                        _infoRowWithCopy("体验反馈群", "228484290"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // ===== 固定标题栏 =====
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                bottom: 16,
                left: 16,
                right: 20,
              ),
              child: Row(
                children: [
                  // 返回按钮
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: useWallpaper
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: useWallpaper ? 0.1 : 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: useWallpaper ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 页面标题
                  Text(
                    "关于",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
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
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
      ],
    );
  }

  Widget _infoRowWithCopy(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            _showSnackBar(
              context,
              icon: Icons.copy,
              message: "群号已复制",
              backgroundColor: Colors.green,
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
              const SizedBox(width: 6),
              Icon(Icons.copy, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ],
    );
  }
}


// ========== 详情页 ==========
class DetailPage extends StatefulWidget {
  final Habit habit;
  final List<Habit> allHabits;
  final VoidCallback onSave;

  const DetailPage({
    super.key,
    required this.habit,
    required this.allHabits,
    required this.onSave,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late PageController _pageController;
  late DateTime _currentMonth;
  DateTime? _selectedDate;

  static const int _initialPage = 1200;

  /// ===== 统一的SnackBar显示方法 =====
  void _showSnackBar(
      BuildContext context, {
        required IconData icon,
        required String message,
        required Color backgroundColor,
        Duration duration = const Duration(seconds: 2),
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: duration,
      ),
    );
  }

  DateTime _getMonthFromPage(int page) {
    final now = DateTime.now();
    final monthDiff = page - _initialPage;
    return DateTime(now.year, now.month + monthDiff);
  }

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _pageController = PageController(initialPage: _initialPage);
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Set<String> get _checkInDates {
    return widget.habit.checkInTimes
        .map((t) => DateFormat('yyyy-MM-dd').format(DateTime.parse(t)))
        .toSet();
  }

  List<CheckInRecord> get _selectedDateRecords {
    if (_selectedDate == null) return [];
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    return widget.habit.checkInRecords
        .where((r) => r.time.startsWith(dateStr))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    // ===== 获取壁纸状态 =====
    final appState = HabitApp.of(context);
    final useWallpaper = appState?.useWallpaper ?? false;
    final wallpaperDecoration = appState?.wallpaperDecoration;

    return Scaffold(
      // 壁纸模式下背景透明
      backgroundColor: useWallpaper ? Colors.transparent : backgroundColor,
      extendBodyBehindAppBar: true, // 始终让内容延伸到AppBar下面

      body: Stack(
        children: [
          // ===== 壁纸背景层 =====
          if (useWallpaper && wallpaperDecoration != null)
            Positioned.fill(
              child: Container(decoration: wallpaperDecoration),
            ),

          // ===== 半透明遮罩 =====
          if (useWallpaper)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.03),
              ),
            ),

          // ===== 内容层 =====
          Positioned.fill(
            top: MediaQuery.of(context).padding.top + 60, // 标题栏高度 + 状态栏高度
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildInfoCard(themeColor, useWallpaper),
                const SizedBox(height: 24),
                _buildCalendarCard(themeColor, useWallpaper),
                const SizedBox(height: 24),
                _buildRecordHeader(themeColor, useWallpaper),
                const SizedBox(height: 12),
                _buildRecordList(themeColor, useWallpaper),
                const SizedBox(height: 100), // 底部留白
              ],
            ),
          ),

          // ===== 固定标题栏（二级页面包含返回按钮） =====
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                bottom: 16,
                left: 16,
                right: 20,
              ),
              child: Row(
                children: [
                  // 返回按钮
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: useWallpaper
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: useWallpaper
                            ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                            : null,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: useWallpaper ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 页面标题
                  Text(
                    "习惯详情",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
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
        ],
      ),
    );
  }

  Widget _buildInfoCard(Color themeColor, bool useWallpaper) {
    // 获取选中日期的打卡次数
    final selectedDateCount = _selectedDate != null
        ? widget.habit.getCheckInCountForDate(_selectedDate!)
        : widget.habit.todayCheckInCount;

    // 判断选中日期是否已完成目标
    final isSelectedDateCompleted = selectedDateCount >= widget.habit.dailyTarget;

    // 格式化选中日期用于显示
    final isToday = _selectedDate != null &&
        DateFormat('yyyy-MM-dd').format(_selectedDate!) ==
            DateFormat('yyyy-MM-dd').format(DateTime.now());
    final selectedDateStr = _selectedDate != null
        ? (isToday ? "今日" : DateFormat('M月d日').format(_selectedDate!))
        : "今日";

    return Container(
      padding: const EdgeInsets.all(20),
      // ===== 使用统一的卡片装饰 =====
      decoration: _cardDecoration(
        useWallpaper: useWallpaper,
        borderColor: themeColor.withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  HabitIcons.getIcon(widget.habit.iconIndex),
                  color: themeColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.habit.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
              GestureDetector(
                onTap: () => _showEditHabitDialog(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.edit_outlined, size: 18, color: themeColor),
                ),
              ),
            ],
          ),
          if (widget.habit.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notes_outlined, color: Colors.grey[400], size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.habit.description,
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey[600], height: 1.5),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.access_time_outlined, color: Colors.grey[400], size: 20),
              const SizedBox(width: 10),
              Text(
                "创建于 ${_formatCreatedAt(widget.habit.createdAt)}",
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem("累计打卡", "${widget.habit.checkInRecords.length}次", themeColor),
                    Container(width: 1, height: 30, color: themeColor.withValues(alpha: 0.2)),
                    _statItem("连续天数", "${_calculateStreak()}天", themeColor),
                    Container(width: 1, height: 30, color: themeColor.withValues(alpha: 0.2)),
                    _statItem("本月打卡", "${_getMonthCheckIns()}天", themeColor),
                  ],
                ),
                // 如果每日目标大于1，显示选中日期的进度
                if (widget.habit.dailyTarget > 1) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: themeColor.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.repeat, size: 18, color: themeColor),
                            const SizedBox(width: 10),
                            Text(
                              "$selectedDateStr打卡",
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                            const Spacer(),
                            Text(
                              "$selectedDateCount/${widget.habit.dailyTarget} 次",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelectedDateCompleted ? Colors.green : themeColor,
                              ),
                            ),
                            if (isSelectedDateCompleted) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.check_circle, size: 16, color: Colors.green),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (selectedDateCount / widget.habit.dailyTarget).clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isSelectedDateCompleted ? Colors.green : themeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(Color themeColor, bool useWallpaper) {
    int getRowCount(DateTime month) {
      final firstDayOfMonth = DateTime(month.year, month.month, 1);
      final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
      final daysInMonth = lastDayOfMonth.day;
      final firstWeekday =
      firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
      return ((firstWeekday + daysInMonth) / 7).ceil();
    }

    final rowCount = getRowCount(_currentMonth);

    return Container(
      // ===== 使用统一的卡片装饰 =====
      decoration: _cardDecoration(useWallpaper: useWallpaper),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.calendar_month, color: themeColor, size: 20),
                const SizedBox(width: 8),
                Text("打卡日历",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700])),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = DateTime.now();
                    });
                    _pageController.animateToPage(
                      _initialPage,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text("今天",
                        style: TextStyle(fontSize: 12, color: themeColor)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: Colors.grey[600]),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
                Text(DateFormat('yyyy年MM月').format(_currentMonth),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: Colors.grey[600]),
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['日', '一', '二', '三', '四', '五', '六']
                  .map((day) => Expanded(
                child: Center(
                  child: Text(day,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500)),
                ),
              ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cellWidth = (constraints.maxWidth - 24) / 7;
                final cellHeight = cellWidth;
                final calendarHeight =
                    rowCount * cellHeight + (rowCount - 1) * 4;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: calendarHeight,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() {
                        _currentMonth = _getMonthFromPage(page);
                      });
                    },
                    itemBuilder: (context, page) {
                      final month = _getMonthFromPage(page);
                      return _buildMonthGrid(month, themeColor);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegend(themeColor, "已打卡"),
                const SizedBox(width: 24),
                _buildLegend(Colors.grey[300]!, "未打卡"),
                const SizedBox(width: 24),
                _buildSelectedLegend(themeColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(DateTime month, Color themeColor) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday =
    firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
    final rowCount = ((firstWeekday + daysInMonth) / 7).ceil();
    final totalCells = rowCount * 7;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayNumber = index - firstWeekday + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox();
        }

        final date = DateTime(month.year, month.month, dayNumber);
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
        final isCheckedIn = _checkInDates.contains(dateStr);
        final isFuture = date.isAfter(today);

        final isSelected = _selectedDate != null &&
            date.year == _selectedDate!.year &&
            date.month == _selectedDate!.month &&
            date.day == _selectedDate!.day;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? themeColor.withValues(alpha: 0.3)
                  : isCheckedIn
                  ? themeColor.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isSelected
                  ? Border.all(color: themeColor, width: 2)
                  : isSelected
                  ? Border.all(color: themeColor, width: 2)
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '$dayNumber',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday || isCheckedIn || isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isFuture
                        ? Colors.grey[300]
                        : isSelected
                        ? themeColor
                        : isCheckedIn
                        ? themeColor
                        : Colors.grey[700],
                  ),
                ),
                if (isCheckedIn && !isSelected)
                  Positioned(
                    bottom: 4,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                          color: themeColor, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildSelectedLegend(Color themeColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.3),
            border: Border.all(color: themeColor, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text("选中", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildRecordHeader(Color themeColor, bool useWallpaper) {
    final records = _selectedDateRecords;
    final hasRecord = records.isNotEmpty;
    final isMakeUp =
        hasRecord && records.any((r) => r.note != null && r.note!.contains("[补卡于"));

    // 检查是否完成今日目标
    final selectedDateCount = _selectedDate != null
        ? widget.habit.getCheckInCountForDate(_selectedDate!)
        : 0;
    final isCompleted = selectedDateCount >= widget.habit.dailyTarget;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(Icons.article_outlined, color: themeColor, size: 20),
          const SizedBox(width: 8),
          Text(
            "打卡日志",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: useWallpaper ? Colors.white : Colors.grey[700],
              shadows: useWallpaper
                  ? [Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 2)]
                  : null,
            ),
          ),
          // 显示次数（如果每日目标大于1）
          if (widget.habit.dailyTarget > 1 && hasRecord) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.withValues(alpha: useWallpaper ? 0.9 : 0.1)
                    : themeColor.withValues(alpha: useWallpaper ? 0.9 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "$selectedDateCount/${widget.habit.dailyTarget}",
                style: TextStyle(
                  fontSize: 11,
                  color: isCompleted
                      ? (useWallpaper ? Colors.white : Colors.green)
                      : (useWallpaper ? Colors.white : themeColor),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: hasRecord
                  ? isCompleted
                  ? Colors.green.withValues(alpha: useWallpaper ? 0.9 : 0.1)
                  : isMakeUp
                  ? Colors.orange.withValues(alpha: useWallpaper ? 0.9 : 0.1)
                  : themeColor.withValues(alpha: useWallpaper ? 0.9 : 0.1)
                  : useWallpaper
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasRecord && isCompleted)
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: useWallpaper ? Colors.white : Colors.green,
                  ),
                if (hasRecord && isCompleted) const SizedBox(width: 4),
                Text(
                  hasRecord
                      ? isCompleted
                      ? "已完成"
                      : isMakeUp
                      ? "已补卡"
                      : "已打卡"
                      : "未打卡",
                  style: TextStyle(
                    fontSize: 12,
                    color: hasRecord
                        ? isCompleted
                        ? (useWallpaper ? Colors.white : Colors.green)
                        : isMakeUp
                        ? (useWallpaper ? Colors.white : Colors.orange)
                        : (useWallpaper ? Colors.white : themeColor)
                        : Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordList(Color themeColor, bool useWallpaper) {
    final records = _selectedDateRecords;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final isFuture = _selectedDate != null &&
        DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day)
            .isAfter(today);
    final isToday = _selectedDate != null &&
        DateFormat('yyyy-MM-dd').format(_selectedDate!) ==
            DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isPast = _selectedDate != null &&
        DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day)
            .isBefore(today);

    // 计算选中日期的打卡次数和是否可以继续补卡
    final selectedDateCount = _selectedDate != null
        ? widget.habit.getCheckInCountForDate(_selectedDate!)
        : 0;
    final canMakeUpMore = selectedDateCount < widget.habit.dailyTarget;

    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        // ===== 使用统一的卡片装饰 =====
        decoration: _cardDecoration(useWallpaper: useWallpaper),
        child: Column(
          children: [
            Icon(
              isFuture ? Icons.schedule_outlined : Icons.event_busy_outlined,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isFuture ? "这是未来的日期" : "这天没有打卡记录",
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            Text(
              isFuture
                  ? "期待你的坚持！"
                  : isToday
                  ? "快去完成今天的打卡吧！"
                  : "继续加油哦～",
              style: TextStyle(fontSize: 12, color: Colors.grey[300]),
            ),
            if (isPast) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => _showMakeUpCheckInDialog(),
                icon: Icon(Icons.add_task, size: 18, color: themeColor),
                label: Text("补卡", style: TextStyle(color: themeColor)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: themeColor.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // 有打卡记录的情况
    return Column(
      children: [
        ...records.reversed.map((record) {
          final dateTime = DateTime.parse(record.time);
          final isMakeUp = record.note != null && record.note!.contains("[补卡于");

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            // ===== 使用统一的卡片装饰 =====
            decoration: _cardDecoration(
              useWallpaper: useWallpaper,
              borderColor: isMakeUp
                  ? Colors.orange.withValues(alpha: 0.3)
                  : themeColor.withValues(alpha: 0.3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isMakeUp
                            ? Colors.orange.withValues(alpha: 0.1)
                            : themeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isMakeUp ? Icons.history : Icons.check,
                        color: isMakeUp ? Colors.orange : themeColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isMakeUp ? "补卡成功" : "打卡成功",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (isMakeUp) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _extractMakeUpTime(record.note!),
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.orange),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('HH:mm:ss').format(dateTime),
                            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _editNote(record),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          record.note != null && record.note!.isNotEmpty
                              ? Icons.edit_note
                              : Icons.add_comment_outlined,
                          size: 18,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ],
                ),
                _buildNoteSection(record, isMakeUp, themeColor),
              ],
            ),
          );
        }),

        // 如果是过去的日期且还可以继续补卡，显示"继续补卡"按钮
        if (isPast && canMakeUpMore) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(
              useWallpaper: useWallpaper,
              borderColor: themeColor.withValues(alpha: 0.2),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text(
                      "还可补卡 ${widget.habit.dailyTarget - selectedDateCount} 次",
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showMakeUpCheckInDialog(),
                  icon: Icon(Icons.add_task, size: 18, color: themeColor),
                  label: Text("继续补卡", style: TextStyle(color: themeColor)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: themeColor.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ],

        // 如果是今天且还可以继续打卡
        if (isToday && canMakeUpMore) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(
              useWallpaper: useWallpaper,
              borderColor: themeColor.withValues(alpha: 0.2),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.schedule, size: 16, color: themeColor),
                    const SizedBox(width: 6),
                    Text(
                      "还需打卡 ${widget.habit.dailyTarget - selectedDateCount} 次",
                      style: TextStyle(fontSize: 13, color: themeColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: selectedDateCount / widget.habit.dailyTarget,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _extractMakeUpTime(String note) {
    final regex = RegExp(r'\[补卡于(.+?)\]');
    final match = regex.firstMatch(note);
    if (match != null) {
      return "补于${match.group(1)}";
    }
    return "补签";
  }

  Widget _buildNoteSection(
      CheckInRecord record, bool isMakeUp, Color themeColor) {
    if (record.note == null || record.note!.isEmpty) {
      return const SizedBox.shrink();
    }

    String displayNote = record.note!;
    final regex = RegExp(r'\[补卡于.+?\]\s*');
    displayNote = displayNote.replaceAll(regex, '').trim();

    if (displayNote.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMakeUp
                ? Colors.orange.withValues(alpha: 0.05)
                : themeColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isMakeUp
                  ? Colors.orange.withValues(alpha: 0.1)
                  : themeColor.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.format_quote,
                size: 16,
                color: isMakeUp
                    ? Colors.orange.withValues(alpha: 0.5)
                    : themeColor.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayNote,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditHabitDialog() {
    final titleController = TextEditingController(text: widget.habit.title);
    final descController = TextEditingController(text: widget.habit.description);
    final themeColor = Theme.of(context).colorScheme.primary;
    int selectedIconIndex = widget.habit.iconIndex;
    int dailyTarget = widget.habit.dailyTarget; // 新增

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
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
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(HabitIcons.getIcon(selectedIconIndex),
                                color: themeColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "编辑习惯",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close,
                                  size: 18, color: Colors.grey[500]),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "选择图标",
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 10),
                      IconSelector(
                        selectedIndex: selectedIconIndex,
                        themeColor: themeColor,
                        onSelect: (index) {
                          setModalState(() => selectedIconIndex = index);
                        },
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: "习惯名称",
                          hintText: "例如：喝水",
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                            BorderSide(color: themeColor, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descController,
                        maxLines: 2,
                        maxLength: 100,
                        decoration: InputDecoration(
                          labelText: "描述（选填）",
                          hintText: "例如：每天喝8杯水",
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                            BorderSide(color: themeColor, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                          counterStyle: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ===== 新增：每日目标次数选择器 =====
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.repeat, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "每日目标",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "每天需要完成的次数",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (dailyTarget > 1) {
                                  setModalState(() => dailyTarget--);
                                }
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: dailyTarget > 1
                                      ? themeColor.withValues(alpha: 0.1)
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.remove,
                                  size: 20,
                                  color: dailyTarget > 1
                                      ? themeColor
                                      : Colors.grey[400],
                                ),
                              ),
                            ),
                            Container(
                              width: 50,
                              alignment: Alignment.center,
                              child: Text(
                                '$dailyTarget',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: themeColor,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (dailyTarget < 99) {
                                  setModalState(() => dailyTarget++);
                                }
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: themeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 20,
                                  color: themeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (titleController.text.trim().isNotEmpty) {
                              setState(() {
                                widget.habit.title = titleController.text.trim();
                                widget.habit.description =
                                    descController.text.trim();
                                widget.habit.iconIndex = selectedIconIndex;
                                widget.habit.dailyTarget = dailyTarget; // 新增
                              });
                              widget.onSave();
                              Navigator.pop(ctx);

                              _showSnackBar(
                                context,
                                icon: Icons.check_circle,
                                message: "已保存修改",
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 1),
                              );
                            } else {
                              _showSnackBar(
                                ctx,
                                icon: Icons.error,
                                message: "习惯名称不能为空",
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 1),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          child: const Text("保存修改",
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showMakeUpCheckInDialog() {
    final noteController = TextEditingController();
    final themeColor = Theme.of(context).colorScheme.primary;
    final selectedDateStr = DateFormat('MM月dd日').format(_selectedDate!);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
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
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.history,
                            color: Colors.orange, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "补卡",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedDateStr,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.orange),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close,
                              size: 18, color: Colors.grey[500]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    maxLength: 100,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "写点什么记录一下吧...",
                      hintStyle:
                      TextStyle(color: Colors.grey[400], fontSize: 14),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      counterStyle: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _performMakeUpCheckIn(noteController.text.trim());
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child:
                      const Text("确认补卡", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkAndShowAchievements() async {
    final newAchievements =
    await AchievementService.checkNewAchievements(widget.allHabits);

    if (newAchievements.isNotEmpty && mounted) {
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        await AchievementUnlockDialog.showMultiple(context, newAchievements);
      }
    }
  }

  void _performMakeUpCheckIn(String note) {
    final now = DateTime.now();

    final makeUpTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      now.hour,
      now.minute,
      now.second,
    );

    final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(makeUpTime);

    final actualTimeStr = DateFormat('MM月dd日 HH:mm').format(now);
    final noteContent = note.isNotEmpty
        ? "[补卡于$actualTimeStr] $note"
        : "[补卡于$actualTimeStr]";

    final record = CheckInRecord(
      time: timeStr,
      note: noteContent,
    );

    widget.habit.checkInRecords.add(record);
    widget.onSave();

    setState(() {});

    // ===== 统一SnackBar样式：补卡成功 =====
    _showSnackBar(
      context,
      icon: Icons.history,
      message: "已补卡 ${DateFormat('MM月dd日').format(_selectedDate!)}",
      backgroundColor: Colors.green,
    );

    _checkAndShowAchievements();
  }

  void _editNote(CheckInRecord record) {
    String originalNote = record.note ?? '';
    String makeUpPrefix = '';
    String userNote = originalNote;

    final regex = RegExp(r'(\[补卡于.+?\])\s*');
    final match = regex.firstMatch(originalNote);
    if (match != null) {
      makeUpPrefix = match.group(1)!;
      userNote = originalNote.replaceAll(regex, '').trim();
    }

    final noteController = TextEditingController(text: userNote);
    final themeColor = Theme.of(context).colorScheme.primary;
    final dateTime = DateTime.parse(record.time);
    final dateStr = DateFormat('MM月dd日 HH:mm').format(dateTime);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
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
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                        Icon(Icons.edit_note, color: themeColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "编辑备注",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateStr,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close,
                              size: 18, color: Colors.grey[500]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: noteController,
                    maxLines: 4,
                    maxLength: 100,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "写点什么记录一下吧...",
                      hintStyle:
                      TextStyle(color: Colors.grey[400], fontSize: 14),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeColor, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      counterStyle: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (userNote.isNotEmpty)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              if (makeUpPrefix.isNotEmpty) {
                                record.note = makeUpPrefix;
                              } else {
                                record.note = null;
                              }
                              widget.onSave();
                              setState(() {});
                              Navigator.pop(ctx);

                              // ===== 统一SnackBar样式：删除备注成功 =====
                              _showSnackBar(
                                context,
                                icon: Icons.delete_outline,
                                message: "已删除备注",
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 1),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red[400],
                              side: BorderSide(color: Colors.red[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text("删除备注",
                                style: TextStyle(fontSize: 15)),
                          ),
                        ),
                      if (userNote.isNotEmpty) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            String newNote = noteController.text.trim();

                            if (makeUpPrefix.isNotEmpty) {
                              if (newNote.isNotEmpty) {
                                record.note = '$makeUpPrefix $newNote';
                              } else {
                                record.note = makeUpPrefix;
                              }
                            } else {
                              record.note = newNote.isNotEmpty ? newNote : null;
                            }

                            widget.onSave();
                            setState(() {});
                            Navigator.pop(ctx);

                            // ===== 统一SnackBar样式：保存备注成功 =====
                            _showSnackBar(
                              context,
                              icon: Icons.check_circle,
                              message: "已保存备注",
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 1),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          child: const Text("保存备注",
                              style: TextStyle(fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatCreatedAt(String createdAt) {
    try {
      final dateTime = DateTime.parse(createdAt);
      return DateFormat('yyyy年MM月dd日').format(dateTime);
    } catch (e) {
      return createdAt;
    }
  }

  int _calculateStreak() {
    if (widget.habit.checkInRecords.isEmpty) return 0;

    int streak = 0;
    DateTime currentDate = DateTime.now();

    String todayStr = DateFormat('yyyy-MM-dd').format(currentDate);
    if (!_checkInDates.contains(todayStr)) {
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    while (true) {
      String dateStr = DateFormat('yyyy-MM-dd').format(currentDate);
      if (_checkInDates.contains(dateStr)) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  int _getMonthCheckIns() {
    final now = DateTime.now();
    final monthStr = DateFormat('yyyy-MM').format(now);

    final Set<String> monthDates = widget.habit.checkInRecords
        .where((r) => r.time.startsWith(monthStr))
        .map((r) => DateFormat('yyyy-MM-dd').format(DateTime.parse(r.time)))
        .toSet();

    return monthDates.length;
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }

  /// 统一的卡片装饰样式
  BoxDecoration _cardDecoration({
    required bool useWallpaper,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: useWallpaper
          ? Colors.white.withValues(alpha: 0.95)
          : Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: borderColor != null
          ? Border.all(color: borderColor)
          : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: useWallpaper ? 0.08 : 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

// ========== 成就页面 ==========
class AchievementPage extends StatefulWidget {
  final List<Habit> habits;

  const AchievementPage({super.key, required this.habits});

  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage> {
  bool _isLoading = true;
  Set<String> _permanentlyUnlockedIds = {};
  List<Achievement> _allAchievements = [];

  /// 统一的卡片装饰样式
  BoxDecoration _cardDecoration({
    required bool useWallpaper,
    Color? borderColor,
    double radius = 16,
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
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    // 获取永久解锁的成就ID
    final unlockedIds = await AchievementService.getUnlockedAchievements();

    // 获取所有成就（带进度）
    final checker = await AchievementChecker.create(widget.habits);
    final allAchievements = checker.getAllAchievementsWithProgress();

    // 标记永久解锁的成就为已解锁
    for (int i = 0; i < allAchievements.length; i++) {
      if (unlockedIds.contains(allAchievements[i].id)) {
        final a = allAchievements[i];
        allAchievements[i] = Achievement(
          id: a.id,
          icon: a.icon,
          title: a.title,
          description: a.description,
          isUnlocked: true,
          progress: 1.0,
          current: a.target,
          target: a.target,
          category: a.category,
        );
      }
    }

    if (mounted) {
      setState(() {
        _permanentlyUnlockedIds = unlockedIds;
        _allAchievements = allAchievements;
        _isLoading = false;
      });
    }
  }

  // 获取常规成就
  List<Achievement> get regularAchievements {
    return _allAchievements.where((a) => a.category != '特殊成就').toList();
  }

  // 获取特殊成就（只返回已解锁的）
  List<Achievement> get specialAchievements {
    return _allAchievements.where((a) => a.category == '特殊成就' && a.isUnlocked).toList();
  }

  // 特殊成就总数
  int get totalSpecialAchievements =>
      _allAchievements.where((a) => a.category == '特殊成就').length;

  // 已解锁成就数
  int get unlockedCount {
    return _allAchievements.where((a) => a.isUnlocked).length;
  }

  // 成就总数
  int get totalAchievements => _allAchievements.length;

  // 按类别分组（常规成就）
  Map<String, List<Achievement>> get groupedRegularAchievements {
    final map = <String, List<Achievement>>{};
    for (final achievement in regularAchievements) {
      if (!map.containsKey(achievement.category)) {
        map[achievement.category] = [];
      }
      map[achievement.category]!.add(achievement);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    // 获取壁纸状态
    final appState = HabitApp.of(context);
    final useWallpaper = appState?.useWallpaper ?? false;
    final wallpaperDecoration = appState?.wallpaperDecoration;

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

          // ===== 内容层 =====
          Positioned.fill(
            top: MediaQuery.of(context).padding.top + 60, // 标题栏高度 + 状态栏高度
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildAchievementContent(themeColor, useWallpaper),
          ),

          // ===== 固定标题栏（二级页面包含返回按钮） =====
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                bottom: 16,
                left: 16,
                right: 20,
              ),
              child: Row(
                children: [
                  // 返回按钮
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: useWallpaper
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: useWallpaper
                            ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                            : null,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: useWallpaper ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 页面标题
                  Text(
                    "打卡成就",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
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
        ],
      ),
    );
  }

  /// 构建成就内容（提取出来的方法，保持原逻辑）
  Widget _buildAchievementContent(Color themeColor, bool useWallpaper) {
    final grouped = groupedRegularAchievements;
    final unlockedSpecial = specialAchievements;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 成就概览卡片
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                themeColor.withValues(alpha: 0.8),
                themeColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Color(0xFFFFD700),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "成就进度",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$unlockedCount / $totalAchievements",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(
                          value: totalAchievements > 0 ? unlockedCount / totalAchievements : 0,
                          strokeWidth: 5,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        "${totalAchievements > 0 ? (unlockedCount / totalAchievements * 100).toInt() : 0}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 常规成就（按类别显示）
        ...grouped.entries.map((entry) {
          final category = entry.key;
          final categoryAchievements = entry.value;
          final unlockedInCategory = categoryAchievements.where((a) => a.isUnlocked).length;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(useWallpaper: useWallpaper),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        size: 18,
                        color: themeColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "$unlockedInCategory/${categoryAchievements.length}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...categoryAchievements.map((achievement) =>
                      _buildAchievementListItem(context, achievement, themeColor)),
                ],
              ),
            ),
          );
        }),

        // 特殊成就
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(useWallpaper: useWallpaper),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.stars_outlined,
                    size: 18,
                    color: Colors.amber[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "特殊成就",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${unlockedSpecial.length}/$totalSpecialAchievements",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (unlockedSpecial.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.lock_outline, size: 32, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        Text(
                          "暂无解锁的特殊成就",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "继续探索，发现隐藏成就吧！",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...unlockedSpecial.map((achievement) =>
                    _buildAchievementListItem(context, achievement, themeColor, isSpecial: true)),
            ],
          ),
        ),
        const SizedBox(height: 100), // 底部留白
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '打卡次数':
        return Icons.check_circle_outline;
      case '连续打卡':
        return Icons.local_fire_department_outlined;
      case '习惯数量':
        return Icons.flag_outlined;
      default:
        return Icons.emoji_events_outlined;
    }
  }

  Widget _buildAchievementListItem(BuildContext context, Achievement achievement, Color themeColor, {bool isSpecial = false}) {
    return GestureDetector(
      onTap: () => _showAchievementDetail(context, achievement, themeColor, isSpecial: isSpecial),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[100]!, width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: achievement.isUnlocked
                    ? (isSpecial ? Colors.amber[50] : themeColor.withValues(alpha: 0.1))
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                achievement.icon,
                size: 24,
                color: achievement.isUnlocked
                    ? (isSpecial ? Colors.amber[600] : themeColor)
                    : Colors.grey[400],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        achievement.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: achievement.isUnlocked ? Colors.black87 : Colors.grey[600],
                        ),
                      ),
                      if (isSpecial && achievement.isUnlocked) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.auto_awesome, size: 14, color: Colors.amber[600]),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  if (!achievement.isUnlocked) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: achievement.progress,
                              minHeight: 4,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                themeColor.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${achievement.current}/${achievement.target}",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (achievement.isUnlocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSpecial ? Colors.amber[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 14, color: isSpecial ? Colors.amber[700] : Colors.green[600]),
                    const SizedBox(width: 2),
                    Text(
                      "已解锁",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isSpecial ? Colors.amber[700] : Colors.green[700],
                      ),
                    ),
                  ],
                ),
              )
            else
              Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showAchievementDetail(BuildContext context, Achievement achievement, Color themeColor, {bool isSpecial = false}) {
    final highlightColor = isSpecial ? Colors.amber[600]! : themeColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
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
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: achievement.isUnlocked
                        ? highlightColor.withValues(alpha: 0.1)
                        : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    achievement.icon,
                    size: 40,
                    color: achievement.isUnlocked ? highlightColor : Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      achievement.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: achievement.isUnlocked ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                    if (isSpecial && achievement.isUnlocked) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.auto_awesome, size: 20, color: Colors.amber[600]),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  achievement.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "进度",
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                          Text(
                            "${achievement.current}/${achievement.target}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: achievement.isUnlocked ? highlightColor : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: achievement.progress,
                          minHeight: 8,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            achievement.isUnlocked ? highlightColor : highlightColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: achievement.isUnlocked
                        ? (isSpecial ? Colors.amber[50] : Colors.green[50])
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        achievement.isUnlocked ? Icons.check_circle : Icons.hourglass_empty,
                        size: 16,
                        color: achievement.isUnlocked
                            ? (isSpecial ? Colors.amber[700] : Colors.green[600])
                            : Colors.orange[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        achievement.isUnlocked ? "已解锁" : "进行中",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: achievement.isUnlocked
                              ? (isSpecial ? Colors.amber[700] : Colors.green[700])
                              : Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}