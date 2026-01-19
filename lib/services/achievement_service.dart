import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../models/achievement.dart';
import 'habit_icons.dart';

// ========== 成就服务类 ==========
class AchievementService {
  static const String _notifiedKey = 'notified_achievements';
  static const String _cancelledCheckInKey = 'has_cancelled_checkin';
  static const String _deletedHabitKey = 'has_deleted_habit';
  static const String _initializedKey = 'achievement_initialized';
  static const String _unlockedKey = 'unlocked_achievements';

  static Future<void> recordCancelledCheckIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cancelledCheckInKey, true);
  }

  static Future<bool> hasCancelledCheckIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cancelledCheckInKey) ?? false;
  }

  static Future<void> recordDeletedHabit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_deletedHabitKey, true);
  }

  static Future<bool> hasDeletedHabit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_deletedHabitKey) ?? false;
  }

  static Future<Set<String>> getNotifiedAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_notifiedKey) ?? [];
    return list.toSet();
  }

  static Future<void> saveNotifiedAchievements(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_notifiedKey, ids.toList());
  }

  /// 获取永久解锁的成就ID列表
  static Future<Set<String>> getUnlockedAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_unlockedKey) ?? [];
    return list.toSet();
  }

  /// 保存永久解锁的成就ID
  static Future<void> saveUnlockedAchievements(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_unlockedKey, ids.toList());
  }

  /// 检查新解锁的成就（需要弹窗通知的）
  static Future<List<Achievement>> checkNewAchievements(List<Habit> habits) async {
    final checker = await AchievementChecker.create(habits);
    final currentUnlocked = checker.getAllUnlockedAchievements();
    final notifiedAchievements = await getNotifiedAchievements();
    final permanentlyUnlocked = await getUnlockedAchievements();

    final newAchievements = <Achievement>[];
    final newNotifiedIds = Set<String>.from(notifiedAchievements);
    final newUnlockedIds = Set<String>.from(permanentlyUnlocked);

    for (final achievement in currentUnlocked) {
      if (!notifiedAchievements.contains(achievement.id)) {
        newAchievements.add(achievement);
        newNotifiedIds.add(achievement.id);
      }
      // 添加到永久解锁列表
      newUnlockedIds.add(achievement.id);
    }

    if (newAchievements.isNotEmpty) {
      await saveNotifiedAchievements(newNotifiedIds);
    }

    // 保存永久解锁的成就
    await saveUnlockedAchievements(newUnlockedIds);

    return newAchievements;
  }

  /// 获取所有应该显示的成就（包括永久解锁的）
  static Future<List<Achievement>> getAllDisplayAchievements(List<Habit> habits) async {
    final checker = await AchievementChecker.create(habits);
    final permanentlyUnlockedIds = await getUnlockedAchievements();

    // 获取所有成就定义（包括未解锁的）
    final allAchievements = checker.getAllAchievementsWithProgress();

    // 标记永久解锁的成就
    for (final achievement in allAchievements) {
      if (permanentlyUnlockedIds.contains(achievement.id)) {
        // 创建一个已解锁版本
        final index = allAchievements.indexOf(achievement);
        allAchievements[index] = Achievement(
          id: achievement.id,
          icon: achievement.icon,
          title: achievement.title,
          description: achievement.description,
          isUnlocked: true,
          progress: 1.0,
          current: achievement.target,
          target: achievement.target,
          category: achievement.category,
        );
      }
    }

    return allAchievements;
  }

  /// 导出成就状态（用于备份）
  static Future<Map<String, dynamic>> exportAchievementStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'has_cancelled_checkin': prefs.getBool(_cancelledCheckInKey) ?? false,
      'has_deleted_habit': prefs.getBool(_deletedHabitKey) ?? false,
      'notified_achievements': prefs.getStringList(_notifiedKey) ?? [],
      'unlocked_achievements': prefs.getStringList(_unlockedKey) ?? [],  // 新增
    };
  }

  /// 导入成就状态（用于恢复备份）
  static Future<void> importAchievementStatus(Map<String, dynamic>? status) async {
    if (status == null) return;

    final prefs = await SharedPreferences.getInstance();

    if (status['has_cancelled_checkin'] == true) {
      await prefs.setBool(_cancelledCheckInKey, true);
    }

    if (status['has_deleted_habit'] == true) {
      await prefs.setBool(_deletedHabitKey, true);
    }

    if (status['notified_achievements'] != null) {
      final list = (status['notified_achievements'] as List).cast<String>();
      await prefs.setStringList(_notifiedKey, list);
    }

    // 新增：导入永久解锁的成就
    if (status['unlocked_achievements'] != null) {
      final list = (status['unlocked_achievements'] as List).cast<String>();
      await prefs.setStringList(_unlockedKey, list);
    }
  }

  /// 清除所有成就数据
  static Future<void> clearAllAchievementData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notifiedKey);
    await prefs.remove(_unlockedKey);  // 新增
    await prefs.remove(_cancelledCheckInKey);
    await prefs.remove(_deletedHabitKey);
    await prefs.remove(_initializedKey);
  }

  /// 初始化成就系统
  static Future<void> initializeIfNeeded(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final initialized = prefs.getBool(_initializedKey) ?? false;

    if (!initialized) {
      await syncAchievements(habits);
      await prefs.setBool(_initializedKey, true);
    }
  }

  /// 同步成就状态
  static Future<void> syncAchievements(List<Habit> habits) async {
    final checker = await AchievementChecker.create(habits);
    final currentUnlocked = checker.getAllUnlockedAchievements();
    final currentNotified = await getNotifiedAchievements();
    final currentPermanent = await getUnlockedAchievements();

    final newNotifiedIds = Set<String>.from(currentNotified);
    final newUnlockedIds = Set<String>.from(currentPermanent);

    for (final achievement in currentUnlocked) {
      newNotifiedIds.add(achievement.id);
      newUnlockedIds.add(achievement.id);
    }

    await saveNotifiedAchievements(newNotifiedIds);
    await saveUnlockedAchievements(newUnlockedIds);
  }

  /// 重新同步成就状态（导入后调用）
  static Future<void> resyncAfterImport(List<Habit> habits) async {
    final checker = await AchievementChecker.create(habits);
    final currentUnlocked = checker.getAllUnlockedAchievements();
    final currentPermanent = await getUnlockedAchievements();

    // 合并当前解锁的和已保存的永久解锁
    final allUnlockedIds = Set<String>.from(currentPermanent);
    for (final achievement in currentUnlocked) {
      allUnlockedIds.add(achievement.id);
    }

    await saveNotifiedAchievements(allUnlockedIds);
    await saveUnlockedAchievements(allUnlockedIds);
  }

  static Future<void> debugPrintStatus(List<Habit> habits) async {
    final checker = await AchievementChecker.create(habits);
    final currentUnlocked = checker.getAllUnlockedAchievements();
    final notified = await getNotifiedAchievements();

    debugPrint('===== 成就调试信息 =====');
    debugPrint('已解锁成就: ${currentUnlocked.map((a) => a.id).toList()}');
    debugPrint('已通知成就: $notified');
    debugPrint('待通知成就: ${currentUnlocked.where((a) => !notified.contains(a.id)).map((a) => a.id).toList()}');
    debugPrint('========================');
  }
}

