import 'package:flutter/material.dart';
import '../services/habit_icons.dart';

class IconSelector extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onSelect;
  final Color themeColor;

  const IconSelector({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.themeColor,
  });

  @override
  State<IconSelector> createState() => _IconSelectorState();
}

class _IconSelectorState extends State<IconSelector> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late IconData _selectedIcon;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: HabitIcons.categories.length,
      vsync: this,
    );
    _selectedIcon = HabitIcons.getIcon(widget.selectedIndex);

    // 定位到选中图标所在的分类
    _scrollToSelectedCategory();
  }

  void _scrollToSelectedCategory() {
    for (int i = 0; i < HabitIcons.categories.length; i++) {
      if (HabitIcons.categories[i].icons.contains(_selectedIcon)) {
        _tabController.animateTo(i);
        break;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 165,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 分类标签栏
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: widget.themeColor,
              unselectedLabelColor: Colors.grey[500],
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
              indicatorColor: widget.themeColor,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              tabs: HabitIcons.categories.map((category) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(category.icon, size: 16),
                      const SizedBox(width: 4),
                      Text(category.name),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          // 图标网格
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: HabitIcons.categories.map((category) {
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: category.icons.length,
                  itemBuilder: (context, index) {
                    final icon = category.icons[index];
                    final isSelected = icon == _selectedIcon;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedIcon = icon);
                        final globalIndex = HabitIcons.getIconIndex(icon);
                        widget.onSelect(globalIndex);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? widget.themeColor.withValues(alpha: 0.15)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          // 移除了未选中状态的边框
                          border: isSelected
                              ? Border.all(color: widget.themeColor, width: 2)
                              : null,
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color: widget.themeColor.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                              : null,
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? widget.themeColor : Colors.grey[600],
                          size: 22,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
