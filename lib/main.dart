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

// 成就数据类
class Achievement {
  final IconData icon;
  final String title;
  final String description;
  final bool isUnlocked;
  final double progress;
  final int current;
  final int target;
  final String category;

  const Achievement({
    required this.icon,
    required this.title,
    required this.description,
    required this.isUnlocked,
    required this.progress,
    required this.current,
    required this.target,
    required this.category,
  });
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

// 习惯图标配置 - 分类版本
class HabitIcons {
  // 图标分类数据
  static const List<IconCategory> categories = [
    IconCategory(
      name: '常用',
      icon: Icons.star_outline,
      icons: [
        Icons.flag_outlined,
        Icons.star_outline,
        Icons.favorite_outline,
        Icons.bookmark_outline,
        Icons.push_pin_outlined,
        Icons.lightbulb_outline,
        Icons.check_circle_outline,
        Icons.radio_button_checked,
        Icons.task_alt_outlined,
        Icons.verified_outlined,
        Icons.thumb_up_outlined,
        Icons.grade_outlined,
      ],
    ),
    IconCategory(
      name: '时间',
      icon: Icons.schedule_outlined,
      icons: [
        Icons.wb_sunny_outlined,
        Icons.bedtime_outlined,
        Icons.alarm_outlined,
        Icons.timer_outlined,
        Icons.schedule_outlined,
        Icons.nightlight_outlined,
        Icons.wb_twilight_outlined,
        Icons.hourglass_empty_outlined,
        Icons.update_outlined,
        Icons.history_outlined,
      ],
    ),
    IconCategory(
      name: '运动',
      icon: Icons.fitness_center,
      icons: [
        Icons.fitness_center,
        Icons.directions_run,
        Icons.directions_walk,
        Icons.sports_gymnastics,
        Icons.pool_outlined,
        Icons.pedal_bike_outlined,
        Icons.skateboarding_outlined,
        Icons.surfing_outlined,
        Icons.hiking_outlined,
        Icons.sports_martial_arts,
        Icons.sports_soccer_outlined,
        Icons.sports_basketball_outlined,
        Icons.sports_tennis_outlined,
        Icons.sports_golf_outlined,
        Icons.sports_baseball_outlined,
        Icons.snowboarding_outlined,
        Icons.downhill_skiing_outlined,
        Icons.rowing_outlined,
        Icons.kayaking_outlined,
        Icons.sports_handball_outlined,
        Icons.sports_volleyball_outlined,
        Icons.sports_cricket_outlined,
        Icons.sports_rugby_outlined,
        Icons.sports_kabaddi_outlined,
        Icons.sports_mma_outlined,
      ],
    ),
    IconCategory(
      name: '饮食',
      icon: Icons.restaurant_outlined,
      icons: [
        Icons.water_drop_outlined,
        Icons.local_drink_outlined,
        Icons.coffee_outlined,
        Icons.local_cafe_outlined,
        Icons.free_breakfast_outlined,
        Icons.wine_bar_outlined,
        Icons.no_drinks_outlined,
        Icons.restaurant_outlined,
        Icons.apple,
        Icons.egg_outlined,
        Icons.rice_bowl_outlined,
        Icons.ramen_dining_outlined,
        Icons.lunch_dining_outlined,
        Icons.dinner_dining_outlined,
        Icons.bakery_dining_outlined,
        Icons.icecream_outlined,
        Icons.cookie_outlined,
        Icons.cake_outlined,
        Icons.local_pizza_outlined,
        Icons.set_meal_outlined,
        Icons.no_food_outlined,
        Icons.no_meals_outlined,
        Icons.fastfood_outlined,
        Icons.kebab_dining_outlined,
        Icons.soup_kitchen_outlined,
      ],
    ),
    IconCategory(
      name: '学习',
      icon: Icons.menu_book_outlined,
      icons: [
        Icons.menu_book_outlined,
        Icons.auto_stories_outlined,
        Icons.book_outlined,
        Icons.library_books_outlined,
        Icons.article_outlined,
        Icons.edit_note,
        Icons.draw_outlined,
        Icons.edit_outlined,
        Icons.history_edu_outlined,
        Icons.school_outlined,
        Icons.science_outlined,
        Icons.calculate_outlined,
        Icons.functions_outlined,
        Icons.biotech_outlined,
        Icons.psychology_outlined,
        Icons.architecture_outlined,
        Icons.precision_manufacturing_outlined,
      ],
    ),
    IconCategory(
      name: '语言',
      icon: Icons.translate,
      icons: [
        Icons.translate,
        Icons.language_outlined,
        Icons.abc_outlined,
        Icons.spellcheck_outlined,
        Icons.record_voice_over_outlined,
        Icons.mic_outlined,
        Icons.headphones_outlined,
        Icons.hearing_outlined,
        Icons.interpreter_mode_outlined,
        Icons.subtitles_outlined,
        Icons.closed_caption_outlined,
        Icons.speaker_notes_outlined,
      ],
    ),
    IconCategory(
      name: '工作',
      icon: Icons.work_outline,
      icons: [
        Icons.code,
        Icons.terminal_outlined,
        Icons.computer_outlined,
        Icons.work_outline,
        Icons.business_center_outlined,
        Icons.task_alt_outlined,
        Icons.checklist_outlined,
        Icons.fact_check_outlined,
        Icons.assignment_outlined,
        Icons.pending_actions_outlined,
        Icons.event_outlined,
        Icons.event_available_outlined,
        Icons.inbox_outlined,
        Icons.mail_outlined,
        Icons.send_outlined,
        Icons.analytics_outlined,
        Icons.insights_outlined,
        Icons.trending_up_outlined,
        Icons.assessment_outlined,
        Icons.leaderboard_outlined,
        Icons.bar_chart_outlined,
        Icons.show_chart_outlined,
      ],
    ),
    IconCategory(
      name: '艺术',
      icon: Icons.palette_outlined,
      icons: [
        Icons.music_note_outlined,
        Icons.piano_outlined,
        Icons.album_outlined,
        Icons.library_music_outlined,
        Icons.queue_music_outlined,
        Icons.brush_outlined,
        Icons.palette_outlined,
        Icons.format_paint_outlined,
        Icons.gesture_outlined,
        Icons.auto_fix_high_outlined,
        Icons.photo_filter_outlined,
        Icons.filter_vintage_outlined,
        Icons.theater_comedy_outlined,
      ],
    ),
    IconCategory(
      name: '摄影',
      icon: Icons.camera_alt_outlined,
      icons: [
        Icons.camera_alt_outlined,
        Icons.videocam_outlined,
        Icons.movie_outlined,
        Icons.theaters_outlined,
        Icons.tv_outlined,
        Icons.podcasts_outlined,
        Icons.live_tv_outlined,
        Icons.photo_outlined,
        Icons.photo_library_outlined,
        Icons.video_library_outlined,
        Icons.slideshow_outlined,
        Icons.camera_roll_outlined,
      ],
    ),
    IconCategory(
      name: '心灵',
      icon: Icons.self_improvement,
      icons: [
        Icons.self_improvement,
        Icons.psychology_outlined,
        Icons.spa_outlined,
        Icons.hot_tub_outlined,
        Icons.air_outlined,
        Icons.mood_outlined,
        Icons.sentiment_satisfied_outlined,
        Icons.emoji_emotions_outlined,
        Icons.emoji_nature_outlined,
        Icons.volunteer_activism_outlined,
        Icons.diversity_1_outlined,
        Icons.handshake_outlined,
        Icons.favorite_outline,
        Icons.healing_outlined,
        Icons.church_outlined,
        Icons.temple_buddhist_outlined,
      ],
    ),
    IconCategory(
      name: '生活',
      icon: Icons.home_outlined,
      icons: [
        Icons.cleaning_services_outlined,
        Icons.dry_cleaning_outlined,
        Icons.iron_outlined,
        Icons.checkroom_outlined,
        Icons.bathtub_outlined,
        Icons.shower_outlined,
        Icons.wash_outlined,
        Icons.soap_outlined,
        Icons.sanitizer_outlined,
        Icons.face_retouching_natural_outlined,
        Icons.face_outlined,
        Icons.home_outlined,
        Icons.bed_outlined,
        Icons.chair_outlined,
        Icons.weekend_outlined,
        Icons.kitchen_outlined,
        Icons.bathroom_outlined,
        Icons.living_outlined,
      ],
    ),
    IconCategory(
      name: '自然',
      icon: Icons.eco_outlined,
      icons: [
        Icons.local_florist_outlined,
        Icons.grass_outlined,
        Icons.yard_outlined,
        Icons.eco_outlined,
        Icons.park_outlined,
        Icons.forest_outlined,
        Icons.pets_outlined,
        Icons.cruelty_free_outlined,
        Icons.bug_report_outlined,
        Icons.emoji_nature_outlined,
        Icons.waves_outlined,
        Icons.terrain_outlined,
        Icons.landscape_outlined,
        Icons.water_outlined,
        Icons.cloud_outlined,
        Icons.thunderstorm_outlined,
        Icons.ac_unit_outlined,
        Icons.wb_cloudy_outlined,
      ],
    ),
    IconCategory(
      name: '社交',
      icon: Icons.people_outline,
      icons: [
        Icons.people_outline,
        Icons.person_outline,
        Icons.groups_outlined,
        Icons.family_restroom_outlined,
        Icons.elderly_outlined,
        Icons.child_care_outlined,
        Icons.call_outlined,
        Icons.video_call_outlined,
        Icons.chat_outlined,
        Icons.forum_outlined,
        Icons.campaign_outlined,
        Icons.connect_without_contact_outlined,
        Icons.share_outlined,
        Icons.group_add_outlined,
        Icons.person_add_outlined,
        Icons.waving_hand_outlined,
      ],
    ),
    IconCategory(
      name: '出行',
      icon: Icons.explore_outlined,
      icons: [
        Icons.directions_car_outlined,
        Icons.directions_bus_outlined,
        Icons.train_outlined,
        Icons.flight_outlined,
        Icons.flight_takeoff_outlined,
        Icons.two_wheeler_outlined,
        Icons.electric_scooter_outlined,
        Icons.sailing_outlined,
        Icons.explore_outlined,
        Icons.map_outlined,
        Icons.tour_outlined,
        Icons.luggage_outlined,
        Icons.directions_bike_outlined,
        Icons.directions_subway_outlined,
        Icons.local_taxi_outlined,
        Icons.airport_shuttle_outlined,
        Icons.directions_boat_outlined,
        Icons.rocket_launch_outlined,
      ],
    ),
    IconCategory(
      name: '健康',
      icon: Icons.monitor_heart_outlined,
      icons: [
        Icons.medical_services_outlined,
        Icons.medication_outlined,
        Icons.vaccines_outlined,
        Icons.healing_outlined,
        Icons.health_and_safety_outlined,
        Icons.monitor_heart_outlined,
        Icons.bloodtype_outlined,
        Icons.visibility_outlined,
        Icons.hearing_outlined,
        Icons.accessibility_new_outlined,
        Icons.monitor_weight_outlined,
        Icons.sick_outlined,
        Icons.coronavirus_outlined,
        Icons.masks_outlined,
        Icons.personal_injury_outlined,
        Icons.emergency_outlined,
      ],
    ),
    IconCategory(
      name: '财务',
      icon: Icons.savings_outlined,
      icons: [
        Icons.savings_outlined,
        Icons.account_balance_wallet_outlined,
        Icons.payments_outlined,
        Icons.credit_card_outlined,
        Icons.attach_money_outlined,
        Icons.money_off_outlined,
        Icons.receipt_long_outlined,
        Icons.account_balance_outlined,
        Icons.currency_exchange_outlined,
        Icons.price_check_outlined,
        Icons.request_quote_outlined,
        Icons.point_of_sale_outlined,
        Icons.monetization_on_outlined,
      ],
    ),
    IconCategory(
      name: '数码',
      icon: Icons.devices_outlined,
      icons: [
        Icons.phone_android_outlined,
        Icons.phone_iphone_outlined,
        Icons.phone_disabled_outlined,
        Icons.smartphone_outlined,
        Icons.tablet_outlined,
        Icons.watch_outlined,
        Icons.devices_outlined,
        Icons.battery_charging_full_outlined,
        Icons.power_outlined,
        Icons.wifi_off_outlined,
        Icons.bluetooth_outlined,
        Icons.screen_lock_portrait_outlined,
        Icons.do_not_disturb_on_outlined,
        Icons.data_saver_on_outlined,
        Icons.signal_cellular_alt_outlined,
      ],
    ),
    IconCategory(
      name: '娱乐',
      icon: Icons.sports_esports_outlined,
      icons: [
        Icons.sports_esports_outlined,
        Icons.games_outlined,
        Icons.casino_outlined,
        Icons.extension_outlined,
        Icons.toys_outlined,
        Icons.attractions_outlined,
        Icons.celebration_outlined,
        Icons.party_mode_outlined,
        Icons.nightlife_outlined,
        Icons.local_bar_outlined,
        Icons.music_video_outlined,
        Icons.stadium_outlined,
        Icons.festival_outlined,
        Icons.event_seat_outlined,
        Icons.confirmation_number_outlined,
      ],
    ),
    IconCategory(
      name: '成就',
      icon: Icons.emoji_events_outlined,
      icons: [
        Icons.emoji_events_outlined,
        Icons.military_tech_outlined,
        Icons.diamond_outlined,
        Icons.bolt_outlined,
        Icons.public_outlined,
        Icons.verified_outlined,
        Icons.workspace_premium_outlined,
        Icons.stars_outlined,
        Icons.auto_awesome_outlined,
        Icons.flare_outlined,
        Icons.whatshot_outlined,
        Icons.local_fire_department_outlined,
        Icons.shield_outlined,
        Icons.security_outlined,
        Icons.token_outlined,
      ],
    ),
  ];

