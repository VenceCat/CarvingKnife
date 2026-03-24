import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io';
import '../models/habit.dart';
import '../services/habit_icons.dart';
import '../services/haptic_service.dart';
import '../ui/app_surfaces.dart';
import '../ui/app_visuals.dart';

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
    final visuals = AppVisuals.resolve(context);
    final useWallpaper = visuals.useWallpaper;

    return Scaffold(
      backgroundColor: visuals.pageBackgroundColor,
      extendBodyBehindAppBar: true,
      body: AppWallpaperBackground(
        visuals: visuals,
        child: Stack(
          children: [
            Positioned.fill(
              top: MediaQuery.of(context).padding.top + 60,
              child: widget.habits.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: AppGlassCard(
                          padding: const EdgeInsets.all(32),
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
                          (habit) => _buildHabitCard(habit, themeColor),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppPageTitleBar(
                title: '提醒设置',
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
      onTap: () {
        HapticService.selection();
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: visuals.useGlassEffect
              ? Colors.white.withValues(alpha: visuals.useWallpaper ? 0.34 : 0.62)
              : visuals.useWallpaper
                  ? Colors.white.withValues(alpha: 0.92)
                  : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: visuals.useWallpaper ? 0.08 : 0.04,
              ),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back_ios_new,
          size: 18,
          color: visuals.useWallpaper ? Colors.black87 : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildHabitCard(Habit habit, Color themeColor) {
    final hasReminder = habit.reminderTime != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppGlassCard(
        borderColor: hasReminder ? themeColor.withValues(alpha: 0.3) : null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticService.lightImpact();
              _showSetReminderFlow(habit);
            },
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
      builder: (ctx) => AppBottomSheetSurface(
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
                      onTap: () {
                        HapticService.selection();
                        Navigator.pop(ctx);
                      },
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
                      HapticService.selection();
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
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: AppDialogSurface(
          radius: 16,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 14),
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        HapticService.selection();
                        Navigator.pop(ctx);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                      ),
                      child: const Text("取消"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticService.mediumImpact();
                        Navigator.pop(ctx);
                        setState(() => habit.reminderTime = timeStr);
                        widget.onSave();
                        _openCalendarIntent(habit, tomorrow);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("确认添加"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 删除提醒确认
  void _showDeleteReminderDialog(Habit habit) {
    showModalBottomSheet(
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
                        onPressed: () {
                          HapticService.selection();
                          Navigator.pop(ctx);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                        ),
                        child:
                        const Text("取消", style: TextStyle(fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          HapticService.mediumImpact();
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
            ),
          ),
        ),
      ],
    );
  }
}
