import 'package:flutter/material.dart';
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

import 'models/habit.dart';
import 'services/widget_service.dart';

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

// 习惯图标配置
class HabitIcons {
  static const List<IconData> icons = [
    Icons.flag_outlined,
    Icons.star_outline,
    Icons.favorite_outline,
    Icons.wb_sunny_outlined,
    Icons.bedtime_outlined,
    Icons.water_drop_outlined,
    Icons.fitness_center,
    Icons.directions_run,
    Icons.directions_walk,
    Icons.self_improvement,
    Icons.menu_book_outlined,
    Icons.edit_note,
    Icons.code,
    Icons.translate,
    Icons.music_note_outlined,
    Icons.piano_outlined,
    Icons.brush_outlined,
    Icons.camera_alt_outlined,
    Icons.local_florist_outlined,
    Icons.eco_outlined,
    Icons.restaurant_outlined,
    Icons.free_breakfast_outlined,
    Icons.local_cafe_outlined,
    Icons.apple,
    Icons.sports_gymnastics,
    Icons.pool_outlined,
    Icons.pedal_bike_outlined,
    Icons.sports_soccer_outlined,
    Icons.sports_basketball_outlined,
    Icons.spa_outlined,
    Icons.bathtub_outlined,
    Icons.cleaning_services_outlined,
    Icons.checkroom_outlined,
    Icons.alarm_outlined,
    Icons.timer_outlined,
    Icons.event_outlined,
    Icons.work_outline,
    Icons.school_outlined,
    Icons.psychology_outlined,
    Icons.lightbulb_outline,
    Icons.savings_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.phone_disabled_outlined,
    Icons.visibility_outlined,
    Icons.hearing_outlined,
    Icons.emoji_emotions_outlined,
    Icons.volunteer_activism_outlined,
    Icons.people_outline,
    Icons.pets_outlined,
    Icons.rocket_launch_outlined,
  ];

  static IconData getIcon(int index) {
    if (index >= 0 && index < icons.length) {
      return icons[index];
    }
    return icons[0];
  }
}

