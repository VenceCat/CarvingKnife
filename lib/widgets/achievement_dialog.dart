import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../services/haptic_service.dart';
import '../ui/app_surfaces.dart';

class AchievementUnlockDialog extends StatefulWidget {
  final Achievement achievement;

  const AchievementUnlockDialog({super.key, required this.achievement});

  /// 显示单个成就弹窗
  static Future<void> show(BuildContext context, Achievement achievement) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AchievementUnlockDialog(achievement: achievement);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// 依次显示多个成就弹窗
  static Future<void> showMultiple(BuildContext context, List<Achievement> achievements) async {
    for (final achievement in achievements) {
      await show(context, achievement);
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  @override
  State<AchievementUnlockDialog> createState() => _AchievementUnlockDialogState();
}

class _AchievementUnlockDialogState extends State<AchievementUnlockDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get isSpecial => widget.achievement.category == '特殊成就';

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final highlightColor = isSpecial ? Colors.amber[600]! : themeColor;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: highlightColor.withValues(alpha: 0.22),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: AppDialogSurface(
            radius: 24,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.celebration, color: highlightColor, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      "成就解锁！",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: highlightColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.celebration, color: highlightColor, size: 24),
                  ],
                ),
                const SizedBox(height: 24),

                // 成就图标（带动画）
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              highlightColor.withValues(alpha: 0.8),
                              highlightColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: highlightColor.withValues(alpha: 0.4),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.achievement.icon,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 成就名称
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        widget.achievement.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (isSpecial) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.auto_awesome, size: 20, color: Colors.amber[600]),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // 成就描述
                Text(
                  widget.achievement.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // 类别标签
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: highlightColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.achievement.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: highlightColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 确认按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticService.mediumImpact();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: highlightColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      "太棒了！",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
}
