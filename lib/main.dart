import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:math';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      backgroundColor: Color(0xFFF5F7),
    ),
    ThemeColorOption(
      name: '薄荷青',
      color: Color(0xFF26C6DA),
      backgroundColor: Color(0xFFF5FBFC),
    ),
    ThemeColorOption(
      name: '沉稳黑',
      color: Color(0xFF455A64),
      backgroundColor: Color(0xFFF5F5F5),
    ),
  ];
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

// 数据模型
class Habit {
  String id;
  String title;
  String description;
  List<String> checkInTimes;
  String? reminderTime;
  String createdAt;

  Habit({
    required this.id,
    required this.title,
    this.description = '',
    required this.checkInTimes,
    this.reminderTime,
    String? createdAt,
  }) : createdAt = createdAt ?? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'checkInTimes': checkInTimes,
    'reminderTime': reminderTime,
    'createdAt': createdAt,
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'],
    title: json['title'],
    description: json['description'] ?? '',
    checkInTimes: List<String>.from(json['checkInTimes'] ?? []),
    reminderTime: json['reminderTime'],
    createdAt: json['createdAt'],
  );
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
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('simple_habits', jsonEncode(habits));
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
          ProfilePage(habits: habits, onSave: _refreshAndSave),
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
      habit.checkInTimes.add(DateFormat('yyyy-MM-dd HH:mm:ss').format(now));
      widget.onSave();
    }
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final themeColor = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("新计划", style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "习惯名称",
                hintText: "例如：早起",
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: "描述（选填）",
                hintText: "例如：每天6点前起床",
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("取消", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                widget.onAdd(Habit(
                  id: DateTime.now().toString(),
                  title: titleController.text,
                  description: descController.text,
                  checkInTimes: [],
                ));
              }
              Navigator.pop(ctx);
            },
            child: Text("确认", style: TextStyle(color: themeColor)),
          ),
        ],
      ),
    );
  }

  void _deleteHabit(Habit habit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text("放弃这个习惯吗？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("保留"),
          ),
          TextButton(
            onPressed: () {
              widget.onDelete(habit);
              Navigator.pop(ctx);
            },
            child: const Text("放弃", style: TextStyle(color: Colors.red)),
          ),
        ],
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
                style:
                TextStyle(letterSpacing: 4, fontWeight: FontWeight.w300)),
            centerTitle: true,
            backgroundColor: backgroundColor,
          ),
          SliverToBoxAdapter(
            child: GestureDetector(
              onTap: () => setState(
                      () => currentQuote = quotes[Random().nextInt(quotes.length)]),
              child: Container(
                padding:
                const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                child: Text(
                  currentQuote,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: themeColor.withOpacity(0.6),
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (c) => DetailPage(habit: habit)),
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
                              ? themeColor.withOpacity(0.4)
                              : Colors.grey[200]!,
                          width: isTodayDone ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(habit.title,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400)),
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
                            icon: Icon(Icons.add_task,
                                size: 20, color: themeColor),
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

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    final templates = [
      {'icon': Icons.wb_sunny_outlined, 'title': '早起', 'desc': '每天6点前起床'},
      {'icon': Icons.fitness_center, 'title': '健身', 'desc': '每天运动30分钟'},
      {'icon': Icons.menu_book_outlined, 'title': '阅读', 'desc': '每天阅读30分钟'},
      {'icon': Icons.water_drop_outlined, 'title': '喝水', 'desc': '每天8杯水'},
      {'icon': Icons.self_improvement, 'title': '冥想', 'desc': '每天冥想10分钟'},
      {'icon': Icons.bedtime_outlined, 'title': '早睡', 'desc': '每天11点前入睡'},
      {'icon': Icons.edit_note, 'title': '写日记', 'desc': '记录每天的心情'},
      {'icon': Icons.directions_walk, 'title': '散步', 'desc': '每天步行8000步'},
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
                childAspectRatio: 1.3,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final t = templates[index];
                  return GestureDetector(
                    onTap: () {
                      onAddHabit(Habit(
                        id: DateTime.now().toString(),
                        title: t['title'] as String,
                        description: t['desc'] as String,
                        checkInTimes: [],
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("已添加「${t['title']}」"),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
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
                                  fontSize: 11, color: Colors.grey[400])),
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

  const ProfilePage({super.key, required this.habits, required this.onSave});

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
                  _menuItem(context, Icons.cloud_outlined, "数据备份", null),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: themeColor, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 15)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[300], size: 20),
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
      ),
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
                                        .withOpacity(0.25 + i * 0.25),
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
          const SizedBox(height: 24),
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
                      (currentTheme?.color ?? Colors.grey).withOpacity(0.4),
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
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: widget.habits.length,
        itemBuilder: (context, index) {
          final habit = widget.habits[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(habit.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                    if (habit.reminderTime != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          habit.reminderTime!,
                          style: TextStyle(
                              fontSize: 13,
                              color: themeColor,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() => habit.reminderTime =
                            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
                            widget.onSave();
                          }
                        },
                        icon: const Icon(Icons.schedule, size: 18),
                        label: Text(
                            habit.reminderTime == null ? "设置提醒" : "修改时间"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: themeColor,
                          side: BorderSide(
                              color: themeColor.withOpacity(0.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: habit.reminderTime != null
                            ? () => _addToCalendar(habit)
                            : null,
                        icon: const Icon(Icons.calendar_month, size: 18),
                        label: const Text("添加日历"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[200],
                        ),
                      ),
                    ),
                  ],
                ),
                if (habit.reminderTime != null)
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() => habit.reminderTime = null);
                        widget.onSave();
                      },
                      child: Text("清除提醒",
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 12)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _addToCalendar(Habit habit) {
    if (habit.reminderTime == null) return;

    final parts = habit.reminderTime!.split(':');
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1,
        int.parse(parts[0]), int.parse(parts[1]));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("添加到日历", style: TextStyle(fontSize: 16)),
        content: Text("将「${habit.title}」添加到系统日历？\n提醒时间：${habit.reminderTime}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("取消", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openCalendarIntent(habit, tomorrow);
            },
            child: Text("确认",
                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
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
                      color: themeColor.withOpacity(0.3),
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
            Text("版本 1.1.1",
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
                  _infoRow("更新日期", "2025年12月"),
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
class DetailPage extends StatelessWidget {
  final Habit habit;
  const DetailPage({super.key, required this.habit});

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
          // ===== 习惯信息卡片 =====
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: themeColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 习惯名称
                Row(
                  children: [
                    Icon(Icons.flag_outlined, color: themeColor, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        habit.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                // 习惯描述
                if (habit.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes_outlined,
                          color: Colors.grey[400], size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          habit.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // 创建时间
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.access_time_outlined,
                        color: Colors.grey[400], size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "创建于 ${_formatCreatedAt(habit.createdAt)}",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),

                // 统计信息
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem(
                          "累计打卡", "${habit.checkInTimes.length}次", themeColor),
                      Container(
                          width: 1,
                          height: 30,
                          color: themeColor.withOpacity(0.2)),
                      _statItem("连续天数", "${_calculateStreak()}天", themeColor),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ===== 打卡记录标题 =====
          Row(
            children: [
              Icon(Icons.history, color: themeColor, size: 20),
              const SizedBox(width: 8),
              Text(
                "打卡记录",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              Text(
                "共 ${habit.checkInTimes.length} 次",
                style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ===== 打卡记录列表 =====
          if (habit.checkInTimes.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.event_available, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("暂无打卡记录",
                      style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(height: 8),
                  Text("快去完成第一次打卡吧！",
                      style: TextStyle(fontSize: 12, color: Colors.grey[300])),
                ],
              ),
            )
          else
            ...habit.checkInTimes.reversed.map((timeStr) {
              final dateTime = DateTime.parse(timeStr);
              final isToday = DateFormat('yyyy-MM-dd').format(dateTime) ==
                  DateFormat('yyyy-MM-dd').format(DateTime.now());

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isToday
                        ? themeColor.withOpacity(0.4)
                        : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isToday ? themeColor : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('yyyy年MM月dd日').format(dateTime),
                            style: TextStyle(
                              fontSize: 14,
                              color: isToday ? themeColor : Colors.grey[700],
                              fontWeight:
                              isToday ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('HH:mm:ss').format(dateTime),
                            style:
                            TextStyle(fontSize: 12, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                    if (isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "今天",
                          style: TextStyle(
                              fontSize: 12,
                              color: themeColor,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),

          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // 格式化创建时间
  String _formatCreatedAt(String createdAt) {
    try {
      final dateTime = DateTime.parse(createdAt);
      return DateFormat('yyyy年MM月dd日').format(dateTime);
    } catch (e) {
      return createdAt;
    }
  }

  // 计算连续打卡天数
  int _calculateStreak() {
    if (habit.checkInTimes.isEmpty) return 0;

    final Set<String> checkInDates = habit.checkInTimes
        .map((t) => DateFormat('yyyy-MM-dd').format(DateTime.parse(t)))
        .toSet();

    int streak = 0;
    DateTime currentDate = DateTime.now();

    // 检查今天是否打卡，如果没有就从昨天开始算
    String todayStr = DateFormat('yyyy-MM-dd').format(currentDate);
    if (!checkInDates.contains(todayStr)) {
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    // 往前数连续的天数
    while (true) {
      String dateStr = DateFormat('yyyy-MM-dd').format(currentDate);
      if (checkInDates.contains(dateStr)) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }
}