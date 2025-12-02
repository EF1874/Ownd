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
        ? CategoryConfig.getItem(selectedCategory!.name).color 
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
          final categoriesAsync = ref.watch(categoriesProvider);
          
          return Container(
            height: 400,
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择分类',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        categoriesAsync.when(
                          data: (categories) => Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: categories.map((category) {
                              final isSelected = selectedCategory?.id == category.id;
                              final itemConfig = CategoryConfig.getItem(category.name);
                              
                              return ChoiceChip(
                                label: Text(category.name),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    onCategorySelected(category);
                                    Navigator.pop(ctx);
                                  }
                                },
                                avatar: Icon(
                                  IconUtils.getIconData(category.iconPath),
                                  size: 18,
                                  color: itemConfig.color,
                                ),
                              );
                            }).toList(),
                          ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => Text('Error: $err'),
                        ),
                        SizedBox(height: 32 + MediaQuery.of(context).padding.bottom),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
