import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';
import '../widgets/achievement_dialog.dart';
import '../services/habit_icons.dart';
import '../widgets/icon_selector.dart';
import '../ui/app_surfaces.dart';
import '../ui/app_visuals.dart';

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
    final visuals = AppVisuals.resolve(context);
    final useWallpaper = visuals.useWallpaper;

    return Scaffold(
      backgroundColor: visuals.pageBackgroundColor,
      extendBodyBehindAppBar: true, // 始终让内容延伸到AppBar下面
      body: AppWallpaperBackground(
        visuals: visuals,
        child: Stack(
          children: [
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
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppPageTitleBar(
                title: '习惯详情',
                visuals: visuals,
                left: 16,
                leading: _buildBackButton(visuals),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(AppVisuals visuals) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: visuals.useWallpaper
              ? Colors.white.withValues(alpha: 0.85)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          boxShadow: visuals.useWallpaper
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
          color: visuals.useWallpaper ? Colors.black87 : Colors.grey[600],
        ),
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

    return AppGlassCard(
      padding: const EdgeInsets.all(20),
      borderColor: themeColor.withValues(alpha: 0.3),
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

    return AppGlassCard(
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
      return AppGlassCard(
        padding: const EdgeInsets.all(40),
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

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppGlassCard(
              padding: const EdgeInsets.all(16),
              borderColor: isMakeUp
                  ? Colors.orange.withValues(alpha: 0.3)
                  : themeColor.withValues(alpha: 0.3),
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
                                        fontSize: 10,
                                        color: Colors.orange,
                                      ),
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
            ),
          );
        }),

        // 如果是过去的日期且还可以继续补卡，显示"继续补卡"按钮
        if (isPast && canMakeUpMore) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: AppGlassCard(
              padding: const EdgeInsets.all(16),
              borderColor: themeColor.withValues(alpha: 0.2),
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
          ),
        ],

        // 如果是今天且还可以继续打卡
        if (isToday && canMakeUpMore) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: AppGlassCard(
              padding: const EdgeInsets.all(16),
              borderColor: themeColor.withValues(alpha: 0.2),
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
            child: AppBottomSheetSurface(
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
        child: AppBottomSheetSurface(
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
        child: AppBottomSheetSurface(
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

}