  // 获取所有图标的平铺列表（用于索引存储）
  static List<IconData> get allIcons {
    final List<IconData> icons = [];
    for (final category in categories) {
      for (final icon in category.icons) {
        if (!icons.contains(icon)) {
          icons.add(icon);
        }
      }
    }
    return icons;
  }

  static IconData getIcon(int index) {
    final icons = allIcons;
    if (index >= 0 && index < icons.length) {
      return icons[index];
    }
    return Icons.flag_outlined;
  }

  static int getIconIndex(IconData icon) {
    return allIcons.indexOf(icon);
  }
}

// 图标分类数据类
class IconCategory {
  final String name;
  final IconData icon;
  final List<IconData> icons;

  const IconCategory({
    required this.name,
    required this.icon,
    required this.icons,
  });
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
        // 移除了 border 属性
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
          StatisticsPage(habits: habits),
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
                                  "开启一个新习惯",
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

// 计算累计打卡次数最多的习惯
  int get maxTotalCheckIns {
    if (widget.habits.isEmpty) return 0;

    int maxTotal = 0;
    for (final habit in widget.habits) {
      if (habit.checkInRecords.length > maxTotal) {
        maxTotal = habit.checkInRecords.length;
      }
    }
    return maxTotal;
  }

  // 计算今日完成率
  double get todayCompletionRate {
    if (widget.habits.isEmpty) return 0;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    int completed = 0;
    for (final habit in widget.habits) {
      if (habit.checkInTimes.any((t) => t.startsWith(today))) {
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
      ranking.add({
        'habit': habit,
        'streak': streak,
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text("统计",
                style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w300)),
            centerTitle: true,
            backgroundColor: backgroundColor,
          ),

          // 概览卡片
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  _buildStatCard("习惯数", "${widget.habits.length}", Icons.flag_outlined, themeColor),
                  const SizedBox(width: 12),
                  _buildStatCard("打卡数", "$totalCheckIns", Icons.check_circle_outline, themeColor),
                  const SizedBox(width: 12),
                  _buildStatCard("连续中", "$currentStreak天", Icons.local_fire_department_outlined, Colors.orange),
                  const SizedBox(width: 12),
                  _buildStatCard("最长", "$maxTotalCheckIns次", Icons.emoji_events_outlined, Colors.amber),
                ],
              ),
            ),
          ),

