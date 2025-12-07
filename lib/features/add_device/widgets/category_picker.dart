import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/category.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../shared/config/category_config.dart';
import '../../../shared/utils/icon_utils.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.read(categoryRepositoryProvider).getAllCategories();
});

class CategoryPicker extends ConsumerWidget {
  final Category? selectedCategory;
  final ValueChanged<Category> onCategorySelected;

  const CategoryPicker({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  // _getIconData removed, using IconUtils.getIconData instead

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedColor = selectedCategory != null
        ? (CategoryConfig.getItem(selectedCategory!.name).color ??
              Theme.of(context).colorScheme.primary)
        : Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showCategorySheet(context, ref),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: '分类',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
            child: selectedCategory != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        IconUtils.getIconData(selectedCategory!.iconPath),
                        size: 20,
                        color: selectedColor,
                      ),
                      const SizedBox(width: 8),
                      Text(selectedCategory!.name),
                    ],
                  )
                : const Text('请选择分类', style: TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );
  }

  void _showCategorySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          return _CategorySheetContent(
            onCategorySelected: (cat) {
              onCategorySelected(cat);
              Navigator.pop(ctx);
            },
            selectedCategory: selectedCategory,
          );
        },
      ),
    );
  }
}

class _CategorySheetContent extends ConsumerStatefulWidget {
  final ValueChanged<Category> onCategorySelected;
  final Category? selectedCategory;

  const _CategorySheetContent({
    required this.onCategorySelected,
    this.selectedCategory,
  });

  @override
  ConsumerState<_CategorySheetContent> createState() =>
      _CategorySheetContentState();
}

class _CategorySheetContentState extends ConsumerState<_CategorySheetContent> {
  String _selectedMajor = CategoryConfig.hierarchy.keys.first;

  @override
  void initState() {
    super.initState();
    if (widget.selectedCategory != null) {
      _selectedMajor = CategoryConfig.getMajorCategory(
        widget.selectedCategory!.name,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final majorCategories = CategoryConfig.hierarchy.keys.toList();

    return Container(
      height: 500, // Increased height
      padding: const EdgeInsets.only(top: 16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('选择分类', style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 16),
          // Level 1: Major Categories (Horizontal List)
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: majorCategories.length,
              separatorBuilder: (ctx, i) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final major = majorCategories[i];
                final isSelected = major == _selectedMajor;
                return ChoiceChip(
                  label: Text(major),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedMajor = major);
                  },
                  showCheckmark: false,
                  avatar: Icon(
                    CategoryConfig.majorCategoryIcons[major] ?? Icons.circle,
                    size: 16,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : null,
                  ),
                );
              },
            ),
          ),
          const Divider(height: 32),
          // Level 2: Sub-categories
          Expanded(
            child: categoriesAsync.when(
              data: (allCategories) {
                // Get sub-categories for selected major
                final subNames = CategoryConfig.hierarchy[_selectedMajor] ?? [];

                // Filter actual Category entities that match the names
                // Also optionally create transient ones if not found?
                // For this refactor, we assume DB has populated categories matching config.
                // If not, we might miss some. But for "Add Device", we usually rely on pre-seeded data.
                final visualCategories = allCategories
                    .where((c) => subNames.contains(c.name))
                    .toList();

                // Append "Other" option
                visualCategories.add(
                  Category()
                    ..name = '其它'
                    ..iconPath = 'MdiIcons.dotsHorizontal'
                    ..id = -1, // Temporary ID
                );

                if (visualCategories.isEmpty && subNames.isNotEmpty) {
                  // Fallback: If DB doesn't have them, we should probably allow selecting them anyway?
                  // But current architecture expects an existing Category entity for the ID.
                  // Showing a warning or just "all" might be safer if data is missing.
                  // For now, let's show all that match the names.
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (visualCategories.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            '暂无此类目数据',
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: visualCategories.map((category) {
                          final isSelected =
                              widget.selectedCategory?.id == category.id;
                          final isOther = category.name == '其它';
                          final itemConfig = isOther
                              ? null
                              : CategoryConfig.getItem(category.name);

                          return ChoiceChip(
                            label: Text(category.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                widget.onCategorySelected(category);
                              }
                            },
                            avatar: Icon(
                              IconUtils.getIconData(category.iconPath),
                              size: 18,
                              color: isOther
                                  ? Colors.grey
                                  : (itemConfig?.color ??
                                        Theme.of(context).colorScheme.primary),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(
                        height: 32 + MediaQuery.of(context).padding.bottom,
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
