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
      backgroundColor: Color(0xFFFCF5F7),
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

// 数据模型 - 替换原有的 Habit 类，并新增 CheckInRecord 类
class Habit {
  String id;
  String title;
  String description;
  List<CheckInRecord> checkInRecords; // 修改：使用记录对象
  String? reminderTime;
  String createdAt;

  Habit({
    required this.id,
    required this.title,
    this.description = '',
    List<CheckInRecord>? checkInRecords,
    this.reminderTime,
    String? createdAt,
  }) : checkInRecords = checkInRecords ?? [],
        createdAt = createdAt ?? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  // 兼容性：获取打卡时间列表
  List<String> get checkInTimes => checkInRecords.map((r) => r.time).toList();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'checkInRecords': checkInRecords.map((r) => r.toJson()).toList(),
    'reminderTime': reminderTime,
    'createdAt': createdAt,
  };

  factory Habit.fromJson(Map<String, dynamic> json) {
    // 兼容旧数据格式
    List<CheckInRecord> records = [];
    if (json['checkInRecords'] != null) {
      records = (json['checkInRecords'] as List)
          .map((r) => CheckInRecord.fromJson(r as Map<String, dynamic>))
          .toList();
    } else if (json['checkInTimes'] != null) {
      // 旧数据迁移：将字符串列表转换为 CheckInRecord 列表
      records = (json['checkInTimes'] as List)
          .map((t) => CheckInRecord(time: t as String))
          .toList();
    }

    return Habit(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      checkInRecords: records,
      reminderTime: json['reminderTime'],
      createdAt: json['createdAt'],
    );
  }
}

// 新增：打卡记录模型
class CheckInRecord {
  String time;
  String? note; // 鼓励语

  CheckInRecord({
    required this.time,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'time': time,
    'note': note,
  };

  factory CheckInRecord.fromJson(Map<String, dynamic> json) => CheckInRecord(
    time: json['time'],
    note: json['note'],
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

      // 弹出鼓励语对话框
      _showEncouragementDialog(habit, record);
    }
  }

