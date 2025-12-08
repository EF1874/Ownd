import 'package:flutter/material.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/config/platform_config.dart';

class HomeSliverAppBar extends StatelessWidget {
  final TextEditingController searchController;
  final bool isGridView;
  final bool showExpiringList;
  final String sortField;
  final bool isAscending;
  final String? selectedPlatformFilter;

  final ValueChanged<bool> onGridViewChanged;
  final ValueChanged<bool> onShowExpiringChanged;
  final ValueChanged<String> onSortFieldChanged;
  final ValueChanged<bool> onSortOrderChanged;
  final ValueChanged<String?> onPlatformFilterChanged;
  final VoidCallback onSearchChanged;
  final VoidCallback onAddDevice;

  const HomeSliverAppBar({
    super.key,
    required this.searchController,
    required this.isGridView,
    required this.showExpiringList,
    required this.sortField,
    required this.isAscending,
    required this.selectedPlatformFilter,
    required this.onGridViewChanged,
    required this.onShowExpiringChanged,
    required this.onSortFieldChanged,
    required this.onSortOrderChanged,
    required this.onPlatformFilterChanged,
    required this.onSearchChanged,
    required this.onAddDevice,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      expandedHeight: 130,
      title: Row(
        children: [
          const Spacer(),
          // IconButton(
          //   icon: const Icon(Icons.add),
          //   tooltip: '添加物品',
          //   onPressed: onAddDevice,
          // ),
          IconButton(
            icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: isGridView ? '列表视图' : '网格视图',
            onPressed: () => onGridViewChanged(!isGridView),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (v) {
              if (v == 'theme') {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('主题切换暂未实现')));
              } else if (v == 'toggle_expiring') {
                onShowExpiringChanged(!showExpiringList);
              } else if (v == 'platform_filter') {
                _showPlatformFilterDialog(context);
              } else if (v.startsWith('field_')) {
                onSortFieldChanged(v.substring(6));
              } else if (v == 'order_asc') {
                onSortOrderChanged(true);
              } else if (v == 'order_desc') {
                onSortOrderChanged(false);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_expiring',
                child: Row(
                  children: [
                    Icon(
                      showExpiringList
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(showExpiringList ? '隐藏到期列表' : '显示到期列表'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'platform_filter',
                child: Row(
                  children: [
                    Icon(
                      Icons.store,
                      size: 20,
                      color: selectedPlatformFilter != null
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selectedPlatformFilter == null
                          ? '平台筛选'
                          : '平台: $selectedPlatformFilter',
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              // Sort Fields
              CheckedPopupMenuItem(
                value: 'field_date',
                checked: sortField == 'date',
                child: const Text('购买日期'),
              ),
              CheckedPopupMenuItem(
                value: 'field_price',
                checked: sortField == 'price',
                child: const Text('价格'),
              ),
              CheckedPopupMenuItem(
                value: 'field_expiry',
                checked: sortField == 'expiry',
                child: const Text('到期/报废时间'),
              ),
              const PopupMenuDivider(),
              // Sort Order
              PopupMenuItem(
                enabled: false,
                height: 24,
                child: Text(
                  '排序方式',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              CheckedPopupMenuItem(
                value: 'order_desc',
                checked: !isAscending,
                child: const Text('倒序'),
              ),
              CheckedPopupMenuItem(
                value: 'order_asc',
                checked: isAscending,
                child: const Text('顺序'),
              ),

              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(Icons.brightness_6, size: 20),
                    const SizedBox(width: 8),
                    Text('切换主题'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: AppTextField(
            controller: searchController,
            label: '搜索物品...',
            onChanged: (_) => onSearchChanged(),
            prefixIcon: const Icon(Icons.search),
          ),
        ),
      ),
    );
  }

  void _showPlatformFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            width: 300,
            constraints: const BoxConstraints(maxHeight: 400),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 8,
                    left: 16,
                    right: 16,
                  ),
                  child: Text(
                    '选择平台',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        dense: true,
                        title: const Text('全部平台'),
                        leading: selectedPlatformFilter == null
                            ? Icon(
                                Icons.check,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : const SizedBox(width: 20),
                        onTap: () {
                          onPlatformFilterChanged(null);
                          Navigator.pop(context);
                        },
                      ),
                      ...PlatformConfig.shoppingPlatforms.map((p) {
                        final isSelected = selectedPlatformFilter == p.name;
                        return ListTile(
                          dense: true,
                          leading: Icon(p.icon, size: 20, color: p.color),
                          title: Text(p.name),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                          onTap: () {
                            onPlatformFilterChanged(p.name);
                            Navigator.pop(context);
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