// ========== 成就检查器 ==========
class AchievementChecker {
  final List<Habit> habits;
  final bool hasCancelledCheckIn;
  final bool hasDeletedHabit;

  AchievementChecker._({
    required this.habits,
    required this.hasCancelledCheckIn,
    required this.hasDeletedHabit,
  });

  static Future<AchievementChecker> create(List<Habit> habits) async {
    final cancelled = await AchievementService.hasCancelledCheckIn();
    final deleted = await AchievementService.hasDeletedHabit();
    return AchievementChecker._(
      habits: habits,
      hasCancelledCheckIn: cancelled,
      hasDeletedHabit: deleted,
    );
  }

  // ========== 辅助方法：分类图标判定 ==========

  /// 获取指定分类的所有图标
  static List<IconData> _getCategoryIcons(String categoryName) {
    for (final category in HabitIcons.categories) {
      if (category.name == categoryName) {
        return category.icons;
      }
    }
    return [];
  }

  /// 检查习惯图标是否属于指定分类
  bool _isHabitInCategory(Habit habit, String categoryName) {
    final categoryIcons = _getCategoryIcons(categoryName);
    final habitIcon = HabitIcons.getIcon(habit.iconIndex);
    return categoryIcons.contains(habitIcon);
  }

  // ========== 基础统计 ==========

