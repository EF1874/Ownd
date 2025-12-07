import 'package:flutter/material.dart';
import '../../../shared/config/category_config.dart';

class StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  StickyFilterDelegate({
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: CategoryConfig.hierarchy.length + 1,
              separatorBuilder: (ctx, i) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final isAll = i == 0;
                final key = isAll
                    ? '全部'
                    : CategoryConfig.hierarchy.keys.elementAt(i - 1);
                final isSelected = selectedCategory == (isAll ? null : key);
                return ChoiceChip(
                  label: Text(key),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      onCategorySelected(isAll ? null : key);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 60.0;

  @override
  double get minExtent => 60.0;

  @override
  bool shouldRebuild(covariant StickyFilterDelegate oldDelegate) {
    return oldDelegate.selectedCategory != selectedCategory;
  }
}
