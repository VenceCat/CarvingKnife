import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';
import '../app.dart';

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Logo 卡片容器
                  Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: _cardDecoration(
                      useWallpaper: useWallpaper,
                      radius: 20,
                    ),
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
                              'assets/images/ic_launcher.png',
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
                  const SizedBox(height: 30),

                  // 检查更新按钮
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: _cardDecoration(
                          useWallpaper: useWallpaper,
                          radius: 12,
                        ),
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
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDecoration(
                      useWallpaper: useWallpaper,
                      radius: 12,
                    ),
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
                  const SizedBox(height: 100),
                ],
              ),
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
                    "关于",
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
