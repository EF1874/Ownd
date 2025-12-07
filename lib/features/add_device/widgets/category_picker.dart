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
    Color? displayColor;
    if (selectedCategory != null) {
      // Direct lookup for Major Category color to ensure consistency
      if (CategoryConfig.majorCategoryColors.containsKey(
        selectedCategory!.name,
      )) {
        displayColor =
            CategoryConfig.majorCategoryColors[selectedCategory!.name];
      } else {
        displayColor = CategoryConfig.getItem(selectedCategory!.name).color;
      }
    }
    final selectedColor = displayColor ?? Theme.of(context).colorScheme.primary;

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
  late String _selectedMajor;
  late ScrollController _majorScrollController;
  bool _selectionMade = false;

  @override
  void initState() {
    super.initState();
    _selectedMajor = CategoryConfig.hierarchy.keys.first;
    _majorScrollController = ScrollController();

    if (widget.selectedCategory != null) {
      final name = widget.selectedCategory!.name;
      // Robust check: if name is directly a Major Category, use it.
      if (CategoryConfig.hierarchy.containsKey(name)) {
        _selectedMajor = name;
      } else {
        _selectedMajor = CategoryConfig.getMajorCategory(name);
      }
    }

    // Scroll logic removed as requested
  }

  @override
  void dispose() {
    _majorScrollController.dispose();
    super.dispose();
  }

  void _confirmMajorCategory() {
    // Construct a Category object for the Major Category
    final iconPath =
        CategoryConfig.majorCategoryIconStrings[_selectedMajor] ??
        'MdiIcons.shape';

    final category = Category()
      ..name = _selectedMajor
      ..iconPath = iconPath
      ..id = -2;

    _selectionMade = true;
    widget.onCategorySelected(category);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final majorCategories = CategoryConfig.hierarchy.keys.toList();

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop && !_selectionMade && widget.selectedCategory == null) {
          _confirmMajorCategory();
        } else if (didPop &&
            !_selectionMade &&
            widget.selectedCategory != null) {
          // Check if we navigated away from the original Major selection
          final originalMajor = CategoryConfig.getMajorCategory(
            widget.selectedCategory!.name,
          );
          if (_selectedMajor != originalMajor) {
            _confirmMajorCategory();
          }
        }
      },
      child: Container(
        height: 500,
        padding: const EdgeInsets.only(top: 16),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '选择分类',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            // Level 1: Major Categories (Horizontal List)
            SizedBox(
              height: 48,
              child: ListView.separated(
                controller: _majorScrollController,
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
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedMajor = major);
                    },
                    avatar: Icon(
                      CategoryConfig.majorCategoryIcons[major] ?? Icons.circle,
                      size: 16,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : CategoryConfig.majorCategoryColors[major],
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 32),
            // Level 2: Sub Categories (Grid)
            Expanded(
              child: categoriesAsync.when(
                data: (allCategories) {
                  final subNames =
                      CategoryConfig.hierarchy[_selectedMajor] ?? [];

                  // Reconstruct visual categories with dynamic "Other"
                  var displayNames = List<String>.from(subNames);
                  if (!displayNames.contains('其它')) {
                    displayNames.add('其它');
                  }

                  final visualCategories = displayNames.map((name) {
                    // Try to find existing category from DB
                    final found = allCategories.firstWhere(
                      (c) => c.name == name,
                      orElse: () => Category()
                        ..name = name
                        ..iconPath = CategoryConfig.getItem(name).iconPath
                        ..id = -1,
                    );
                    // Fix icon for Other
                    if (name == '其它') {
                      found.iconPath = 'MdiIcons.dotsHorizontal';
                    }
                    return found;
                  }).toList();

                  if (visualCategories.isEmpty) {
                    return Center(
                      child: Text(
                        '暂无此类目数据',
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: visualCategories.map((category) {
                            final isSameId =
                                widget.selectedCategory?.id == category.id;
                            final isSameName =
                                widget.selectedCategory?.name == category.name;
                            final isSelected =
                                (widget.selectedCategory != null) &&
                                (isSameId ||
                                    (widget.selectedCategory!.id < 0 &&
                                        isSameName));

                            final isOther = category.name == '其它';
                            final itemConfig = isOther
                                ? null
                                : CategoryConfig.getItem(category.name);

                            return ChoiceChip(
                              label: Text(category.name),
                              selected: isSelected,
                              showCheckmark: false,
                              onSelected: (selected) {
                                if (selected) {
                                  _selectionMade = true;
                                  widget.onCategorySelected(category);
                                  Navigator.of(context).pop();
                                } else {
                                  // Deselect -> Return to Major
                                  _confirmMajorCategory();
                                }
                              },
                              avatar: Icon(
                                IconUtils.getIconData(category.iconPath),
                                size: 18,
                                color: isOther
                                    ? Colors.grey
                                    : (itemConfig?.color ??
                                          Theme.of(
                                            context,
                                          ).colorScheme.primary),
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
      ),
    );
  }
}
