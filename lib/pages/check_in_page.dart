import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'dart:ui' as ui;
import '../models/habit.dart';
import '../services/achievement_service.dart';
import '../services/haptic_service.dart';
import '../widgets/achievement_dialog.dart';
import '../services/habit_icons.dart';
import '../services/widget_service.dart';
import '../widgets/icon_selector.dart';
import 'detail_page.dart';
import '../ui/app_surfaces.dart';
import '../ui/app_tokens.dart';
import '../ui/app_visuals.dart';
import '../widgets/neumorphic_navbar.dart';

class CheckInPageController {
  VoidCallback? _openAddDialog;

  void _attach(VoidCallback callback) {
    _openAddDialog = callback;
  }

  void _detach(VoidCallback callback) {
    if (_openAddDialog == callback) {
      _openAddDialog = null;
    }
  }

  void openAddHabitDialog() {
    _openAddDialog?.call();
  }
}

class CheckInPage extends StatefulWidget {
  final List<Habit> habits;
  final VoidCallback onSave;
  final Function(Habit) onAdd;
  final Function(Habit) onDelete;
  final CheckInPageController? controller;
  final double floatingButtonBottomOffset;

  const CheckInPage({
    super.key,
    required this.habits,
    required this.onSave,
    required this.onAdd,
    required this.onDelete,
    required this.floatingButtonBottomOffset,
    this.controller,
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
    widget.controller?._attach(_showAddDialog);
  }

  @override
  void didUpdateWidget(covariant CheckInPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(_showAddDialog);
      widget.controller?._attach(_showAddDialog);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(_showAddDialog);
    super.dispose();
  }

  void _toggleCheckIn(Habit habit) {
    final todayCount = habit.todayCheckInCount;
    if (todayCount >= habit.dailyTarget) {
      HapticService.lightImpact();
      _showCancelCheckInDialog(habit);
      return;
    }
    HapticService.mediumImpact();
    _completeCheckIn(habit);
  }

  void _completeCheckIn(
    Habit habit, {
    String? initialNote,
    bool showConfirmation = true,
  }) {
    final now = DateTime.now();
    final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    final normalizedNote = initialNote?.trim();
    final record = CheckInRecord(
      time: timeStr,
      note: normalizedNote == null || normalizedNote.isEmpty
          ? null
          : normalizedNote,
    );
    habit.checkInRecords.add(record);
    widget.onSave();
    if (showConfirmation) {
      _showCheckInNoteDialog(habit, record);
    }
  }

  // ignore: unused_element
  void _toggleCheckInLegacy(Habit habit) {
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
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    habit.dailyTarget > 1
                        ? "「${habit.title}」 $todayCount/${habit.dailyTarget} 次"
                        : "「${habit.title}」已完成",
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
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
                    decoration: AppFormStyle.inputDecoration(
                      context,
                      themeColor: themeColor,
                      hintText: "写点什么记录一下吧...",
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
                      label: const Text(
                        "完成",
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isCompleted ? Colors.green : themeColor,
                        foregroundColor: Colors.white,
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
    final todayRecords =
        habit.checkInRecords.where((r) => r.time.startsWith(todayStr)).toList();
    final todayCompletedCount = todayRecords.length;

    if (todayRecords.isEmpty) return;

    // 获取最后一次打卡记录
    final lastRecord = todayRecords.last;
    final checkInTime = DateTime.parse(lastRecord.time);
    final timeStr = DateFormat('HH:mm').format(checkInTime);
    final lastRecordPreview = _buildRecordPreviewText(lastRecord);

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
                      child: const Icon(Icons.undo,
                          color: Colors.orange, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "取消打卡",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            habit.dailyTarget > 1
                                ? "取消最后一次打卡？"
                                : "确定要取消今日的打卡吗？",
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: themeColor.withValues(alpha: 0.2)),
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
                                      "${todayCompletedCount}/${habit.dailyTarget}次",
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
                if (lastRecordPreview.isNotEmpty) ...[
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
                        Icon(Icons.format_quote,
                            size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lastRecordPreview,
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
                    border:
                        Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: Colors.orange[700]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          habit.dailyTarget > 1
                              ? "将取消最后一次打卡记录"
                              : "取消后今日的打卡记录和备注将被删除",
                          style: TextStyle(
                              fontSize: 12, color: Colors.orange[700]),
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
                        ),
                        child:
                            const Text("保留打卡", style: TextStyle(fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await AchievementService.recordCancelledCheckIn();

                          setState(() {
                            // 移除最后一条今日打卡记录
                            final index =
                                habit.checkInRecords.indexOf(lastRecord);
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
                          backgroundColor: AppVisuals.resolve(context)
                                  .useGlassEffect
                              ? Colors.orange.withValues(
                                  alpha:
                                      AppVisuals.resolve(context).useWallpaper
                                          ? 0.74
                                          : 0.9,
                                )
                              : Colors.orange,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppVisuals.resolve(context)
                                  .useGlassEffect
                              ? Colors.orange.withValues(
                                  alpha:
                                      AppVisuals.resolve(context).useWallpaper
                                          ? 0.42
                                          : 0.56,
                                )
                              : Colors.orange.withValues(alpha: 0.6),
                          disabledForegroundColor: Colors.white,
                        ),
                        child:
                            const Text("取消打卡", style: TextStyle(fontSize: 15)),
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
                    decoration: AppFormStyle.inputDecoration(
                      context,
                      themeColor: themeColor,
                      hintText: "写点什么记录一下吧...",
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
    int dailyTarget = 1;

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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxHeight = MediaQuery.of(ctx).size.height * 0.82;
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxHeight),
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
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
                                    child: Icon(
                                        HabitIcons.getIcon(selectedIconIndex),
                                        color: themeColor,
                                        size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "新计划",
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          "开启一个新习惯",
                                          style: TextStyle(
                                              fontSize: 13, color: Colors.grey),
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
                                  setModalState(
                                      () => selectedIconIndex = index);
                                },
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: titleController,
                                onChanged: (value) {
                                  if (errorText != null &&
                                      value.trim().isNotEmpty) {
                                    errorText = null;
                                    setModalState(() {});
                                  }
                                },
                                decoration: AppFormStyle.inputDecoration(
                                  context,
                                  themeColor: themeColor,
                                  labelText: "习惯名称",
                                  hintText: "例如：喝水",
                                  errorText: errorText,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: descController,
                                maxLines: 2,
                                maxLength: 100,
                                decoration: AppFormStyle.inputDecoration(
                                  context,
                                  themeColor: themeColor,
                                  labelText: "描述（选填）",
                                  hintText: "例如：每天喝8杯水",
                                  counterStyle:
                                      TextStyle(color: Colors.grey[400]),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // ===== 新增：每日目标次数选择器 =====
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: AppFormStyle.panelDecoration(
                                  context,
                                  tint: themeColor,
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.repeat,
                                        size: 20, color: Colors.grey[600]),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                              ? themeColor.withValues(
                                                  alpha: 0.1)
                                              : Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(10),
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
                                          color:
                                              themeColor.withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
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
                                    HapticService.mediumImpact();
                                    if (titleController.text.trim().isEmpty) {
                                      errorText = "习惯名称不能为空";
                                      setModalState(() {});
                                    } else {
                                      final habitTitle =
                                          titleController.text.trim();
                                      widget.onAdd(Habit(
                                        id: DateTime.now().toString(),
                                        title: habitTitle,
                                        description: descController.text.trim(),
                                        iconIndex: selectedIconIndex,
                                        dailyTarget: dailyTarget,
                                      ));
                                      Navigator.pop(ctx);
                                      await WidgetService.updateWidget(
                                          widget.habits);

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
                                  label: const Text("创建习惯",
                                      style: TextStyle(fontSize: 16)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeColor,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _reorderHabits(List<Habit> orderedList, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final habit = orderedList.removeAt(oldIndex);
    orderedList.insert(newIndex, habit);
    setState(() {
      for (int i = 0; i < orderedList.length; i++) {
        orderedList[i].sortOrder = i;
      }
    });
    widget.onSave();
  }

  void _togglePin(Habit habit) {
    setState(() => habit.isPinned = !habit.isPinned);
    widget.onSave();
  }

  void _deleteHabit(Habit habit) {
    final themeColor = Theme.of(context).colorScheme.primary;

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
                              habit.checkInRecords.length ==
                                      habit.completedCheckInCount
                                  ? "已打卡 ${habit.completedCheckInCount} 次"
                                  : "已打卡 ${habit.completedCheckInCount} 次 · 共 ${habit.checkInRecords.length} 条记录",
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
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.2)),
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
                              color: Colors.red[700],
                              fontSize: 13,
                              height: 1.4),
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
                          backgroundColor: AppVisuals.resolve(context)
                                  .useGlassEffect
                              ? const Color(0xFFD32F2F).withValues(
                                  alpha:
                                      AppVisuals.resolve(context).useWallpaper
                                          ? 0.74
                                          : 0.9,
                                )
                              : const Color(0xFFD32F2F),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppVisuals.resolve(context)
                                  .useGlassEffect
                              ? const Color(0xFFD32F2F).withValues(
                                  alpha:
                                      AppVisuals.resolve(context).useWallpaper
                                          ? 0.42
                                          : 0.56,
                                )
                              : const Color(0xFFD32F2F).withValues(alpha: 0.6),
                          disabledForegroundColor: Colors.white,
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
    final visuals = AppVisuals.resolve(context);
    final useWallpaper = visuals.useWallpaper;
    final floatingButtonBottomOffset = widget.floatingButtonBottomOffset;
    final listBottomSafeSpace = floatingButtonBottomOffset + 58 + 24;

    return Scaffold(
      backgroundColor: visuals.pageBackgroundColor,
      extendBodyBehindAppBar: true,
      body: AppWallpaperBackground(
        visuals: visuals,
        child: Stack(
          children: [
            // 内容区域 - 从顶部延伸
            ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + 60 + 8,
                20,
                listBottomSafeSpace,
              ),
              children: [
                // 名言区域
                GestureDetector(
                  onTap: () => setState(() =>
                      currentQuote = quotes[Random().nextInt(quotes.length)]),
                  child: AppGlassCard(
                    radius: AppRadii.lg,
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 20,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            size: 18,
                            color: themeColor,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            currentQuote,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: themeColor.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 习惯列表分组
                ..._buildGroupedHabitListWidgets(themeColor, useWallpaper),
              ],
            ),

            // 标题栏
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppPageTitleBar(
                title: '打卡',
                visuals: visuals,
                left: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建分组习惯列表（转为Widget列表）
  List<Widget> _buildGroupedHabitListWidgets(Color themeColor, bool useWallpaper) {
    final todoHabits = widget.habits.where((h) => !h.isTodayCompleted).toList()
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return a.sortOrder.compareTo(b.sortOrder);
      });
    final doneHabits = widget.habits.where((h) => h.isTodayCompleted).toList();

    return [
      // ===== 今日待办 =====
      if (todoHabits.isNotEmpty) ...[
        _buildSectionHeader(
          icon: Icons.radio_button_unchecked,
          title: "今日待办",
          count: todoHabits.length,
          color: themeColor,
          useWallpaper: useWallpaper,
        ),
        const SizedBox(height: 12),
        AppGlassCard(
          radius: 20,
          borderColor: useWallpaper
              ? themeColor.withValues(alpha: 0.14)
              : Colors.grey[100],
          child: ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            padding: EdgeInsets.zero,
            onReorder: (oldIndex, newIndex) =>
                _reorderHabits(todoHabits, oldIndex, newIndex),
            children: todoHabits.asMap().entries.map((entry) {
              final index = entry.key;
              final habit = entry.value;
              return ReorderableDelayedDragStartListener(
                key: Key('reorder_${habit.id}'),
                index: index,
                child: _buildTodoHabitItem(
                  habit,
                  themeColor,
                  isFirst: index == 0,
                  isLast: index == todoHabits.length - 1,
                ),
              );
            }).toList(),
          ),
        ),
      ],

      // ===== 今日已完成 =====
      if (doneHabits.isNotEmpty) ...[
        const SizedBox(height: 24),
        _buildSectionHeader(
          icon: Icons.check_circle_outline,
          title: "今日已完成",
          count: doneHabits.length,
          color: Colors.green,
          useWallpaper: useWallpaper,
        ),
        const SizedBox(height: 12),
        AppGlassCard(
          radius: 20,
          borderColor: useWallpaper
              ? themeColor.withValues(alpha: 0.14)
              : Colors.grey[100],
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
      ],

      // ===== 空状态 =====
      if (widget.habits.isEmpty)
        Padding(
          padding: const EdgeInsets.all(40),
          child: AppGlassCard(
            radius: AppRadii.lg,
            padding: const EdgeInsets.all(24),
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
                  "点击右下角圆形 + 按钮创建第一个习惯",
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
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: AppGlassCard(
            radius: 16,
            borderColor: Colors.green.withValues(alpha: 0.3),
            padding: const EdgeInsets.all(20),
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
    ];
  }

  /// 构建分组标题
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
    required bool useWallpaper,
    Widget? trailing,
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
        if (trailing != null) ...[
          const Spacer(),
          trailing,
        ],
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
            onTap: () {
              HapticService.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => DetailPage(
                    habit: habit,
                    allHabits: widget.habits,
                    onSave: widget.onSave,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.1))),
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
                                if (habit.isPinned) ...[
                                  const SizedBox(width: 4),
                                  Icon(Icons.push_pin,
                                      size: 12, color: Colors.blue[400]),
                                ],
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
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
    final todayRecords =
        habit.checkInRecords.where((r) => r.time.startsWith(todayStr)).toList();

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
                    : Border(
                        bottom: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.1))),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
    final todayRecords =
        habit.checkInRecords.where((r) => r.time.startsWith(todayStr)).toList();
    final todayCompletedCount = todayRecords.length;
    final todayStatusText =
        "今日已打卡 ${todayCompletedCount}${habit.dailyTarget > 1 ? '/${habit.dailyTarget}' : ''} 次";

    showModalBottomSheet(
      context: context,
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
                                  todayStatusText,
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
                        child: Icon(Icons.close,
                            size: 18, color: Colors.grey[500]),
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
                    subtitle:
                        habit.dailyTarget > 1 ? "选择要取消的打卡记录" : "取消今日的打卡记录",
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
                // 置顶选项
                _buildSwipeActionItem(
                  icon:
                      habit.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  title: habit.isPinned ? "取消置顶" : "置顶习惯",
                  subtitle: habit.isPinned ? "取消后将按默认顺序排列" : "置顶后将显示在列表最前面",
                  color: habit.isPinned ? Colors.grey : Colors.blue,
                  onTap: () {
                    Navigator.pop(ctx);
                    _togglePin(habit);
                  },
                ),
                const SizedBox(height: 12),
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
    final visuals = AppVisuals.resolve(context);
    final backgroundColor = visuals.useGlassEffect
        ? Colors.white.withValues(alpha: visuals.useWallpaper ? 0.2 : 0.72)
        : Colors.grey[50];
    final iconBackgroundColor = visuals.useGlassEffect
        ? color.withValues(alpha: visuals.useWallpaper ? 0.18 : 0.12)
        : color.withValues(alpha: 0.1);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
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
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
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
    final recordPreview = _buildRecordPreviewText(record);

    showModalBottomSheet(
      context: context,
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
                if (recordPreview.isNotEmpty) ...[
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
                        Icon(Icons.format_quote,
                            size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            recordPreview,
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
                          backgroundColor: AppVisuals.resolve(context)
                                  .useGlassEffect
                              ? Colors.orange.withValues(
                                  alpha:
                                      AppVisuals.resolve(context).useWallpaper
                                          ? 0.74
                                          : 0.9,
                                )
                              : Colors.orange,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppVisuals.resolve(context)
                                  .useGlassEffect
                              ? Colors.orange.withValues(
                                  alpha:
                                      AppVisuals.resolve(context).useWallpaper
                                          ? 0.42
                                          : 0.56,
                                )
                              : Colors.orange.withValues(alpha: 0.6),
                          disabledForegroundColor: Colors.white,
                        ),
                        child:
                            const Text("取消打卡", style: TextStyle(fontSize: 15)),
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
      builder: (ctx) => AppBottomSheetSurface(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
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
                          child: const Icon(Icons.undo,
                              color: Colors.orange, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "选择要取消的打卡",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "「${habit.title}」今日共 ${records.length} 条记录",
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
                    final recordPreview = _buildRecordPreviewText(record);

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
                                      color:
                                          isMakeUp ? Colors.orange : themeColor,
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
                                              color: Colors.orange
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
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
                                    if (recordPreview.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        recordPreview,
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

  String _buildRecordPreviewText(CheckInRecord record) {
    final note = record.note == null ? '' : _extractDisplayNote(record.note!);
    return note;
  }
}

// ========== 统计页面 ==========
