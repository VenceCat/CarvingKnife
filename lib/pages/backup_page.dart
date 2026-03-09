import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/habit.dart';
import '../services/achievement_service.dart';
import '../services/auth_service.dart';
import '../services/cloud_backup_service.dart';
import '../services/supabase_service.dart';
import '../ui/app_surfaces.dart';
import '../ui/app_visuals.dart';

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
  bool _isCloudUploading = false;
  bool _isCloudRestoring = false;
  bool _isCloudLoading = false;
  CloudBackupSnapshot? _cloudSnapshot;

  @override
  void initState() {
    super.initState();
    _refreshCloudBackupStatus();
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

  Future<void> _refreshCloudBackupStatus({bool showError = false}) async {
    if (!SupabaseService.isConfigured ||
        SupabaseService.hasInitializationError ||
        AuthService.currentUser == null) {
      if (mounted) {
        setState(() {
          _cloudSnapshot = null;
          _isCloudLoading = false;
        });
      }
      return;
    }

    setState(() => _isCloudLoading = true);
    try {
      final snapshot = await CloudBackupService.fetchLatestBackup();
      if (!mounted) return;
      setState(() => _cloudSnapshot = snapshot);
    } catch (e) {
      if (showError && mounted) {
        _showMessage('获取云备份信息失败：${_readableCloudError(e)}');
      }
    } finally {
      if (mounted) {
        setState(() => _isCloudLoading = false);
      }
    }
  }

  _ParsedBackupData _parseBackupData(Map<String, dynamic> data) {
    if (!data.containsKey('habits') || data['habits'] is! List) {
      throw Exception("无效的备份文件格式");
    }

    final habits = (data['habits'] as List)
        .map((item) => Habit.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();

    final achievementStatusRaw = data['achievementStatus'];
    final achievementStatus = achievementStatusRaw is Map
        ? Map<String, dynamic>.from(achievementStatusRaw)
        : null;

    final backupTime = data['backupTime'] as String?;
    final backupTimeText = backupTime != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(backupTime))
        : '未知';

    return _ParsedBackupData(
      habits: habits,
      backupTimeText: backupTimeText,
      achievementStatus: achievementStatus,
    );
  }

  Future<void> _restoreFromBackupData(
    Map<String, dynamic> data, {
    required String sourceLabel,
    String? bindingEmail,
  }) async {
    final parsed = _parseBackupData(data);
    if (!mounted) return;

    _showImportConfirmDialog(
      parsed.habits,
      parsed.backupTimeText,
      parsed.achievementStatus,
      sourceLabel: sourceLabel,
      bindingEmail: bindingEmail,
    );
  }

  Future<void> _backupToCloud() async {
    setState(() => _isCloudUploading = true);

    try {
      final backupData = await _generateBackupData();
      await CloudBackupService.uploadLatestBackup(backupData);
      await _refreshCloudBackupStatus();
      if (mounted) {
        _showCloudBackupSuccessDialog(
          email: AuthService.currentUser?.email ?? '',
          backupTime: backupData['backupTime'] as String?,
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage('云备份失败：${_readableCloudError(e)}');
      }
    } finally {
      if (mounted) {
        setState(() => _isCloudUploading = false);
      }
    }
  }

  Future<void> _restoreFromCloud() async {
    setState(() => _isCloudRestoring = true);

    try {
      final snapshot = await CloudBackupService.fetchLatestBackup();
      if (snapshot == null) {
        if (mounted) {
          _showMessage('云端暂无可恢复的备份数据。');
        }
        return;
      }

      if (mounted) {
        setState(() => _cloudSnapshot = snapshot);
      }

      await _restoreFromBackupData(
        snapshot.backupData,
        sourceLabel: '云端备份',
        bindingEmail: snapshot.email,
      );
    } catch (e) {
      if (mounted) {
        _showMessage('恢复云备份失败：${_readableCloudError(e)}');
      }
    } finally {
      if (mounted) {
        setState(() => _isCloudRestoring = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _readableCloudError(Object error) {
    final authMessage = AuthService.readableMessage(error);
    if (authMessage != '操作失败，请稍后再试。') {
      return authMessage;
    }

    if (error is StateError) {
      return error.message;
    }

    if (error is PostgrestException) {
      final lower = error.message.toLowerCase();
      if (lower.contains('cloud_backups') &&
          (lower.contains('does not exist') || lower.contains('not find'))) {
        return '云备份数据表还未创建，请先执行 supabase/cloud_backup_schema.sql。';
      }
      return '云服务请求失败，请稍后再试。';
    }

    final message = error.toString();
    if (RegExp(r'[\u4e00-\u9fff]').hasMatch(message)) {
      return message;
    }
    return '请检查网络和云端配置后重试。';
  }

  String _formatDateTime(DateTime value) {
    return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
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
      await _restoreFromBackupData(data, sourceLabel: '备份文件');
    } catch (e) {
      if (mounted) {
        _showMessage("导入失败：$e");
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }

  void _showImportConfirmDialog(
      List<Habit> habits,
      String backupTime,
      Map<String, dynamic>? achievementStatus,
      {
        String sourceLabel = '备份文件',
        String? bindingEmail,
      }) {
    final themeColor = Theme.of(context).colorScheme.primary;
    int totalCheckIns = habits.fold(0, (sum, h) => sum + h.checkInRecords.length);

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
                            "$sourceLabel · 备份于 $backupTime",
                            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                          ),
                          if (bindingEmail != null && bindingEmail.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              "绑定邮箱：$bindingEmail",
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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

  void _showCloudBackupSuccessDialog({
    required String email,
    String? backupTime,
  }) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final backupTimeText = backupTime == null
        ? '刚刚'
        : DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(backupTime));

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
                const SizedBox(height: 24),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_done, color: Colors.green, size: 40),
                ),
                const SizedBox(height: 16),
                const Text(
                  "云备份成功",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  "云端仅保留当前账号最新的一份备份",
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
                          Icon(Icons.mail_outline, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            "绑定邮箱",
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
                        email.isEmpty ? "未获取到邮箱" : email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            "备份时间",
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
                        backupTimeText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
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

  Widget _buildCloudStatusCard({
    required Color themeColor,
    required String email,
  }) {
    final snapshot = _cloudSnapshot;

    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_done_outlined, size: 18, color: themeColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "云端绑定",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              if (_isCloudLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: themeColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            email,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            snapshot == null
                ? "云端暂无备份，上传后会覆盖该账号之前的旧备份。"
                : "最近备份：${_formatDateTime(snapshot.backupTime)} · ${snapshot.habitsCount} 个习惯",
            style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.5),
          ),
          if (snapshot != null) ...[
            const SizedBox(height: 4),
            Text(
              "云端更新时间：${_formatDateTime(snapshot.updatedAt)}",
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCloudHintCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final visuals = AppVisuals.resolve(context);
    final useWallpaper = visuals.useWallpaper;
    final currentUser = AuthService.currentUser;
    final cloudAvailable =
        SupabaseService.isConfigured && !SupabaseService.hasInitializationError;

    return Scaffold(
      backgroundColor: visuals.pageBackgroundColor,
      extendBodyBehindAppBar: true,
      body: AppWallpaperBackground(
        visuals: visuals,
        child: Stack(
          children: [
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
                          color:
                              Colors.black.withValues(alpha: useWallpaper ? 0.08 : 0.05),
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
                    "云备份",
                    style: TextStyle(
                      fontSize: 14,
                      color: useWallpaper ? Colors.grey[700] : Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!SupabaseService.isConfigured)
                    _buildCloudHintCard(
                      icon: Icons.cloud_off_outlined,
                      color: Colors.grey,
                      title: "云服务未配置",
                      description: "当前应用还没有配置 Supabase，暂时无法使用云备份。",
                    )
                  else if (SupabaseService.hasInitializationError)
                    _buildCloudHintCard(
                      icon: Icons.error_outline,
                      color: Colors.redAccent,
                      title: "云服务初始化失败",
                      description:
                          SupabaseService.initializationErrorMessage ?? "请检查云端配置后重试。",
                    )
                  else if (currentUser == null)
                    _buildCloudHintCard(
                      icon: Icons.lock_outline,
                      color: Colors.orange,
                      title: "登录后可用",
                      description: "云备份会和登录邮箱绑定，登录后可上传和恢复最新备份。",
                    )
                  else ...[
                    _buildCloudStatusCard(
                      themeColor: themeColor,
                      email: currentUser.email ?? "未获取到邮箱",
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      icon: Icons.cloud_upload_outlined,
                      title: "备份到云端",
                      subtitle: "上传当前数据并覆盖云端旧备份",
                      color: themeColor,
                      isLoading: _isCloudUploading,
                      enabled: cloudAvailable && !_isCloudRestoring,
                      onTap: _backupToCloud,
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      icon: Icons.cloud_download_outlined,
                      title: "恢复云备份",
                      subtitle: _cloudSnapshot == null
                          ? "云端暂无备份数据"
                          : "恢复 ${_formatDateTime(_cloudSnapshot!.backupTime)} 的最新云备份",
                      color: Colors.orange,
                      isLoading: _isCloudRestoring,
                      enabled: !_isCloudLoading &&
                          !_isCloudUploading &&
                          _cloudSnapshot != null,
                      onTap: _restoreFromCloud,
                    ),
                  ],
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
                    enabled: !_isCloudUploading,
                    onTap: _exportToLocal,
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    icon: Icons.share_outlined,
                    title: "分享备份文件",
                    subtitle: "通过微信、邮件等方式分享",
                    color: themeColor,
                    isLoading: _isExporting,
                    enabled: !_isCloudUploading,
                    onTap: _shareBackup,
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
                    enabled: !_isCloudRestoring,
                    onTap: _importBackup,
                  ),
                  const SizedBox(height: 24),
                  AppGlassCard(
                    padding: const EdgeInsets.all(16),
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
                        _buildTip("• 本地备份文件包含所有习惯和打卡记录"),
                        _buildTip("• 云端仅保留当前登录邮箱最新上传的一份备份"),
                        _buildTip("• 恢复数据会覆盖当前所有数据"),
                        _buildTip("• 更换账号后只能看到对应邮箱的云备份"),
                      ],
                    ),
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
                title: '数据备份',
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
          color: visuals.useGlassEffect
              ? Colors.white.withValues(alpha: visuals.useWallpaper ? 0.34 : 0.62)
              : visuals.useWallpaper
                  ? Colors.white.withValues(alpha: 0.92)
                  : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: visuals.useWallpaper ? 0.08 : 0.04),
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

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isLoading,
    bool enabled = true,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isLoading || !enabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: AppGlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: enabled
                    ? color.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: isLoading
                  ? Padding(
                padding: const EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
                  : Icon(
                      icon,
                      color: enabled ? color : Colors.grey[400],
                      size: 22,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: enabled ? null : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: enabled ? Colors.grey[500] : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: enabled ? Colors.grey[300] : Colors.grey[200],
              size: 20,
            ),
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

class _ParsedBackupData {
  final List<Habit> habits;
  final String backupTimeText;
  final Map<String, dynamic>? achievementStatus;

  const _ParsedBackupData({
    required this.habits,
    required this.backupTimeText,
    required this.achievementStatus,
  });
}
