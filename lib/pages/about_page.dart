import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/haptic_service.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';
import '../ui/app_surfaces.dart';
import '../ui/app_visuals.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _currentVersion = '';
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    final version = await UpdateService.getCurrentVersion();
    if (mounted) {
      setState(() => _currentVersion = version);
    }
  }

  Future<void> _checkUpdate() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);

    try {
      final result = await UpdateService.checkUpdate();

      if (!mounted) return;

      if (result.error != null) {
        _showSnackBar(
          context,
          icon: Icons.error,
          message: result.error!,
          backgroundColor: Colors.red,
        );
      } else if (result.hasUpdate && result.updateInfo != null) {
        await UpdateDialog.show(
          context,
          updateInfo: result.updateInfo!,
          currentVersion: result.currentVersion ?? _currentVersion,
        );
      } else {
        _showSnackBar(
          context,
          icon: Icons.check_circle,
          message: "当前已是最新版本 v${result.currentVersion ?? _currentVersion}",
          backgroundColor: Colors.green,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

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

    return Scaffold(
      backgroundColor: visuals.pageBackgroundColor,
      extendBodyBehindAppBar: true,
      body: AppWallpaperBackground(
        visuals: visuals,
        child: Stack(
          children: [
            Positioned.fill(
            top: MediaQuery.of(context).padding.top + 60,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Logo 卡片容器
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: AppGlassCard(
                      radius: 20,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Logo
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: themeColor.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/images/app_icon.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // 应用名称
                          const Text(
                            "雕刀",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 版本号
                          Text(
                            "版本 ${_currentVersion.isNotEmpty ? _currentVersion : '...'}",
                            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                          ),
                          const SizedBox(height: 20),
                          // Slogan
                          Text(
                            "用极简的方式，雕刻更好的自己",
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 检查更新按钮
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SizedBox(
                      width: double.infinity,
                      child: AppGlassCard(
                        radius: 12,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isChecking ? null : _checkUpdate,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _isChecking
                                      ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: themeColor,
                                    ),
                                  )
                                      : Icon(Icons.refresh, size: 18, color: themeColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isChecking ? "正在检查..." : "检查更新",
                                    style: TextStyle(
                                      color: themeColor,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 信息卡片
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: AppGlassCard(
                      radius: 12,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _infoRow("开发者", "Vence的猫"),
                          const Divider(height: 20),
                          _infoRow("联系邮箱", "vence_cat@163.com"),
                          const Divider(height: 20),
                          _infoRowWithCopy("体验反馈群", "228484290"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppPageTitleBar(
                title: '关于',
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

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
      ],
    );
  }

  Widget _infoRowWithCopy(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            _showSnackBar(
              context,
              icon: Icons.copy,
              message: "群号已复制",
              backgroundColor: Colors.green,
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
              const SizedBox(width: 6),
              Icon(Icons.copy, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ],
    );
  }
}
