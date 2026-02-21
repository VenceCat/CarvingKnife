import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/habit.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';
import '../services/widget_service.dart';
import '../app.dart';

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