// 图标选择器组件
class IconSelector extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: HabitIcons.icons.length,
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onSelect(index),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? themeColor.withValues(alpha: 0.15) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? themeColor : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Icon(
                HabitIcons.icons[index],
                color: isSelected ? themeColor : Colors.grey[600],
                size: 22,
              ),
            ),
          );
        },
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

  @override
  void initState() {
    super.initState();
    _currentColorIndex = widget.initialColorIndex;
  }

  ThemeColorOption get currentTheme =>
      ThemeConfig.colorOptions[_currentColorIndex];

  Future<void> setThemeColor(int index) async {
    setState(() => _currentColorIndex = index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_color_index', index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = currentTheme;

    return MaterialApp(
      title: '雕刀',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: theme.color,
          primary: theme.color,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: theme.backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: theme.backgroundColor,
          foregroundColor: Colors.black87,
          elevation: 0,
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

      // 更新小组件
      await WidgetService.updateWidget(habits);
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('simple_habits', jsonEncode(habits));

    // 更新小组件
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

  // 新增：恢复数据方法
  void _restoreHabits(List<Habit> newHabits) {
    setState(() => habits = newHabits);
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          CheckInPage(
            habits: habits,
            onSave: _refreshAndSave,
            onAdd: _addHabit,
            onDelete: _removeHabit,
          ),
          HabitLibraryPage(onAddHabit: _addHabit),
          ProfilePage(
            habits: habits,
            onSave: _refreshAndSave,
            onRestore: _restoreHabits, // 新增参数
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[100]!, width: 1)),
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
              icon: Icon(Icons.auto_awesome_mosaic_outlined),
              activeIcon: Icon(Icons.auto_awesome_mosaic),
              label: '习惯库',
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
    "天道酬勤，力耕不欺。",
    "今日事，今日毕。",
    "宝剑锋从磨砺出。",
    "慢慢来，比较快。",
    "自律即自由。",
    "每次坚持都算数。",
    "活在当下。",
    "不忘初心，方得始终。",
  ];

  late String currentQuote;

  @override
  void initState() {
    super.initState();
    currentQuote = quotes[Random().nextInt(quotes.length)];
  }

  void _toggleCheckIn(Habit habit) {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    if (habit.checkInTimes.any((t) => t.startsWith(todayStr))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("今日已完成"), duration: Duration(seconds: 1)),
      );
    } else {
      // 创建打卡记录
      final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      final record = CheckInRecord(time: timeStr);
      habit.checkInRecords.add(record);
      widget.onSave();

      // 弹出打卡对话框
      _showEncouragementDialog(habit, record);
    }
  }

  // 打卡对话框 - 优化后的样式
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
                  // 成功图标
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
                  // 标题
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
                  // 备注输入框
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
                  // 完成按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (noteController.text.trim().isNotEmpty) {
                          record.note = noteController.text.trim();
                          widget.onSave();
                        }
                        Navigator.pop(ctx);
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
    int selectedIconIndex = 0; // 新增：选中的图标索引

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
                            child: Icon(HabitIcons.getIcon(selectedIconIndex), color: themeColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "新计划",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "开始一个新的好习惯",
                                  style: TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          // 关闭按钮
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
                      // 图标选择
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "选择图标",
                          style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
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
                      // 习惯名称输入框
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
                          hintText: "例如：早起",
                          labelStyle: TextStyle(color: Colors.grey[600]),
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
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
                          ),
                          errorText: errorText,
                          errorStyle: TextStyle(color: Colors.red[400]),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 描述输入框
                      TextField(
                        controller: descController,
                        maxLines: 2,
                        maxLength: 100,
                        decoration: InputDecoration(
                          labelText: "描述（选填）",
                          hintText: "例如：每天6点前起床",
                          labelStyle: TextStyle(color: Colors.grey[600]),
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
                      // 确认按钮
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (titleController.text.trim().isEmpty) {
                              errorText = "习惯名称不能为空";
                              setModalState(() {});
                            } else {
                              widget.onAdd(Habit(
                                id: DateTime.now().toString(),
                                title: titleController.text.trim(),
                                description: descController.text.trim(),
                                iconIndex: selectedIconIndex, // 新增
                              ));
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text("已添加「${titleController.text.trim()}」"),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check, size: 20),
                          label: const Text("创建习惯", style: TextStyle(fontSize: 16)),
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
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.delete_outline, color: Colors.red[400], size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "删除习惯",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "确定要删除这个习惯吗？",
                            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    // 关闭按钮
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
                // 习惯信息卡片
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
                        child: Icon(Icons.flag_outlined, color: themeColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "已打卡 ${habit.checkInRecords.length} 次",
                              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 警告提示
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
                      Icon(Icons.warning_amber_rounded, color: Colors.red[400], size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "删除后所有打卡记录将一并清除，此操作不可撤销！",
                          style: TextStyle(color: Colors.red[700], fontSize: 13, height: 1.4),
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
                        child: const Text("保留", style: TextStyle(fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onDelete(habit);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text("已删除「${habit.title}」"),
                              duration: const Duration(seconds: 2),
                            ),
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text("雕刀",
                style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w300)),
            centerTitle: true,
            backgroundColor: backgroundColor,
          ),
          SliverToBoxAdapter(
            child: GestureDetector(
              onTap: () => setState(
                      () => currentQuote = quotes[Random().nextInt(quotes.length)]),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                child: Text(
                  currentQuote,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: themeColor.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final habit = widget.habits[index];
                final isTodayDone = habit.checkInTimes.any((t) => t.startsWith(
                    DateFormat('yyyy-MM-dd').format(DateTime.now())));

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => DetailPage(
                          habit: habit,
                          onSave: widget.onSave,
                        ),
                      ),
                    ),
                    onLongPress: () => _deleteHabit(habit),
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isTodayDone
                              ? themeColor.withValues(alpha: 0.4)
                              : Colors.grey[200]!,
                          width: isTodayDone ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // 新增：习惯图标
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isTodayDone
                                  ? themeColor.withValues(alpha: 0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              HabitIcons.getIcon(habit.iconIndex),
                              color: isTodayDone ? themeColor : Colors.grey[500],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(habit.title,
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w400)),
                                if (habit.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    habit.description,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[400]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            isTodayDone
                                ? Icons.check_circle
                                : Icons.radio_button_off,
                            color: isTodayDone ? themeColor : Colors.grey[300],
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: Icon(Icons.add_task, size: 20, color: themeColor),
                            onPressed: () => _toggleCheckIn(habit),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: widget.habits.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        elevation: 2,
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ========== 习惯库页面 ==========
class HabitLibraryPage extends StatelessWidget {
  final Function(Habit) onAddHabit;

  const HabitLibraryPage({super.key, required this.onAddHabit});

  void _showAddDialog(BuildContext context, Map<String, dynamic> template) {
    final titleController = TextEditingController(text: template['title'] as String);
    final descController = TextEditingController(text: template['desc'] as String);
    final themeColor = Theme.of(context).colorScheme.primary;
    String? errorText;

    // 根据模板图标找到对应的索引
    int selectedIconIndex = HabitIcons.icons.indexOf(template['icon'] as IconData);
    if (selectedIconIndex < 0) selectedIconIndex = 0;

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
                            child: Icon(HabitIcons.getIcon(selectedIconIndex), color: themeColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "添加习惯",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "从习惯库添加到我的习惯",
                                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                          // 关闭按钮
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
                      // 图标选择
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "选择图标",
                          style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
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
                      // 习惯名称输入框
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
                          hintText: "例如：早起",
                          labelStyle: TextStyle(color: Colors.grey[600]),
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
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
                          ),
                          errorText: errorText,
                          errorStyle: TextStyle(color: Colors.red[400]),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 描述输入框
                      TextField(
                        controller: descController,
                        maxLines: 2,
                        maxLength: 100,
                        decoration: InputDecoration(
                          labelText: "描述（选填）",
                          hintText: "可以修改描述内容",
                          labelStyle: TextStyle(color: Colors.grey[600]),
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
                      // 确认按钮
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (titleController.text.trim().isEmpty) {
                              errorText = "习惯名称不能为空";
                              setModalState(() {});
                            } else {
                              onAddHabit(Habit(
                                id: DateTime.now().toString(),
                                title: titleController.text.trim(),
                                description: descController.text.trim(),
                                iconIndex: selectedIconIndex,
                              ));
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text("已添加「${titleController.text.trim()}」"),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text("添加到我的习惯", style: TextStyle(fontSize: 16)),
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

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    final templates = [
      // 健康生活
      {'icon': Icons.wb_sunny_outlined, 'title': '早起', 'desc': '每天7点前起床'},
      {'icon': Icons.bedtime_outlined, 'title': '早睡', 'desc': '每天11点前入睡'},
      {'icon': Icons.water_drop_outlined, 'title': '喝水', 'desc': '每天8杯水'},
      {'icon': Icons.fitness_center, 'title': '健身', 'desc': '每天运动30分钟'},
      {'icon': Icons.directions_walk, 'title': '散步', 'desc': '每天步行8000步'},
      {'icon': Icons.directions_run, 'title': '跑步', 'desc': '每天跑步3公里'},
      {'icon': Icons.sports_gymnastics, 'title': '拉伸', 'desc': '每天拉伸15分钟'},
      {'icon': Icons.monitor_weight_outlined, 'title': '记录体重', 'desc': '每天记录体重变化'},

      // 饮食习惯
      {'icon': Icons.free_breakfast_outlined, 'title': '吃早餐', 'desc': '每天按时吃早餐'},
      {'icon': Icons.no_drinks_outlined, 'title': '戒饮料', 'desc': '不喝含糖饮料'},
      {'icon': Icons.apple, 'title': '吃水果', 'desc': '每天吃一份水果'},
      {'icon': Icons.local_dining_outlined, 'title': '细嚼慢咽', 'desc': '专注吃饭不玩手机'},

      // 学习成长
      {'icon': Icons.menu_book_outlined, 'title': '阅读', 'desc': '每天阅读30分钟'},
      {'icon': Icons.translate, 'title': '学英语', 'desc': '每天背10个单词'},
      {'icon': Icons.code, 'title': '写代码', 'desc': '每天编程1小时'},
      {'icon': Icons.headphones_outlined, 'title': '听播客', 'desc': '每天听一期播客'},
      {'icon': Icons.school_outlined, 'title': '上网课', 'desc': '每天学习新知识'},
      {'icon': Icons.piano_outlined, 'title': '练琴', 'desc': '每天练习30分钟'},

      // 心灵成长
      {'icon': Icons.self_improvement, 'title': '冥想', 'desc': '每天冥想10分钟'},
      {'icon': Icons.edit_note, 'title': '写日记', 'desc': '记录每天的心情'},
      {'icon': Icons.favorite_outline, 'title': '感恩', 'desc': '每天记录3件感恩的事'},
      {'icon': Icons.psychology_outlined, 'title': '反思', 'desc': '每天复盘总结'},

      // 生活习惯
      {'icon': Icons.cleaning_services_outlined, 'title': '整理房间', 'desc': '保持环境整洁'},
      {'icon': Icons.checkroom_outlined, 'title': '叠被子', 'desc': '起床后整理床铺'},
      {'icon': Icons.spa_outlined, 'title': '护肤', 'desc': '每天护肤保养'},
      {'icon': Icons.brush_outlined, 'title': '刷牙', 'desc': '早晚各刷一次牙'},
      {'icon': Icons.bathtub_outlined, 'title': '泡脚', 'desc': '睡前泡脚放松'},

      // 社交与情感
      {'icon': Icons.call_outlined, 'title': '联系家人', 'desc': '每周给家人打电话'},
      {'icon': Icons.emoji_emotions_outlined, 'title': '微笑', 'desc': '每天对人微笑'},
      {'icon': Icons.volunteer_activism_outlined, 'title': '帮助他人', 'desc': '每天做一件好事'},

      // 工作效率
      {'icon': Icons.checklist, 'title': '列计划', 'desc': '每天列出待办事项'},
      {'icon': Icons.timer_outlined, 'title': '番茄工作', 'desc': '专注工作25分钟'},
      {'icon': Icons.phone_disabled_outlined, 'title': '少刷手机', 'desc': '每天屏幕时间<3小时'},
      {'icon': Icons.inbox_outlined, 'title': '清空收件箱', 'desc': '每天处理完邮件'},

      // 兴趣爱好
      {'icon': Icons.camera_alt_outlined, 'title': '拍照', 'desc': '每天记录生活瞬间'},
      {'icon': Icons.draw_outlined, 'title': '画画', 'desc': '每天画一幅小画'},
      {'icon': Icons.music_note_outlined, 'title': '听音乐', 'desc': '每天享受音乐时光'},
      {'icon': Icons.local_florist_outlined, 'title': '养植物', 'desc': '每天照顾绿植'},
      {'icon': Icons.cookie_outlined, 'title': '烘焙', 'desc': '每周尝试新食谱'},

      // 抽象彩蛋
      {'icon': Icons.flight_takeoff, 'title': '起飞', 'desc': '航班不可延误'},
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text("习惯库",
                style:
                TextStyle(letterSpacing: 2, fontWeight: FontWeight.w300)),
            centerTitle: true,
            backgroundColor: backgroundColor,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text("点击添加到我的习惯",
                  style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final t = templates[index];
                  return GestureDetector(
                    onTap: () => _showAddDialog(context, t),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(t['icon'] as IconData,
                              color: themeColor, size: 26),
                          const Spacer(),
                          Text(t['title'] as String,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(t['desc'] as String,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[400]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  );
                },
                childCount: templates.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ========== 我的页面 ==========
class ProfilePage extends StatelessWidget {
  final List<Habit> habits;
  final VoidCallback onSave;
  final Function(List<Habit>) onRestore;

  const ProfilePage({super.key, required this.habits, required this.onSave, required this.onRestore,});

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    int totalCheckIns = habits.fold(0, (sum, h) => sum + h.checkInTimes.length);
    int todayCheckIns = habits
        .where((h) => h.checkInTimes.any((t) =>
        t.startsWith(DateFormat('yyyy-MM-dd').format(DateTime.now()))))
        .length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text("我的",
                style:
                TextStyle(letterSpacing: 2, fontWeight: FontWeight.w300)),
            centerTitle: true,
            backgroundColor: backgroundColor,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 统计卡片
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statItem("习惯数", habits.length.toString(), themeColor),
                        Container(
                            width: 1, height: 40, color: Colors.grey[200]),
                        _statItem("今日完成", todayCheckIns.toString(), themeColor),
                        Container(
                            width: 1, height: 40, color: Colors.grey[200]),
                        _statItem("累计打卡", totalCheckIns.toString(), themeColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _menuItem(context, Icons.notifications_none, "提醒设置",
                      ReminderSettingsPage(habits: habits, onSave: onSave)),
                  _menuItem(context, Icons.color_lens_outlined, "主题设置",
                      const ThemeSettingsPage()),
                  _menuItem(context, Icons.cloud_outlined, "数据备份", BackupPage(habits: habits, onRestore: onRestore)),
                  _menuItem(
                      context, Icons.info_outline, "关于", const AboutPage()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w300, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      ],
    );
  }

  Widget _menuItem(
      BuildContext context, IconData icon, String title, Widget? page) {
    final themeColor = Theme.of(context).colorScheme.primary;
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
                  duration: const Duration(seconds: 1)),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
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

  String _generateFileName() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);
    return 'habit_backup_$dateStr.json';
  }

  Map<String, dynamic> _generateBackupData() {
    return {
      'version': '1.0',
      'appName': '雕刀',
      'backupTime': DateTime.now().toIso8601String(),
      'habitsCount': widget.habits.length,
      'habits': widget.habits.map((h) => h.toJson()).toList(),
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

      final backupData = _generateBackupData();
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

// 新增：导出成功弹窗
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
                // 成功图标
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
                // 标题
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
                // 文件路径
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
                            style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
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
                // 确认按钮
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
      final backupData = _generateBackupData();
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

      if (mounted) {
        final backupTime = data['backupTime'] != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(data['backupTime']))
            : '未知';

        _showImportConfirmDialog(habits, backupTime);
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

// 新增：导入确认弹窗
  void _showImportConfirmDialog(List<Habit> habits, String backupTime) {
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
                    // 关闭按钮
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
                // 备份信息卡片
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
                      _buildStatItem("习惯数量", "${habits.length} 个", themeColor),
                      Container(width: 1, height: 40, color: themeColor.withValues(alpha: 0.2)),
                      _buildStatItem("打卡记录", "$totalCheckIns 次", themeColor),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 警告提示
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
                        child: const Text("取消", style: TextStyle(fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          widget.onRestore(habits);
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

// 新增：恢复成功弹窗
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
                // 成功图标
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
                // 标题
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
                // 确认按钮
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

// 辅助方法：构建统计项
  Widget _buildStatItem(String label, String value, Color color) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("数据备份", style: TextStyle(fontSize: 16)),
        backgroundColor: backgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.folder_outlined, size: 40, color: themeColor),
                const SizedBox(height: 12),
                Text("当前数据", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text(
                  "${widget.habits.length} 个习惯",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: themeColor),
                ),
                Text(
                  "${widget.habits.fold(0, (sum, h) => sum + h.checkInTimes.length)} 次打卡记录",
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text("导出备份", style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          _buildActionCard(
            icon: Icons.download_outlined,
            title: "保存到本地",
            subtitle: "将备份文件保存到下载目录",
            color: themeColor,
            isLoading: _isExporting,
            onTap: _exportToLocal,
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            icon: Icons.share_outlined,
            title: "分享备份文件",
            subtitle: "通过微信、邮件等方式分享",
            color: themeColor,
            isLoading: _isExporting,
            onTap: _shareBackup,
          ),
          const SizedBox(height: 24),
          Text("导入备份", style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          _buildActionCard(
            icon: Icons.upload_outlined,
            title: "从文件恢复",
            subtitle: "选择备份文件恢复数据",
            color: Colors.orange,
            isLoading: _isImporting,
            onTap: _importBackup,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text("备份说明", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700])),
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
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
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
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
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
      child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
    );
  }
}

// ========== 主题设置页面 ==========
class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = HabitApp.of(context);
    final currentTheme = appState?.currentTheme;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("主题设置", style: TextStyle(fontSize: 16)),
        backgroundColor: backgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: currentTheme?.backgroundColor ?? Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("预览效果",
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                      (currentTheme?.color ?? Colors.grey).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("示例习惯",
                                style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text("每天坚持",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[400])),
                          ],
                        ),
                      ),
                      Icon(Icons.check_circle,
                          color: currentTheme?.color ?? Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text("选择主题颜色",
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          ...ThemeConfig.colorOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = currentTheme?.name == option.name;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => appState?.setThemeColor(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? option.color : Colors.grey[200]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: option.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                            color: Colors.white, size: 22)
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
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: List.generate(4, (i) {
                                return Container(
                                  width: 20,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: option.color
                                        .withValues(alpha: 0.25 + i * 0.25),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: option.color, size: 24),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ========== 提醒设置页面 ==========
class ReminderSettingsPage extends StatefulWidget {
  final List<Habit> habits;
  final VoidCallback onSave;

  const ReminderSettingsPage(
      {super.key, required this.habits, required this.onSave});

  @override
  State<ReminderSettingsPage> createState() => _ReminderSettingsPageState();
}

class _ReminderSettingsPageState extends State<ReminderSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("提醒设置", style: TextStyle(fontSize: 16)),
        backgroundColor: backgroundColor,
      ),
      body: widget.habits.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text("暂无习惯", style: TextStyle(color: Colors.grey[400])),
          ],
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
              color: themeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
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
          ...widget.habits.map((habit) => _buildHabitCard(habit, themeColor)),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Habit habit, Color themeColor) {
    final hasReminder = habit.reminderTime != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasReminder
              ? themeColor.withValues(alpha: 0.3)
              : Colors.grey[200]!,
        ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, time.hour, time.minute);

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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("删除提醒", style: TextStyle(fontSize: 16)),
        content: Text(
          "确定要删除「${habit.title}」的提醒吗？\n\n注意：日历中的事件需要手动删除",
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("取消", style: TextStyle(color: Colors.grey[500])),
          ),
          TextButton(
            onPressed: () {
              setState(() => habit.reminderTime = null);
              widget.onSave();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("已删除提醒"),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text("删除", style: TextStyle(color: Colors.red)),
          ),
        ],
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("已为「${habit.title}」设置提醒"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("打开日历失败: $e")),
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
    _minuteController = FixedExtentScrollController(initialItem: _selectedMinute);
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
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("关于", style: TextStyle(fontSize: 16)),
        backgroundColor: backgroundColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: themeColor.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/images/ic_launcher.png',
                    fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),
            const Text("雕刀",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 4)),
            const SizedBox(height: 8),
            Text("版本 1.6.5",
                style: TextStyle(fontSize: 14, color: Colors.grey[400])),
            const SizedBox(height: 30),
            Text("用极简的方式，雕刻更好的自己",
                style: TextStyle(fontSize: 14, color: Colors.grey[500])),
            const SizedBox(height: 50),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _infoRow("开发者", "Vence的猫"),
                  const Divider(height: 20),
                  _infoRow("联系邮箱", "vence_cat@163.com"),
                  const Divider(height: 20),
                  _infoRow("更新时间", "2026年1月4日"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        Text(value,
            style: const TextStyle(fontSize: 14, color: Colors.black87)),
      ],
    );
  }
}

// ========== 详情页 ==========
class DetailPage extends StatefulWidget {
  final Habit habit;
  final VoidCallback onSave;

  const DetailPage({super.key, required this.habit, required this.onSave});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late PageController _pageController;
  late DateTime _currentMonth;
  DateTime? _selectedDate; // 新增：选中的日期

  static const int _initialPage = 1200;

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
    _selectedDate = DateTime.now(); // 默认选中今天
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

  // 新增：获取选中日期的打卡记录
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text("习惯详情", style: TextStyle(fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildInfoCard(themeColor),
          const SizedBox(height: 24),
          _buildCalendarCard(themeColor),
          const SizedBox(height: 24),
          _buildRecordHeader(themeColor),
          const SizedBox(height: 12),
          _buildRecordList(themeColor),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: themeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 修改：使用习惯自己的图标
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
              // 编辑按钮
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
                    style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem("累计打卡", "${widget.habit.checkInRecords.length}次", themeColor),
                Container(width: 1, height: 30, color: themeColor.withValues(alpha: 0.2)),
                _statItem("连续天数", "${_calculateStreak()}天", themeColor),
                Container(width: 1, height: 30, color: themeColor.withValues(alpha: 0.2)),
                _statItem("本月打卡", "${_getMonthCheckIns()}天", themeColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

// 新增：编辑习惯对话框
  void _showEditHabitDialog() {
    final titleController = TextEditingController(text: widget.habit.title);
    final descController = TextEditingController(text: widget.habit.description);
    final themeColor = Theme.of(context).colorScheme.primary;
    int selectedIconIndex = widget.habit.iconIndex;

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
                            child: Icon(HabitIcons.getIcon(selectedIconIndex), color: themeColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "编辑习惯",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ),
                          // 关闭按钮
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
                      // 图标选择
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "选择图标",
                          style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
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
                      // 习惯名称输入框
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: "习惯名称",
                          hintText: "例如：早起",
                          labelStyle: TextStyle(color: Colors.grey[600]),
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
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 描述输入框
                      TextField(
                        controller: descController,
                        maxLines: 2,
                        maxLength: 100,
                        decoration: InputDecoration(
                          labelText: "描述（选填）",
                          hintText: "例如：每天6点前起床",
                          labelStyle: TextStyle(color: Colors.grey[600]),
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
                      // 保存按钮
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (titleController.text.trim().isNotEmpty) {
                              setState(() {
                                widget.habit.title = titleController.text.trim();
                                widget.habit.description = descController.text.trim();
                                widget.habit.iconIndex = selectedIconIndex;
                              });
                              widget.onSave();
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("已保存修改"),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text("习惯名称不能为空"),
                                  duration: Duration(seconds: 1),
                                ),
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
                          child: const Text("保存修改", style: TextStyle(fontSize: 16)),
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

  Widget _buildCalendarCard(Color themeColor) {
    int getRowCount(DateTime month) {
      final firstDayOfMonth = DateTime(month.year, month.month, 1);
      final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
      final daysInMonth = lastDayOfMonth.day;
      final firstWeekday = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
      return ((firstWeekday + daysInMonth) / 7).ceil();
    }

    final rowCount = getRowCount(_currentMonth);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
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
                        fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[700])),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text("今天", style: TextStyle(fontSize: 12, color: themeColor)),
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                final calendarHeight = rowCount * cellHeight + (rowCount - 1) * 4;

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
    final firstWeekday = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
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
        final isToday =
            date.year == today.year && date.month == today.month && date.day == today.day;
        final isCheckedIn = _checkInDates.contains(dateStr);
        final isFuture = date.isAfter(today);

        // 新增：判断是否选中
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
                    fontWeight: isToday || isCheckedIn || isSelected ? FontWeight.w600 : FontWeight.normal,
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
                      decoration: BoxDecoration(color: themeColor, shape: BoxShape.circle),
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

  // 修改：显示选中日期的标题
  Widget _buildRecordHeader(Color themeColor) {
    final records = _selectedDateRecords;
    final hasRecord = records.isNotEmpty;

    // 判断是否是补卡记录
    final isMakeUp = hasRecord &&
        records.any((r) => r.note != null && r.note!.contains("[补卡于"));

    return Row(
      children: [
        Icon(Icons.article_outlined, color: themeColor, size: 20),
        const SizedBox(width: 8),
        Text(
          "打卡日志",
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[700]),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: hasRecord
                ? isMakeUp
                ? Colors.orange.withValues(alpha: 0.1)
                : themeColor.withValues(alpha: 0.1)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            hasRecord
                ? isMakeUp
                ? "已补卡"
                : "已打卡"
                : "未打卡",
            style: TextStyle(
              fontSize: 12,
              color: hasRecord
                  ? isMakeUp
                  ? Colors.orange
                  : themeColor
                  : Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // 修改：只显示选中日期的打卡记录
  Widget _buildRecordList(Color themeColor) {
    final records = _selectedDateRecords;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final isFuture = _selectedDate != null &&
        DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day).isAfter(today);
    final isToday = _selectedDate != null &&
        DateFormat('yyyy-MM-dd').format(_selectedDate!) ==
            DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isPast = _selectedDate != null &&
        DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day).isBefore(today);

    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(
              isFuture ? Icons.schedule_outlined : Icons.event_busy_outlined,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isFuture
                  ? "这是未来的日期"
                  : "这天没有打卡记录",
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

    return Column(
      children: records.reversed.map((record) {
        final dateTime = DateTime.parse(record.time);
        final isMakeUp = record.note != null && record.note!.contains("[补卡于");

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMakeUp
                  ? Colors.orange.withValues(alpha: 0.3)
                  : themeColor.withValues(alpha: 0.3),
            ),
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
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _extractMakeUpTime(record.note!),
                                  style: const TextStyle(fontSize: 10, color: Colors.orange),
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
      }).toList(),
    );
  }

// 新增：提取补卡时间
  String _extractMakeUpTime(String note) {
    final regex = RegExp(r'\[补卡于(.+?)\]');
    final match = regex.firstMatch(note);
    if (match != null) {
      return "补于${match.group(1)}";
    }
    return "补签";
  }

// 新增：构建备注区域
  Widget _buildNoteSection(CheckInRecord record, bool isMakeUp, Color themeColor) {
    if (record.note == null || record.note!.isEmpty) {
      return const SizedBox.shrink();
    }

    // 处理显示的备注内容，去掉补卡标记
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

// 新增：补卡对话框
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
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.history, color: Colors.orange, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "补卡",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedDateStr,
                              style: const TextStyle(fontSize: 14, color: Colors.orange),
                            ),
                          ],
                        ),
                      ),
                      // 关闭按钮
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
                  const SizedBox(height: 20),
                  // 输入框
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    maxLength: 100,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "写点什么记录一下吧...",
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
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
                  // 确认按钮
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
                      child: const Text("确认补卡", style: TextStyle(fontSize: 16)),
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

// 新增：执行补卡
  void _performMakeUpCheckIn(String note) {
    // 记录当前的完整时间，但存储到选中的日期
    final now = DateTime.now();

    // 存储时使用选中的日期（用于归类到那一天）
    final makeUpTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      now.hour,
      now.minute,
      now.second,
    );

    final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(makeUpTime);

    // 在备注中记录实际补卡的日期时间
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("已补卡 ${DateFormat('MM月dd日').format(_selectedDate!)}"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 编辑备注 - 优化后的样式
  void _editNote(CheckInRecord record) {
    // 处理备注内容，保留补卡标记但只编辑用户备注部分
    String originalNote = record.note ?? '';
    String makeUpPrefix = '';
    String userNote = originalNote;

    // 检查是否有补卡标记
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
                        child: Icon(Icons.edit_note, color: themeColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "编辑备注",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateStr,
                              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                      // 关闭按钮
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
                  // 备注输入框
                  TextField(
                    controller: noteController,
                    maxLines: 4,
                    maxLength: 100,
                    autofocus: true,
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
                  // 按钮区域
                  Row(
                    children: [
                      // 删除按钮（如果有备注内容才显示）
                      if (userNote.isNotEmpty)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // 如果有补卡标记，只保留标记
                              if (makeUpPrefix.isNotEmpty) {
                                record.note = makeUpPrefix;
                              } else {
                                record.note = null;
                              }
                              widget.onSave();
                              setState(() {});
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("已删除备注"),
                                  duration: Duration(seconds: 1),
                                ),
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
                            child: const Text("删除备注", style: TextStyle(fontSize: 15)),
                          ),
                        ),
                      if (userNote.isNotEmpty) const SizedBox(width: 12),
                      // 保存按钮
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            String newNote = noteController.text.trim();

                            // 如果有补卡标记，需要保留
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("已保存备注"),
                                duration: Duration(seconds: 1),
                              ),
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
                          child: const Text("保存备注", style: TextStyle(fontSize: 15)),
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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }
}