          // 完成率卡片
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.pie_chart_outline, size: 20, color: themeColor),
                        const SizedBox(width: 8),
                        Text("完成率", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800])),
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
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 20, color: themeColor),
                        const SizedBox(width: 8),
                        Text("最近30天", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800])),
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
                        ...List.generate(5, (i) => Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.2 + i * 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )),
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
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.leaderboard_outlined, size: 20, color: themeColor),
                        const SizedBox(width: 8),
                        Text("习惯排行", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800])),
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
                        final total = item['total'] as int;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              // 排名
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: index == 0 ? Colors.amber[100] :
                                  index == 1 ? Colors.grey[200] :
                                  index == 2 ? Colors.orange[100] :
                                  Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    "${index + 1}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: index == 0 ? Colors.amber[800] :
                                      index == 1 ? Colors.grey[600] :
                                      index == 2 ? Colors.orange[800] :
                                      Colors.grey[500],
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
                              // 名称
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      habit.title,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      "共打卡 $total 次",
                                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                    ),
                                  ],
                                ),
                              ),
                              // 连续天数
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: streak > 0 ? Colors.orange[50] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.local_fire_department,
                                      size: 14,
                                      color: streak > 0 ? Colors.orange[600] : Colors.grey[400],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "$streak天",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: streak > 0 ? Colors.orange[700] : Colors.grey[400],
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
    );
  }

  // 构建统计卡片
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color),
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
          message: "${DateFormat('M/d').format(date)}: $count/${habitCount}",
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
                style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w300)),
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
                        Container(width: 1, height: 40, color: Colors.grey[200]),
                        _statItem("今日完成", todayCheckIns.toString(), themeColor),
                        Container(width: 1, height: 40, color: Colors.grey[200]),
                        _statItem("累计打卡", totalCheckIns.toString(), themeColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 菜单项
                  _menuItem(context, Icons.emoji_events_outlined, "打卡成就",
                      AchievementPage(habits: habits)),
                  _menuItem(context, Icons.notifications_none, "提醒设置",
                      ReminderSettingsPage(habits: habits, onSave: onSave)),
                  _menuItem(context, Icons.color_lens_outlined, "主题设置",
                      const ThemeSettingsPage()),
                  _menuItem(context, Icons.cloud_outlined, "数据备份",
                      BackupPage(habits: habits, onRestore: onRestore)),
                  _menuItem(context, Icons.info_outline, "关于", const AboutPage()),
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

  Widget _menuItem(BuildContext context, IconData icon, String title, Widget? page) {
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

  // 删除提醒确认 - 优化后的样式
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
                  child: Icon(Icons.notifications_off_outlined, color: Colors.red[400], size: 36),
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
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "日历中的事件需要手动删除",
                          style: TextStyle(color: Colors.orange[800], fontSize: 13),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text("确认删除", style: TextStyle(fontSize: 15)),
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
            Text("版本 1.7.5",
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
                  _infoRow("更新时间", "2026年1月12日"),
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

// ========== 成就页面 ==========
class AchievementPage extends StatelessWidget {
  final List<Habit> habits;

  const AchievementPage({super.key, required this.habits});

  // 计算总打卡次数
  int get totalCheckIns {
    return habits.fold(0, (sum, h) => sum + h.checkInRecords.length);
  }

  // 计算今日完成数
  int get todayCheckIns {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return habits.where((h) => h.checkInTimes.any((t) => t.startsWith(today))).length;
  }

  // 计算历史最长连续天数
  int get historyMaxStreak {
    if (habits.isEmpty) return 0;

    int maxStreak = 0;
    for (final habit in habits) {
      final streak = _calculateHistoryMaxStreak(habit);
      if (streak > maxStreak) {
        maxStreak = streak;
      }
    }
    return maxStreak;
  }

  int _calculateHistoryMaxStreak(Habit habit) {
    if (habit.checkInRecords.isEmpty) return 0;

    final dates = <String>[];
    for (final record in habit.checkInRecords) {
      if (record.time.length >= 10) {
        final dateStr = record.time.substring(0, 10);
        if (!dates.contains(dateStr)) {
          dates.add(dateStr);
        }
      }
    }

    if (dates.isEmpty) return 0;

    dates.sort();
    int maxStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < dates.length; i++) {
      final prevDate = DateTime.parse(dates[i - 1]);
      final currDate = DateTime.parse(dates[i]);
      final diff = currDate.difference(prevDate).inDays;

      if (diff == 1) {
        currentStreak++;
        maxStreak = max(maxStreak, currentStreak);
      } else if (diff > 1) {
        currentStreak = 1;
      }
    }

    return maxStreak;
  }

  // ========== 特殊成就检查方法 ==========

  // 起飞，芜湖！ - 创建飞机图标习惯并打卡一次
  bool get isFlightUnlocked {
    final flightIconIndex = HabitIcons.getIconIndex(Icons.flight_takeoff_outlined);
    for (final habit in habits) {
      if (habit.iconIndex == flightIconIndex && habit.checkInRecords.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  // 缺勤大师 - 累计未打卡次数达到50次
  int get totalMissedDays {
    int missed = 0;
    final today = DateTime.now();

    for (final habit in habits) {
      try {
        final createdDate = DateTime.parse(habit.createdAt.substring(0, 10));
        final daysSinceCreation = today.difference(createdDate).inDays + 1;

        final checkedDates = <String>{};
        for (final record in habit.checkInRecords) {
          if (record.time.length >= 10) {
            checkedDates.add(record.time.substring(0, 10));
          }
        }

        missed += (daysSinceCreation - checkedDates.length).clamp(0, daysSinceCreation);
      } catch (e) {
        continue;
      }
    }

    return missed;
  }

  // 夜猫子 - 在凌晨0-5点打卡
  bool get isNightOwlUnlocked {
    for (final habit in habits) {
      for (final record in habit.checkInRecords) {
        if (record.time.length >= 13) {
          final hour = int.tryParse(record.time.substring(11, 13)) ?? 12;
          if (hour >= 0 && hour < 5) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // 早起的鸟儿 - 在早上5-7点打卡
  bool get isEarlyBirdUnlocked {
    for (final habit in habits) {
      for (final record in habit.checkInRecords) {
        if (record.time.length >= 13) {
          final hour = int.tryParse(record.time.substring(11, 13)) ?? 12;
          if (hour >= 5 && hour < 7) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // 周末战士 - 累计在周末打卡10次
  int get weekendCheckIns {
    int count = 0;
    for (final habit in habits) {
      for (final record in habit.checkInRecords) {
        if (record.time.length >= 10) {
          try {
            final date = DateTime.parse(record.time.substring(0, 10));
            if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
              count++;
            }
          } catch (e) {
            continue;
          }
        }
      }
    }
    return count;
  }

  // 一心多用 - 同一天完成5个不同习惯
  bool get isMultitaskerUnlocked {
    final dateMap = <String, Set<String>>{};
    for (final habit in habits) {
      for (final record in habit.checkInRecords) {
        if (record.time.length >= 10) {
          final dateStr = record.time.substring(0, 10);
          if (!dateMap.containsKey(dateStr)) {
            dateMap[dateStr] = {};
          }
          dateMap[dateStr]!.add(habit.id);
        }
      }
    }

    for (final habitIds in dateMap.values) {
      if (habitIds.length >= 5) {
        return true;
      }
    }
    return false;
  }

  // 完美一周 - 连续7天完成所有习惯
  bool get isPerfectWeekUnlocked {
    if (habits.isEmpty) return false;

    final today = DateTime.now();
    int consecutivePerfectDays = 0;

    for (int i = 0; i < 60; i++) {
      final date = today.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      bool allDone = true;
      int validHabits = 0;

      for (final habit in habits) {
        try {
          final createdDate = DateTime.parse(habit.createdAt.substring(0, 10));
          if (date.isBefore(createdDate)) {
            continue;
          }
          validHabits++;
          if (!habit.checkInTimes.any((t) => t.startsWith(dateStr))) {
            allDone = false;
            break;
          }
        } catch (e) {
          continue;
        }
      }

      if (validHabits > 0 && allDone) {
        consecutivePerfectDays++;
        if (consecutivePerfectDays >= 7) {
          return true;
        }
      } else {
        consecutivePerfectDays = 0;
      }
    }

    return false;
  }

  // 深夜食堂 - 在晚上10点后打卡饮食相关习惯
  bool get isLateNightFoodieUnlocked {
    final foodIcons = [
      Icons.restaurant_outlined,
      Icons.local_dining_outlined,
      Icons.fastfood_outlined,
      Icons.ramen_dining_outlined,
      Icons.rice_bowl_outlined,
      Icons.local_pizza_outlined,
      Icons.cake_outlined,
      Icons.cookie_outlined,
      Icons.icecream_outlined,
    ];

    final foodIconIndices = foodIcons.map((icon) => HabitIcons.getIconIndex(icon)).toSet();

    for (final habit in habits) {
      if (foodIconIndices.contains(habit.iconIndex)) {
        for (final record in habit.checkInRecords) {
          if (record.time.length >= 13) {
            final hour = int.tryParse(record.time.substring(11, 13)) ?? 12;
            if (hour >= 22 || hour < 4) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  // 健身狂人 - 运动相关习惯累计打卡30次
  int get fitnessCheckIns {
    final fitnessIcons = [
      Icons.fitness_center,
      Icons.directions_run,
      Icons.directions_walk,
      Icons.sports_gymnastics,
      Icons.pool_outlined,
      Icons.pedal_bike_outlined,
      Icons.hiking_outlined,
    ];

    final fitnessIconIndices = fitnessIcons.map((icon) => HabitIcons.getIconIndex(icon)).toSet();

    int count = 0;
    for (final habit in habits) {
      if (fitnessIconIndices.contains(habit.iconIndex)) {
        count += habit.checkInRecords.length;
      }
    }
    return count;
  }

  // 书虫 - 阅读相关习惯累计打卡30次
  int get readingCheckIns {
    final readingIcons = [
      Icons.menu_book_outlined,
      Icons.auto_stories_outlined,
      Icons.book_outlined,
      Icons.library_books_outlined,
    ];

    final readingIconIndices = readingIcons.map((icon) => HabitIcons.getIconIndex(icon)).toSet();

    int count = 0;
    for (final habit in habits) {
      if (readingIconIndices.contains(habit.iconIndex)) {
        count += habit.checkInRecords.length;
      }
    }
    return count;
  }

  // 佛系玩家 - 创建习惯后7天内未打卡
  bool get isZenPlayerUnlocked {
    final today = DateTime.now();
    for (final habit in habits) {
      try {
        final createdDate = DateTime.parse(habit.createdAt.substring(0, 10));
        final daysSinceCreation = today.difference(createdDate).inDays;

        if (daysSinceCreation >= 7 && habit.checkInRecords.isEmpty) {
          return true;
        }
      } catch (e) {
        continue;
      }
    }
    return false;
  }

  // 午夜惊魂 - 在凌晨3点打卡
  bool get isMidnightHorrorUnlocked {
    for (final habit in habits) {
      for (final record in habit.checkInRecords) {
        if (record.time.length >= 16) {
          final hour = int.tryParse(record.time.substring(11, 13)) ?? 12;
          final minute = int.tryParse(record.time.substring(14, 16)) ?? 0;
          if (hour == 3 && minute >= 0 && minute <= 30) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // 获取常规成就列表
  List<Achievement> get regularAchievements {
    final total = totalCheckIns;
    final streak = historyMaxStreak;
    final habitCount = habits.length;

    return [
      // 打卡次数成就
      Achievement(
        icon: Icons.star_outline,
        title: '初次打卡',
        description: '完成第一次打卡',
        isUnlocked: total >= 1,
        progress: total >= 1 ? 1.0 : 0.0,
        current: total,
        target: 1,
        category: '打卡次数',
      ),
      Achievement(
        icon: Icons.looks_one_outlined,
        title: '小试牛刀',
        description: '累计打卡10次',
        isUnlocked: total >= 10,
        progress: (total / 10).clamp(0.0, 1.0),
        current: total,
        target: 10,
        category: '打卡次数',
      ),
      Achievement(
        icon: Icons.looks_two_outlined,
        title: '渐入佳境',
        description: '累计打卡50次',
        isUnlocked: total >= 50,
        progress: (total / 50).clamp(0.0, 1.0),
        current: total,
        target: 50,
        category: '打卡次数',
      ),
      Achievement(
        icon: Icons.looks_3_outlined,
        title: '百折不挠',
        description: '累计打卡100次',
        isUnlocked: total >= 100,
        progress: (total / 100).clamp(0.0, 1.0),
        current: total,
        target: 100,
        category: '打卡次数',
      ),
      Achievement(
        icon: Icons.military_tech_outlined,
        title: '打卡达人',
        description: '累计打卡500次',
        isUnlocked: total >= 500,
        progress: (total / 500).clamp(0.0, 1.0),
        current: total,
        target: 500,
        category: '打卡次数',
      ),
      Achievement(
        icon: Icons.emoji_events_outlined,
        title: '传奇人物',
        description: '累计打卡1000次',
        isUnlocked: total >= 1000,
        progress: (total / 1000).clamp(0.0, 1.0),
        current: total,
        target: 1000,
        category: '打卡次数',
      ),

      // 连续打卡成就
      Achievement(
        icon: Icons.local_fire_department_outlined,
        title: '三天热情',
        description: '连续打卡3天',
        isUnlocked: streak >= 3,
        progress: (streak / 3).clamp(0.0, 1.0),
        current: streak,
        target: 3,
        category: '连续打卡',
      ),
      Achievement(
        icon: Icons.whatshot_outlined,
        title: '周末勇士',
        description: '连续打卡7天',
        isUnlocked: streak >= 7,
        progress: (streak / 7).clamp(0.0, 1.0),
        current: streak,
        target: 7,
        category: '连续打卡',
      ),
      Achievement(
        icon: Icons.bolt_outlined,
        title: '月度之星',
        description: '连续打卡30天',
        isUnlocked: streak >= 30,
        progress: (streak / 30).clamp(0.0, 1.0),
        current: streak,
        target: 30,
        category: '连续打卡',
      ),
      Achievement(
        icon: Icons.diamond_outlined,
        title: '习惯大师',
        description: '连续打卡100天',
        isUnlocked: streak >= 100,
        progress: (streak / 100).clamp(0.0, 1.0),
        current: streak,
        target: 100,
        category: '连续打卡',
      ),
      Achievement(
        icon: Icons.workspace_premium_outlined,
        title: '年度传奇',
        description: '连续打卡365天',
        isUnlocked: streak >= 365,
        progress: (streak / 365).clamp(0.0, 1.0),
        current: streak,
        target: 365,
        category: '连续打卡',
      ),

      // 习惯数量成就
      Achievement(
        icon: Icons.flag_outlined,
        title: '新的开始',
        description: '创建第一个习惯',
        isUnlocked: habitCount >= 1,
        progress: habitCount >= 1 ? 1.0 : 0.0,
        current: habitCount,
        target: 1,
        category: '习惯数量',
      ),
      Achievement(
        icon: Icons.auto_awesome_outlined,
        title: '习惯收集者',
        description: '拥有5个习惯',
        isUnlocked: habitCount >= 5,
        progress: (habitCount / 5).clamp(0.0, 1.0),
        current: habitCount,
        target: 5,
        category: '习惯数量',
      ),
      Achievement(
        icon: Icons.psychology_outlined,
        title: '自律达人',
        description: '拥有10个习惯',
        isUnlocked: habitCount >= 10,
        progress: (habitCount / 10).clamp(0.0, 1.0),
        current: habitCount,
        target: 10,
        category: '习惯数量',
      ),
    ];
  }

  // 获取特殊成就列表（只返回已解锁的）
  List<Achievement> get specialAchievements {
    final todayDone = todayCheckIns;
    final habitCount = habits.length;
    final missed = totalMissedDays;
    final weekend = weekendCheckIns;
    final fitness = fitnessCheckIns;
    final reading = readingCheckIns;

    final allSpecial = [
      // 完美一天
      Achievement(
        icon: Icons.check_circle_outline,
        title: '完美一天',
        description: '今日完成所有习惯',
        isUnlocked: habitCount > 0 && todayDone == habitCount,
        progress: habitCount > 0 ? (todayDone / habitCount).clamp(0.0, 1.0) : 0.0,
        current: todayDone,
        target: habitCount,
        category: '特殊成就',
      ),
      // 起飞，芜湖！
      Achievement(
        icon: Icons.flight_takeoff_outlined,
        title: '起飞，芜湖！',
        description: '创建飞机图标习惯并完成打卡',
        isUnlocked: isFlightUnlocked,
        progress: isFlightUnlocked ? 1.0 : 0.0,
        current: isFlightUnlocked ? 1 : 0,
        target: 1,
        category: '特殊成就',
      ),
      // 缺勤大师
      Achievement(
        icon: Icons.hotel_outlined,
        title: '缺勤大师',
        description: '累计未打卡50次',
        isUnlocked: missed >= 50,
        progress: (missed / 50).clamp(0.0, 1.0),
        current: missed,
        target: 50,
        category: '特殊成就',
      ),
      // 夜猫子
      Achievement(
        icon: Icons.nightlight_outlined,
        title: '夜猫子',
        description: '在凌晨0-5点打卡',
        isUnlocked: isNightOwlUnlocked,
        progress: isNightOwlUnlocked ? 1.0 : 0.0,
        current: isNightOwlUnlocked ? 1 : 0,
        target: 1,
        category: '特殊成就',
      ),
      // 早起的鸟儿
      Achievement(
        icon: Icons.wb_sunny_outlined,
        title: '早起的鸟儿',
        description: '在早上5-7点打卡',
        isUnlocked: isEarlyBirdUnlocked,
        progress: isEarlyBirdUnlocked ? 1.0 : 0.0,
        current: isEarlyBirdUnlocked ? 1 : 0,
        target: 1,
        category: '特殊成就',
      ),
      // 周末战士
      Achievement(
        icon: Icons.weekend_outlined,
        title: '周末战士',
        description: '在周末累计打卡10次',
        isUnlocked: weekend >= 10,
        progress: (weekend / 10).clamp(0.0, 1.0),
        current: weekend,
        target: 10,
        category: '特殊成就',
      ),
      // 一心多用
      Achievement(
        icon: Icons.auto_awesome_mosaic_outlined,
        title: '一心多用',
        description: '同一天完成5个不同习惯',
        isUnlocked: isMultitaskerUnlocked,
        progress: isMultitaskerUnlocked ? 1.0 : 0.0,
        current: isMultitaskerUnlocked ? 1 : 0,
        target: 1,
        category: '特殊成就',
      ),
      // 完美一周
      Achievement(
        icon: Icons.date_range_outlined,
        title: '完美一周',
        description: '连续7天完成所有习惯',
        isUnlocked: isPerfectWeekUnlocked,
        progress: isPerfectWeekUnlocked ? 1.0 : 0.0,
        current: isPerfectWeekUnlocked ? 1 : 0,
        target: 1,
        category: '特殊成就',
      ),
      // 深夜食堂
      Achievement(
        icon: Icons.ramen_dining_outlined,
        title: '深夜食堂',
        description: '在晚上10点后打卡饮食习惯',
        isUnlocked: isLateNightFoodieUnlocked,
        progress: isLateNightFoodieUnlocked ? 1.0 : 0.0,
        current: isLateNightFoodieUnlocked ? 1 : 0,
        target: 1,
        category: '特殊成就',
      ),
      // 健身狂人
      Achievement(
        icon: Icons.fitness_center,
        title: '健身狂人',
        description: '运动相关习惯累计打卡30次',
        isUnlocked: fitness >= 30,
        progress: (fitness / 30).clamp(0.0, 1.0),
        current: fitness,
        target: 30,
        category: '特殊成就',
      ),
      // 书虫
      Achievement(
        icon: Icons.menu_book_outlined,
        title: '书虫',
        description: '阅读相关习惯累计打卡30次',
        isUnlocked: reading >= 30,
        progress: (reading / 30).clamp(0.0, 1.0),
        current: reading,
        target: 30,
        category: '特殊成就',
      ),
      // 佛系玩家
      Achievement(
        icon: Icons.self_improvement,
        title: '佛系玩家',
        description: '创建习惯7天后仍未打卡',
        isUnlocked: isZenPlayerUnlocked,
        progress: isZenPlayerUnlocked ? 1.0 : 0.0,
        current: isZenPlayerUnlocked ? 1 : 0,
        target: 1,
        category: '特殊成就',
      ),
      // 午夜惊魂
      Achievement(
        icon: Icons.dark_mode_outlined,
        title: '午夜惊魂',
        description: '在凌晨3点打卡',
        isUnlocked: isMidnightHorrorUnlocked,
        progress: isMidnightHorrorUnlocked ? 1.0 : 0.0,
        current: isMidnightHorrorUnlocked ? 1 : 0,
        target: 1,
        category: '特殊成就',
      ),
    ];

    // 只返回已解锁的特殊成就
    return allSpecial.where((a) => a.isUnlocked).toList();
  }

  // 特殊成就总数（用于显示）
  int get totalSpecialAchievements => 13;

  // 所有成就
  List<Achievement> get achievements {
    return [...regularAchievements, ...specialAchievements];
  }

  // 已解锁成就数
  int get unlockedCount {
    final regularUnlocked = regularAchievements.where((a) => a.isUnlocked).length;
    return regularUnlocked + specialAchievements.length;
  }

  // 成就总数
  int get totalAchievements {
    return regularAchievements.length + totalSpecialAchievements;
  }

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
    final grouped = groupedRegularAchievements;
    final unlockedSpecial = specialAchievements;

    return Scaffold(
      appBar: AppBar(
        title: const Text("打卡成就", style: TextStyle(fontSize: 16)),
        backgroundColor: backgroundColor,
      ),
      body: ListView(
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
                    color: Colors.white,
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
                            value: unlockedCount / totalAchievements,
                            strokeWidth: 5,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          "${(unlockedCount / totalAchievements * 100).toInt()}%",
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
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
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
                // 只显示已解锁的特殊成就
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
        ],
      ),
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