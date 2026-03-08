import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';
import '../ui/app_surfaces.dart';
import '../ui/app_visuals.dart';

class AchievementPage extends StatefulWidget {
  final List<Habit> habits;

  const AchievementPage({super.key, required this.habits});

  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage> {
  bool _isLoading = true;
  Set<String> _permanentlyUnlockedIds = {};
  List<Achievement> _allAchievements = [];

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    // 获取永久解锁的成就ID
    final unlockedIds = await AchievementService.getUnlockedAchievements();

    // 获取所有成就（带进度）
    final checker = await AchievementChecker.create(widget.habits);
    final allAchievements = checker.getAllAchievementsWithProgress();

    // 标记永久解锁的成就为已解锁
    for (int i = 0; i < allAchievements.length; i++) {
      if (unlockedIds.contains(allAchievements[i].id)) {
        final a = allAchievements[i];
        allAchievements[i] = Achievement(
          id: a.id,
          icon: a.icon,
          title: a.title,
          description: a.description,
          isUnlocked: true,
          progress: 1.0,
          current: a.target,
          target: a.target,
          category: a.category,
        );
      }
    }

    if (mounted) {
      setState(() {
        _permanentlyUnlockedIds = unlockedIds;
        _allAchievements = allAchievements;
        _isLoading = false;
      });
    }
  }

  // 获取常规成就
  List<Achievement> get regularAchievements {
    return _allAchievements.where((a) => a.category != '特殊成就').toList();
  }

  // 获取特殊成就（只返回已解锁的）
  List<Achievement> get specialAchievements {
    return _allAchievements.where((a) => a.category == '特殊成就' && a.isUnlocked).toList();
  }

  // 特殊成就总数
  int get totalSpecialAchievements =>
      _allAchievements.where((a) => a.category == '特殊成就').length;

  // 已解锁成就数
  int get unlockedCount {
    return _allAchievements.where((a) => a.isUnlocked).length;
  }

  // 成就总数
  int get totalAchievements => _allAchievements.length;

  // 按类别分组（常规成就）
  Map<String, List<Achievement>> get groupedRegularAchievements {
    final map = <String, List<Achievement>>{};
    for (final achievement in regularAchievements) {
      if (!map.containsKey(achievement.category)) {
        map[achievement.category] = [];
      }
      map[achievement.category]!.add(achievement);
    }
    return map;
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
              top: MediaQuery.of(context).padding.top + 60, // 标题栏高度 + 状态栏高度
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildAchievementContent(themeColor),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppPageTitleBar(
                title: '打卡成就',
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

  /// 构建成就内容（提取出来的方法，保持原逻辑）
  Widget _buildAchievementContent(Color themeColor) {
    final grouped = groupedRegularAchievements;
    final unlockedSpecial = specialAchievements;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 成就概览卡片
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                themeColor.withValues(alpha: 0.8),
                themeColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Color(0xFFFFD700),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "成就进度",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$unlockedCount / $totalAchievements",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(
                          value: totalAchievements > 0 ? unlockedCount / totalAchievements : 0,
                          strokeWidth: 5,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        "${totalAchievements > 0 ? (unlockedCount / totalAchievements * 100).toInt() : 0}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 常规成就（按类别显示）
        ...grouped.entries.map((entry) {
          final category = entry.key;
          final categoryAchievements = entry.value;
          final unlockedInCategory = categoryAchievements.where((a) => a.isUnlocked).length;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppGlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        size: 18,
                        color: themeColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "$unlockedInCategory/${categoryAchievements.length}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...categoryAchievements.map((achievement) =>
                      _buildAchievementListItem(context, achievement, themeColor)),
                ],
              ),
            ),
          );
        }),

        // 特殊成就
        AppGlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.stars_outlined,
                    size: 18,
                    color: Colors.amber[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "特殊成就",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${unlockedSpecial.length}/$totalSpecialAchievements",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (unlockedSpecial.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.lock_outline, size: 32, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        Text(
                          "暂无解锁的特殊成就",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "继续探索，发现隐藏成就吧！",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...unlockedSpecial.map((achievement) =>
                    _buildAchievementListItem(context, achievement, themeColor, isSpecial: true)),
            ],
          ),
        ),
        const SizedBox(height: 100), // 底部留白
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '打卡次数':
        return Icons.check_circle_outline;
      case '连续打卡':
        return Icons.local_fire_department_outlined;
      case '习惯数量':
        return Icons.flag_outlined;
      default:
        return Icons.emoji_events_outlined;
    }
  }

  Widget _buildAchievementListItem(BuildContext context, Achievement achievement, Color themeColor, {bool isSpecial = false}) {
    return GestureDetector(
      onTap: () => _showAchievementDetail(context, achievement, themeColor, isSpecial: isSpecial),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[100]!, width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: achievement.isUnlocked
                    ? (isSpecial ? Colors.amber[50] : themeColor.withValues(alpha: 0.1))
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                achievement.icon,
                size: 24,
                color: achievement.isUnlocked
                    ? (isSpecial ? Colors.amber[600] : themeColor)
                    : Colors.grey[400],
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
                        achievement.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: achievement.isUnlocked ? Colors.black87 : Colors.grey[600],
                        ),
                      ),
                      if (isSpecial && achievement.isUnlocked) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.auto_awesome, size: 14, color: Colors.amber[600]),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  if (!achievement.isUnlocked) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: achievement.progress,
                              minHeight: 4,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                themeColor.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${achievement.current}/${achievement.target}",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (achievement.isUnlocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSpecial ? Colors.amber[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 14, color: isSpecial ? Colors.amber[700] : Colors.green[600]),
                    const SizedBox(width: 2),
                    Text(
                      "已解锁",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isSpecial ? Colors.amber[700] : Colors.green[700],
                      ),
                    ),
                  ],
                ),
              )
            else
              Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showAchievementDetail(BuildContext context, Achievement achievement, Color themeColor, {bool isSpecial = false}) {
    final highlightColor = isSpecial ? Colors.amber[600]! : themeColor;

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
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: achievement.isUnlocked
                        ? highlightColor.withValues(alpha: 0.1)
                        : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    achievement.icon,
                    size: 40,
                    color: achievement.isUnlocked ? highlightColor : Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      achievement.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: achievement.isUnlocked ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                    if (isSpecial && achievement.isUnlocked) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.auto_awesome, size: 20, color: Colors.amber[600]),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  achievement.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "进度",
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                          Text(
                            "${achievement.current}/${achievement.target}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: achievement.isUnlocked ? highlightColor : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: achievement.progress,
                          minHeight: 8,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            achievement.isUnlocked ? highlightColor : highlightColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: achievement.isUnlocked
                        ? (isSpecial ? Colors.amber[50] : Colors.green[50])
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        achievement.isUnlocked ? Icons.check_circle : Icons.hourglass_empty,
                        size: 16,
                        color: achievement.isUnlocked
                            ? (isSpecial ? Colors.amber[700] : Colors.green[600])
                            : Colors.orange[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        achievement.isUnlocked ? "已解锁" : "进行中",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: achievement.isUnlocked
                              ? (isSpecial ? Colors.amber[700] : Colors.green[700])
                              : Colors.orange[700],
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
    );
  }
}