  // 新增：鼓励语对话框
  void _showEncouragementDialog(Habit habit, CheckInRecord record) {
    final noteController = TextEditingController();
    final themeColor = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      barrierDismissible: false,
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
              child: Icon(Icons.celebration, color: themeColor, size: 30),
            ),
            const SizedBox(height: 12),
            const Text("打卡成功！", style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "「${habit.title}」已完成",
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 3,
              maxLength: 100,
              decoration: InputDecoration(
                hintText: "写点什么鼓励自己吧...",
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
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              if (noteController.text.trim().isNotEmpty) {
                record.note = noteController.text.trim();
                widget.onSave();
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text("完成"),
          ),
        ],
      ),
    );
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
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: "描述（选填）",
                hintText: "例如：每天6点前起床",
                isDense: true,
              ),
              maxLines: null,
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
        contentPadding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 12),
        actionsPadding: const EdgeInsets.only(bottom: 8),
        actionsAlignment: MainAxisAlignment.center,
        content: const Text(
          "放弃这个习惯吗？",
          textAlign: TextAlign.center,
        ),
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(template['icon'] as IconData, color: themeColor, size: 22),
            const SizedBox(width: 10),
            const Text("添加习惯", style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "习惯名称",
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: "描述",
                hintText: "可以修改描述内容",
                isDense: true,
              ),
              maxLines: null,
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
                onAddHabit(Habit(
                  id: DateTime.now().toString(),
                  title: titleController.text,
                  description: descController.text,
                ));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("已添加「${titleController.text}」"),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            child: Text("添加", style: TextStyle(color: themeColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    final templates = [
      // 健康生活
      {'icon': Icons.wb_sunny_outlined, 'title': '早起', 'desc': '每天6点前起床'},
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
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[400], size: 24),
                const SizedBox(width: 10),
                const Text("导出成功", style: TextStyle(fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("文件已保存到：", style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(file.path, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("确定"),
              ),
            ],
          ),
        );
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

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("确认恢复", style: TextStyle(fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("备份时间：$backupTime"),
                const SizedBox(height: 8),
                Text("习惯数量：${habits.length} 个"),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "恢复将覆盖当前所有数据！",
                          style: TextStyle(color: Colors.orange[700], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
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
                  Navigator.pop(ctx);
                  widget.onRestore(habits);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("已恢复 ${habits.length} 个习惯"),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text("确认恢复", style: TextStyle(color: Colors.orange)),
              ),
            ],
          ),
        );
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
          // 预览效果（移到最上方）
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
                          color: themeColor.withValues(alpha: 0.1),
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
                              color: themeColor.withValues(alpha: 0.5)),
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
            Text("版本 1.4.4",
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
                  _infoRow("更新时间", "2025年12月27日"),
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

// ========== 详情页 ========== 替换整个 DetailPage 类
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
              Icon(Icons.flag_outlined, color: themeColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.habit.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
                _buildTodayLegend(themeColor),
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

        return Container(
          decoration: BoxDecoration(
            color: isCheckedIn ? themeColor.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isToday ? Border.all(color: themeColor, width: 2) : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '$dayNumber',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isToday || isCheckedIn ? FontWeight.w600 : FontWeight.normal,
                  color: isFuture
                      ? Colors.grey[300]
                      : isCheckedIn
                      ? themeColor
                      : Colors.grey[700],
                ),
              ),
              if (isCheckedIn)
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

  Widget _buildTodayLegend(Color themeColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            border: Border.all(color: themeColor, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text("今天", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildRecordHeader(Color themeColor) {
    return Row(
      children: [
        Icon(Icons.history, color: themeColor, size: 20),
        const SizedBox(width: 8),
        Text("打卡记录",
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[700])),
        const Spacer(),
        Text("共 ${widget.habit.checkInRecords.length} 次",
            style: TextStyle(fontSize: 13, color: Colors.grey[400])),
      ],
    );
  }

  // 修改：打卡记录列表，显示鼓励语
  Widget _buildRecordList(Color themeColor) {
    if (widget.habit.checkInRecords.isEmpty) {
      return Container(
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
            Text("暂无打卡记录", style: TextStyle(color: Colors.grey[400])),
            const SizedBox(height: 8),
            Text("快去完成第一次打卡吧！",
                style: TextStyle(fontSize: 12, color: Colors.grey[300])),
          ],
        ),
      );
    }

    return Column(
      children: widget.habit.checkInRecords.reversed.map((record) {
        final dateTime = DateTime.parse(record.time);
        final isToday = DateFormat('yyyy-MM-dd').format(dateTime) ==
            DateFormat('yyyy-MM-dd').format(DateTime.now());

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isToday ? themeColor.withValues(alpha: 0.4) : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                            fontWeight: isToday ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('HH:mm:ss').format(dateTime),
                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "今天",
                        style: TextStyle(
                            fontSize: 12, color: themeColor, fontWeight: FontWeight.w500),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // 编辑按钮
                  GestureDetector(
                    onTap: () => _editNote(record),
                    child: Icon(
                      record.note != null && record.note!.isNotEmpty
                          ? Icons.edit_note
                          : Icons.add_comment_outlined,
                      size: 20,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              // 显示鼓励语
              if (record.note != null && record.note!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: themeColor.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.format_quote,
                          size: 16, color: themeColor.withValues(alpha: 0.5)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          record.note!,
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
            ],
          ),
        );
      }).toList(),
    );
  }

  // 编辑鼓励语
  void _editNote(CheckInRecord record) {
    final noteController = TextEditingController(text: record.note ?? '');
    final themeColor = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("编辑鼓励语", style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          maxLength: 100,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "写点什么鼓励自己...",
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        actions: [
          if (record.note != null && record.note!.isNotEmpty)
            TextButton(
              onPressed: () {
                record.note = null;
                widget.onSave();
                setState(() {});
                Navigator.pop(ctx);
              },
              child: const Text("删除", style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("取消", style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () {
              if (noteController.text.trim().isNotEmpty) {
                record.note = noteController.text.trim();
              } else {
                record.note = null;
              }
              widget.onSave();
              setState(() {});
              Navigator.pop(ctx);
            },
            child: Text("保存", style: TextStyle(color: themeColor)),
          ),
        ],
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