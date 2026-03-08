import 'package:flutter/material.dart';
import 'dart:io';
import '../config/theme_config.dart';
import '../services/wallpaper_service.dart';
import '../app.dart';
import '../ui/app_surfaces.dart';
import '../ui/app_visuals.dart';

class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  bool _isLoading = false;

  /// 统一的SnackBar显示方法
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
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final visuals = AppVisuals.resolve(context);

    // 获取壁纸状态
    final appState = HabitApp.of(context);
    final currentTheme = appState?.currentTheme;
    final wallpaperData = appState?.wallpaperData;
    final useWallpaper = appState?.useWallpaper ?? false;
    final glassEffectEnabled = appState?.glassEffectEnabled ?? false;

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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ===== 壁纸设置卡片 =====
                  _buildWallpaperCard(
                    context,
                    appState,
                    wallpaperData,
                    useWallpaper,
                    themeColor,
                  ),

                  const SizedBox(height: 24),

                  _buildGlassEffectCard(
                    appState,
                    glassEffectEnabled,
                    themeColor,
                    useWallpaper,
                  ),

                  const SizedBox(height: 24),

                  // ===== 预览效果 =====
                  _buildPreviewCard(
                    wallpaperData,
                    useWallpaper,
                    themeColor,
                  ),

                  // ===== 预设主题颜色 =====
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        "选择主题颜色",
                        style: TextStyle(
                          fontSize: 14,
                          color: visuals.softTextColor,
                          fontWeight: FontWeight.w500,
                          shadows: visuals.titleShadows,
                        ),
                      ),
                      if (useWallpaper) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "壁纸模式",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 遍历所有主题选项
                  ...ThemeConfig.colorOptions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isSelected =
                        !useWallpaper && currentTheme?.name == option.name;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildThemeOption(
                        appState,
                        index,
                        option,
                        isSelected,
                        useWallpaper,
                      ),
                    );
                  }),

                  const SizedBox(height: 80),
                ],
              ),
            ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppPageTitleBar(
                title: '主题设置',
                visuals: visuals,
                left: 16,
                leading: _buildBackButton(visuals),
              ),
            ),
            if (_isLoading) _buildLoadingOverlay(),
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

  /// 壁纸设置卡片
  ButtonStyle _buildPrimaryButtonStyle({
    required Color color,
  }) {
    final visuals = AppVisuals.resolve(context);
    final backgroundColor = visuals.useGlassEffect
        ? color.withValues(alpha: visuals.useWallpaper ? 0.74 : 0.9)
        : color;
    final disabledBackgroundColor = visuals.useGlassEffect
        ? color.withValues(alpha: visuals.useWallpaper ? 0.42 : 0.56)
        : color.withValues(alpha: 0.6);

    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      disabledBackgroundColor: disabledBackgroundColor,
      disabledForegroundColor: Colors.white,
    );
  }

  Widget _buildWallpaperCard(
      BuildContext context,
      HabitAppState? appState,
      WallpaperData? wallpaperData,
      bool useWallpaper,
      Color themeColor,
      ) {
    return AppGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.wallpaper, color: themeColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "壁纸背景",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "上传壁纸作为全局背景",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 壁纸内容
          if (useWallpaper && wallpaperData != null) ...[
            // 已有壁纸：显示预览
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(wallpaperData.path),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          "使用中",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: _buildButton(
                    icon: Icons.refresh,
                    label: "更换壁纸",
                    color: themeColor,
                    onTap: () => _pickWallpaper(context, appState),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildButton(
                    icon: Icons.delete_outline,
                    label: "移除壁纸",
                    color: const Color(0xFFD32F2F),
                    onTap: () => _removeWallpaper(context, appState),
                  ),
                ),
              ],
            ),
          ] else ...[
            // 无壁纸：显示上传按钮
            Center(
              child: InkWell(
                onTap: () => _pickWallpaper(context, appState),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "点击上传壁纸",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "支持 JPG、PNG 格式",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 预览卡片
  Widget _buildGlassEffectCard(
    HabitAppState? appState,
    bool enabled,
    Color themeColor,
    bool useWallpaper,
  ) {
    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.blur_on, color: themeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '\u6bdb\u73bb\u7483\u6548\u679c',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'BETA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  '\u5f00\u542f\u540e\u5361\u7247\u4e0e\u5bfc\u822a\u6761\u4f7f\u7528\u6a21\u7cca\u900f\u660e\u6837\u5f0f',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            activeColor: themeColor,
            onChanged: (value) async {
              await appState?.setGlassEffectEnabled(value);
              if (!mounted) return;
              setState(() {});
              _showSnackBar(
                context,
                icon: value ? Icons.auto_awesome : Icons.toggle_off_outlined,
                message: value
                    ? '\u5df2\u5f00\u542f\u6bdb\u73bb\u7483\u6548\u679c'
                    : '\u5df2\u5173\u95ed\u6bdb\u73bb\u7483\u6548\u679c',
                backgroundColor: value
                    ? (useWallpaper ? Colors.blueGrey : themeColor)
                    : Colors.grey,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(
      WallpaperData? wallpaperData,
      bool useWallpaper,
      Color themeColor,
      ) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: useWallpaper ? 0.15 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: useWallpaper
                  ? null
                  : Theme.of(context).scaffoldBackgroundColor,
              image: useWallpaper && wallpaperData != null
                  ? DecorationImage(
                image: FileImage(File(wallpaperData.path)),
                fit: BoxFit.cover,
              )
                  : null,
            ),
          ),
          if (useWallpaper)
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          Container(
            height: 180,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "预览效果",
                  style: TextStyle(
                    fontSize: 12,
                    color: useWallpaper ? Colors.white70 : Colors.grey[500],
                    shadows: useWallpaper
                        ? [const Shadow(color: Colors.black38, blurRadius: 2)]
                        : null,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: useWallpaper ? 0.95 : 1),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          color: themeColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "每日运动",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "已坚持 30 天",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: themeColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 主题选项
  Widget _buildThemeOption(
      HabitAppState? appState,
      int index,
      ThemeColorOption option,
      bool isSelected,
      bool useWallpaper,
      ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await appState?.setThemeColor(index);
          if (mounted) setState(() {});
        },
        borderRadius: BorderRadius.circular(14),
        child: AppGlassCard(
          radius: 14,
          borderColor: isSelected ? option.color : null,
          isSelected: isSelected,
          selectedColor: option.color,
          padding: const EdgeInsets.all(16),
          child: Opacity(
            opacity: useWallpaper ? 0.6 : 1.0,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: option.color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: option.color.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 24)
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
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? option.color : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(5, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isSelected ? 28 : 24,
                            height: 8,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: option.color.withValues(alpha: 0.2 + i * 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSelected ? 1 : 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: option.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: option.color,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: _buildPrimaryButtonStyle(color: color),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black38,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("处理中..."),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickWallpaper(BuildContext context, HabitAppState? appState) async {
    if (appState == null) return;

    setState(() => _isLoading = true);
    try {
      final success = await appState.setWallpaper(context);
      if (success && mounted) {
        setState(() {});
        _showSnackBar(
          this.context,
          icon: Icons.check_circle,
          message: "壁纸设置成功",
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          this.context,
          icon: Icons.error,
          message: "设置失败: $e",
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 移除壁纸确认弹窗
  Future<void> _removeWallpaper(BuildContext context, HabitAppState? appState) async {
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
                            "移除壁纸",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "确定要移除当前壁纸吗？",
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 18, color: Colors.red[700]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "移除后所有页面将恢复默认背景样式",
                          style: TextStyle(
                              color: Colors.red[700], fontSize: 12, height: 1.4),
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
                        child: const Text("保留壁纸", style: TextStyle(fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          setState(() => _isLoading = true);
                          await appState?.clearWallpaper();
                          if (!mounted) return;
                          setState(() => _isLoading = false);

                          _showSnackBar(
                            this.context,
                            icon: Icons.check_circle,
                            message: "壁纸已移除",
                            backgroundColor: Colors.green,
                          );
                        },
                        style: _buildPrimaryButtonStyle(
                          color: const Color(0xFFD32F2F),
                        ),
                        child: const Text("移除", style: TextStyle(fontSize: 15)),
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
}
