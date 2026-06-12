import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:fl_chart/fl_chart.dart';
import '../models/habit.dart';
import '../services/habit_icons.dart';
import '../ui/app_surfaces.dart';
import '../ui/app_tokens.dart';
import '../ui/app_visuals.dart';
import '../widgets/neumorphic_navbar.dart';

class StatisticsPage extends StatefulWidget {
  final List<Habit> habits;

  const StatisticsPage({super.key, required this.habits});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  // 计算总打卡次数
  int get totalCheckIns {
    return widget.habits.fold(0, (sum, h) => sum + h.completedCheckInCount);
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
    for (final time in habit.checkInTimes) {
      if (time.length >= 10) {
        dates.add(time.substring(0, 10));
      }
    }
    return dates.length;
  }

  // ===== 新增：计算某个习惯的历史最长连续天数 =====
  int _calculateMaxStreakEver(Habit habit) {
    if (habit.completedCheckInCount == 0) return 0;

    // 获取所有打卡日期（去重）
    final dates = <String>{};
    for (final time in habit.checkInTimes) {
      if (time.length >= 10) {
        dates.add(time.substring(0, 10));
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
      final date =
          DateFormat('yyyy-MM-dd').format(weekStart.add(Duration(days: i)));
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
      final date =
          DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, i));
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
        'total': habit.completedCheckInCount,
      });
    }

    ranking.sort((a, b) => (b['streak'] as int).compareTo(a['streak'] as int));
    return ranking;
  }

  int _calculateHabitStreak(Habit habit) {
    if (habit.completedCheckInCount == 0) return 0;

    final dates = <String>{};
    for (final time in habit.checkInTimes) {
      if (time.length >= 10) {
        dates.add(time.substring(0, 10));
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

  // 获取最近30天的完成率趋势数据
  List<Map<String, dynamic>> get completionTrendData {
    final data = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      int completedCount = 0;

      for (final habit in widget.habits) {
        if (habit.checkInTimes.any((t) => t.startsWith(dateStr))) {
          completedCount++;
        }
      }

      final rate = widget.habits.isNotEmpty
          ? completedCount / widget.habits.length
          : 0.0;

      data.add({
        'date': date,
        'rate': rate,
        'count': completedCount,
        'total': widget.habits.length,
      });
    }

    return data;
  }

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
            // 内容区域 - 从顶部延伸，在导航栏下方滚动
            ListView(
              padding: EdgeInsets.fromLTRB(20, navBarHeight + 16, 20, 100),
              children: [
                // 概览卡片
                Row(
                  children: [
                    _buildStatCard(
                      "习惯数",
                      "${widget.habits.length}",
                      Icons.flag_outlined,
                      themeColor,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      "打卡数",
                      "$totalCheckIns",
                      Icons.check_circle_outline,
                      themeColor,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      "连续中",
                      "$currentStreak天",
                      Icons.local_fire_department_outlined,
                      Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      "最长",
                      "$maxTotalDays天",
                      Icons.emoji_events_outlined,
                      Colors.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 30天完成率趋势图
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.show_chart_rounded,
                              size: 20, color: themeColor),
                          const SizedBox(width: 8),
                          Text(
                            "30天完成率趋势",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (completionTrendData.isEmpty || widget.habits.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              '暂无数据',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 180,
                          child: _buildCompletionTrendChart(themeColor),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 打卡热力图
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_month_outlined,
                              size: 20, color: themeColor),
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
                          Text("少",
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[400])),
                          const SizedBox(width: 4),
                          ...List.generate(
                            5,
                            (i) => Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 2),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(
                                    alpha: 0.2 + i * 0.2),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text("多",
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[400])),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 习惯排行
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.leaderboard_outlined,
                              size: 20, color: themeColor),
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
                            child: Text("暂无数据",
                                style:
                                    TextStyle(color: Colors.grey[400])),
                          ),
                        )
                      else
                        ...habitRanking
                            .take(5)
                            .toList()
                            .asMap()
                            .entries
                            .map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final habit = item['habit'] as Habit;
                          final streak = item['streak'] as int;
                          final maxStreak = item['maxStreak'] as int;
                          final totalDays = item['totalDays'] as int;

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
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
                                    borderRadius:
                                        BorderRadius.circular(8),
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
                                    color:
                                        themeColor.withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(10),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                    borderRadius:
                                        BorderRadius.circular(12),
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
              ],
            ),

            // 标题栏
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppPageTitleBar(
                title: '统计',
                visuals: visuals,
                left: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== 新增：统一的卡片样式 =====
  Widget _buildCard({
    required Widget child,
  }) {
    return AppGlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: child,
    );
  }

  // 构建统计卡片
  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: AppGlassCard(
        radius: AppRadii.md,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
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
        final opacity =
            habitCount > 0 ? (count / habitCount).clamp(0.0, 1.0) : 0.0;

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

  // 构建30天完成率趋势图
  Widget _buildCompletionTrendChart(Color themeColor) {
    final data = completionTrendData;
    final spots = data
        .asMap()
        .entries
        .map((entry) => FlSpot(
              entry.key.toDouble(),
              (entry.value['rate'] as double) * 100,
            ))
        .toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 25,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= data.length) return const SizedBox();
                final date = data[value.toInt()]['date'] as DateTime;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('M/d').format(date),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: themeColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: themeColor.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final dataPoint = data[spot.x.toInt()];
                final date = dataPoint['date'] as DateTime;
                final rate = spot.y.toInt();
                final count = dataPoint['count'] as int;
                final total = dataPoint['total'] as int;
                return LineTooltipItem(
                  '${DateFormat('M月d日').format(date)}\n$rate% ($count/$total)',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

// ========== 我的页面 ==========
