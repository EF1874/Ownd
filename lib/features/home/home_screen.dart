import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import '../../data/models/device.dart';
import '../../data/repositories/device_repository.dart';
import '../../shared/widgets/base_card.dart';
import '../../shared/widgets/status_badge.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/app_text_field.dart';

final deviceListProvider = StreamProvider<List<Device>>((ref) {
  final repository = ref.watch(deviceRepositoryProvider);
  return repository.watchAllDevices();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  bool _isGridView = false;
  String _sortBy = 'date_desc'; // date_desc, date_asc, price_desc, price_asc

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Device> _processDevices(List<Device> devices) {
    var result = List<Device>.from(devices);

    // Filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      result = result.where((d) => d.name.toLowerCase().contains(query)).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'date_desc':
        result.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
        break;
      case 'date_asc':
        result.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
        break;
      case 'price_desc':
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'price_asc':
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(deviceListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('我的物品'),
            actions: [
              IconButton(
                icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                onPressed: () => setState(() => _isGridView = !_isGridView),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                onSelected: (v) => setState(() => _sortBy = v),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'date_desc', child: Text('购买日期 (新→旧)')),
                  const PopupMenuItem(value: 'date_asc', child: Text('购买日期 (旧→新)')),
                  const PopupMenuItem(value: 'price_desc', child: Text('价格 (高→低)')),
                  const PopupMenuItem(value: 'price_asc', child: Text('价格 (低→高)')),
                ],
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: AppTextField(
                  controller: _searchController,
                  label: '搜索设备...',
                  onChanged: (_) => setState(() {}),
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSummaryCard(context, devicesAsync),
          ),
          devicesAsync.when(
            data: (devices) {
              final processed = _processDevices(devices);
              
              if (processed.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('暂无设备')),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: _isGridView
                    ? SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _DeviceGridItem(device: processed[index]),
                          childCount: processed.length,
                        ),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _DeviceListItem(device: processed[index]),
                          childCount: processed.length,
                        ),
                      ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, AsyncValue<List<Device>> devicesAsync) {
    return devicesAsync.maybeWhen(
      data: (devices) {
        double totalValue = 0;
        double dailyCost = 0;
        int scrapCount = 0;
        
        for (var d in devices) {
          totalValue += d.price;
          dailyCost += d.dailyCost;
          if (d.status == 'scrap') scrapCount++;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: BaseCard(
            color: Theme.of(context).colorScheme.primary,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem(context, '总资产', '¥${totalValue.toStringAsFixed(0)}', isLight: true),
                      _buildStatItem(context, '日均消耗', '¥${dailyCost.toStringAsFixed(2)}', isLight: true),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('设备总数: ${devices.length}', style: const TextStyle(color: Colors.white70)),
                      Text('已报废: $scrapCount', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn().slideY();
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, {bool isLight = false}) {
    final color = isLight ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color.withOpacity(0.7))),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _DeviceListItem extends ConsumerWidget {
  final Device device;

  const _DeviceListItem({required this.device});

  Color _getCategoryColor(String? categoryName) {
    switch (categoryName) {
      case '手机': return Colors.blue;
      case '电脑': return Colors.indigo;
      case '平板': return Colors.deepPurple;
      case '耳机': return Colors.teal;
      case '相机': return Colors.brown;
      case '游戏机': return Colors.deepOrange;
      case '智能家居': return Colors.cyan;
      case '穿戴设备': return Colors.pinkAccent;
      case '乐器': return Colors.amber;
      case '户外运动': return Colors.green;
      case '书籍': return Colors.lime;
      case '家电': return Colors.orange;
      default: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy-MM-dd');
    final categoryColor = _getCategoryColor(device.category.value?.name);

    return Dismissible(
      key: ValueKey(device.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('确认删除?'),
            content: Text('确定要删除 ${device.name} 吗?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(deviceRepositoryProvider).deleteDevice(device.id);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: BaseCard(
          onTap: () {
            // Edit
          },
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.devices, // TODO: Dynamic icon
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dateFormat.format(device.purchaseDate)} · ${device.platform}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '¥${device.price.toStringAsFixed(0)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusBadge(device),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildStatusBadge(Device device) {
    if (device.status == 'scrap') return const StatusBadge(text: '报废', color: Colors.red);
    if (device.status == 'backup') return const StatusBadge(text: '备用', color: Colors.orange);
    return const StatusBadge(text: '在用', color: Colors.green);
  }
}

class _DeviceGridItem extends ConsumerWidget {
  final Device device;

  const _DeviceGridItem({required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoryColor = _DeviceListItem(device: device)._getCategoryColor(device.category.value?.name);
    
    return BaseCard(
      onTap: () {},
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('编辑'),
                onTap: () {
                  Navigator.pop(ctx);
                  // TODO: Edit
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(deviceRepositoryProvider).deleteDevice(device.id);
                },
              ),
            ],
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.devices, size: 48, color: categoryColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            device.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '¥${device.price.toStringAsFixed(0)}',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
              ),
              Text(
                '¥${device.dailyCost.toStringAsFixed(2)}/天',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.tertiary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DeviceListItem(device: device)._buildStatusBadge(device),
        ],
      ),
    ).animate().fadeIn().scale();
  }
}