  int get totalCheckIns {
    return habits.fold(0, (sum, h) => sum + h.checkInRecords.length);
  }

  int get todayCheckIns {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return habits.where((h) => h.checkInTimes.any((t) => t.startsWith(today))).length;
  }

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

  // ========== 特殊成就检查 ==========

  bool get isFlightUnlocked {
    for (final habit in habits) {
      final habitIcon = HabitIcons.getIcon(habit.iconIndex);
      if ((habitIcon == Icons.flight_takeoff_outlined ||
          habitIcon == Icons.flight_outlined) &&
          habit.checkInRecords.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

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

  /// 健身狂人 - 使用"运动"分类的所有图标
  int get fitnessCheckIns {
    int count = 0;
    for (final habit in habits) {
      if (_isHabitInCategory(habit, '运动')) {
        count += habit.checkInRecords.length;
      }
    }
    return count;
  }

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

  /// 许愿时刻 - 在11:11打卡
  bool get isWishTimeUnlocked {
    for (final habit in habits) {
      for (final record in habit.checkInRecords) {
        if (record.time.length >= 16) {
          final hour = int.tryParse(record.time.substring(11, 13)) ?? 0;
          final minute = int.tryParse(record.time.substring(14, 16)) ?? 0;
          if (hour == 11 && minute == 11) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// 强迫症福音 - 在整点打卡（分钟为00）
  bool get isOnTheHourUnlocked {
    for (final habit in habits) {
      for (final record in habit.checkInRecords) {
        if (record.time.length >= 16) {
          final minute = int.tryParse(record.time.substring(14, 16)) ?? 1;
          if (minute == 0) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// 节日打卡人 - 在特定节日打卡
  bool get isHolidayCheckerUnlocked {
    const holidays = [
      '01-01', // 元旦
      '02-14', // 情人节
      '03-08', // 妇女节
      '04-01', // 愚人节
      '05-01', // 劳动节
      '05-04', // 青年节
      '06-01', // 儿童节
      '10-01', // 国庆节
      '12-25', // 圣诞节
    ];

    for (final habit in habits) {
      for (final record in habit.checkInRecords) {
        if (record.time.length >= 10) {
          final monthDay = record.time.substring(5, 10);
          if (holidays.contains(monthDay)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // ========== 获取成就列表 ==========

  List<Achievement> getAllUnlockedAchievements() {
    return getAllAchievementsWithProgress().where((a) => a.isUnlocked).toList();
  }

  List<Achievement> getAllAchievementsWithProgress() {
    final all = <Achievement>[];

    final total = totalCheckIns;
    final streak = historyMaxStreak;
    final habitCount = habits.length;
    final todayDone = todayCheckIns;
    final missed = totalMissedDays;
    final weekend = weekendCheckIns;
    final fitness = fitnessCheckIns;

    // 打卡次数成就
    all.add(Achievement(id: 'first_checkin', icon: Icons.star_outline, title: '初次打卡', description: '完成第一次打卡', isUnlocked: total >= 1, progress: total >= 1 ? 1.0 : 0.0, current: total, target: 1, category: '打卡次数'));
    all.add(Achievement(id: 'checkin_10', icon: Icons.looks_one_outlined, title: '小试牛刀', description: '累计打卡10次', isUnlocked: total >= 10, progress: (total / 10).clamp(0.0, 1.0), current: total, target: 10, category: '打卡次数'));
    all.add(Achievement(id: 'checkin_50', icon: Icons.looks_two_outlined, title: '渐入佳境', description: '累计打卡50次', isUnlocked: total >= 50, progress: (total / 50).clamp(0.0, 1.0), current: total, target: 50, category: '打卡次数'));
    all.add(Achievement(id: 'checkin_100', icon: Icons.looks_3_outlined, title: '百折不挠', description: '累计打卡100次', isUnlocked: total >= 100, progress: (total / 100).clamp(0.0, 1.0), current: total, target: 100, category: '打卡次数'));
    all.add(Achievement(id: 'checkin_500', icon: Icons.military_tech_outlined, title: '打卡达人', description: '累计打卡500次', isUnlocked: total >= 500, progress: (total / 500).clamp(0.0, 1.0), current: total, target: 500, category: '打卡次数'));
    all.add(Achievement(id: 'checkin_1000', icon: Icons.emoji_events_outlined, title: '传奇人物', description: '累计打卡1000次', isUnlocked: total >= 1000, progress: (total / 1000).clamp(0.0, 1.0), current: total, target: 1000, category: '打卡次数'));

    // 连续打卡成就
    all.add(Achievement(id: 'streak_3', icon: Icons.local_fire_department_outlined, title: '三天热情', description: '连续打卡3天', isUnlocked: streak >= 3, progress: (streak / 3).clamp(0.0, 1.0), current: streak, target: 3, category: '连续打卡'));
    all.add(Achievement(id: 'streak_7', icon: Icons.whatshot_outlined, title: '周末勇士', description: '连续打卡7天', isUnlocked: streak >= 7, progress: (streak / 7).clamp(0.0, 1.0), current: streak, target: 7, category: '连续打卡'));
    all.add(Achievement(id: 'streak_30', icon: Icons.bolt_outlined, title: '月度之星', description: '连续打卡30天', isUnlocked: streak >= 30, progress: (streak / 30).clamp(0.0, 1.0), current: streak, target: 30, category: '连续打卡'));
    all.add(Achievement(id: 'streak_100', icon: Icons.diamond_outlined, title: '习惯大师', description: '连续打卡100天', isUnlocked: streak >= 100, progress: (streak / 100).clamp(0.0, 1.0), current: streak, target: 100, category: '连续打卡'));
    all.add(Achievement(id: 'streak_365', icon: Icons.workspace_premium_outlined, title: '年度传奇', description: '连续打卡365天', isUnlocked: streak >= 365, progress: (streak / 365).clamp(0.0, 1.0), current: streak, target: 365, category: '连续打卡'));

    // 习惯数量成就
    all.add(Achievement(id: 'habit_1', icon: Icons.flag_outlined, title: '新的开始', description: '创建第一个习惯', isUnlocked: habitCount >= 1, progress: habitCount >= 1 ? 1.0 : 0.0, current: habitCount, target: 1, category: '习惯数量'));
    all.add(Achievement(id: 'habit_5', icon: Icons.auto_awesome_outlined, title: '习惯收集者', description: '拥有5个习惯', isUnlocked: habitCount >= 5, progress: (habitCount / 5).clamp(0.0, 1.0), current: habitCount, target: 5, category: '习惯数量'));
    all.add(Achievement(id: 'habit_10', icon: Icons.psychology_outlined, title: '自律达人', description: '拥有10个习惯', isUnlocked: habitCount >= 10, progress: (habitCount / 10).clamp(0.0, 1.0), current: habitCount, target: 10, category: '习惯数量'));

    // 特殊成就
    all.add(Achievement(id: 'perfect_day', icon: Icons.check_circle_outline, title: '完美一天', description: '今日完成所有习惯', isUnlocked: habitCount > 0 && todayDone == habitCount, progress: habitCount > 0 ? (todayDone / habitCount).clamp(0.0, 1.0) : 0.0, current: todayDone, target: habitCount > 0 ? habitCount : 1, category: '特殊成就'));
    all.add(Achievement(id: 'flight', icon: Icons.flight_takeoff_outlined, title: '起飞，芜湖！', description: '航班不可延误', isUnlocked: isFlightUnlocked, progress: isFlightUnlocked ? 1.0 : 0.0, current: isFlightUnlocked ? 1 : 0, target: 1, category: '特殊成就'));
    all.add(Achievement(id: 'missed_50', icon: Icons.hotel_outlined, title: '缺勤大师', description: '累计未打卡50次', isUnlocked: missed >= 50, progress: (missed / 50).clamp(0.0, 1.0), current: missed, target: 50, category: '特殊成就'));
    all.add(Achievement(id: 'night_owl', icon: Icons.nightlight_outlined, title: '夜猫子', description: '在凌晨0-5点打卡', isUnlocked: isNightOwlUnlocked, progress: isNightOwlUnlocked ? 1.0 : 0.0, current: isNightOwlUnlocked ? 1 : 0, target: 1, category: '特殊成就'));
    all.add(Achievement(id: 'early_bird', icon: Icons.wb_sunny_outlined, title: '早起的鸟儿', description: '在早上5-7点打卡', isUnlocked: isEarlyBirdUnlocked, progress: isEarlyBirdUnlocked ? 1.0 : 0.0, current: isEarlyBirdUnlocked ? 1 : 0, target: 1, category: '特殊成就'));
    all.add(Achievement(id: 'weekend_10', icon: Icons.weekend_outlined, title: '周末战士', description: '在周末累计打卡10次', isUnlocked: weekend >= 10, progress: (weekend / 10).clamp(0.0, 1.0), current: weekend, target: 10, category: '特殊成就'));
    all.add(Achievement(id: 'multitasker', icon: Icons.auto_awesome_mosaic_outlined, title: '一心多用', description: '同一天完成5个不同习惯', isUnlocked: isMultitaskerUnlocked, progress: isMultitaskerUnlocked ? 1.0 : 0.0, current: isMultitaskerUnlocked ? 1 : 0, target: 1, category: '特殊成就'));
    all.add(Achievement(id: 'perfect_week', icon: Icons.date_range_outlined, title: '完美一周', description: '连续7天完成所有习惯', isUnlocked: isPerfectWeekUnlocked, progress: isPerfectWeekUnlocked ? 1.0 : 0.0, current: isPerfectWeekUnlocked ? 1 : 0, target: 1, category: '特殊成就'));
    all.add(Achievement(id: 'fitness_30', icon: Icons.fitness_center, title: '健身狂人', description: '运动习惯累计打卡30次', isUnlocked: fitness >= 30, progress: (fitness / 30).clamp(0.0, 1.0), current: fitness, target: 30, category: '特殊成就'));
    all.add(Achievement(id: 'zen_player', icon: Icons.self_improvement, title: '佛系玩家', description: '创建习惯7天后仍未打卡', isUnlocked: isZenPlayerUnlocked, progress: isZenPlayerUnlocked ? 1.0 : 0.0, current: isZenPlayerUnlocked ? 1 : 0, target: 1, category: '特殊成就'));
    all.add(Achievement(id: 'midnight_horror', icon: Icons.dark_mode_outlined, title: '午夜惊魂', description: '在凌晨3点打卡', isUnlocked: isMidnightHorrorUnlocked, progress: isMidnightHorrorUnlocked ? 1.0 : 0.0, current: isMidnightHorrorUnlocked ? 1 : 0, target: 1, category: '特殊成就'));
    all.add(Achievement(id: 'regret_pill', icon: Icons.healing_outlined, title: '后悔药', description: '取消一次打卡', isUnlocked: hasCancelledCheckIn, progress: hasCancelledCheckIn ? 1.0 : 0.0, current: hasCancelledCheckIn ? 1 : 0, target: 1, category: '特殊成就'));
    all.add(Achievement(id: 'habit_terminator', icon: Icons.delete_sweep_outlined, title: '习惯终结者', description: '删除一个习惯', isUnlocked: hasDeletedHabit, progress: hasDeletedHabit ? 1.0 : 0.0, current: hasDeletedHabit ? 1 : 0, target: 1, category: '特殊成就'));
    all.add(Achievement(id: 'wish_time', icon: Icons.auto_awesome, title: '许愿时刻', description: '在11:11打卡', isUnlocked: isWishTimeUnlocked, progress: isWishTimeUnlocked ? 1.0 : 0.0, current: isWishTimeUnlocked ? 1 : 0, target: 1, category: '特殊成就'));
    all.add(Achievement(id: 'on_the_hour', icon: Icons.timer_outlined, title: '强迫症福音', description: '在整点打卡', isUnlocked: isOnTheHourUnlocked, progress: isOnTheHourUnlocked ? 1.0 : 0.0, current: isOnTheHourUnlocked ? 1 : 0, target: 1, category: '特殊成就'));
    all.add(Achievement(id: 'holiday_checker', icon: Icons.celebration, title: '节日打卡人', description: '在特定节日打卡', isUnlocked: isHolidayCheckerUnlocked, progress: isHolidayCheckerUnlocked ? 1.0 : 0.0, current: isHolidayCheckerUnlocked ? 1 : 0, target: 1, category: '特殊成就'));

    return all;
  }
}