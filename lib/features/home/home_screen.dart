import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/device.dart';
import '../../data/repositories/device_repository.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/base_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/utils/category_utils.dart';
import '../../shared/config/category_config.dart';
import '../../shared/config/cost_config.dart';
import '../add_device/add_device_screen.dart';
import '../navigation/navigation_provider.dart';

final deviceListProvider = StreamProvider((ref) {
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
  Offset _fabPosition = const Offset(0, 0); // Will be initialized in build
  bool _isFabInitialized = false;

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
    final size = MediaQuery.of(context).size;

    // Initialize FAB position to bottom right, but higher to avoid bottom nav
    if (!_isFabInitialized) {
      _fabPosition = Offset(size.width - 72, size.height - 160);
      _isFabInitialized = true;
    }

    return Scaffold(
      body: Stack(
        children: [
          NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction == ScrollDirection.reverse) {
                // Scrolling down, hide nav bar
                ref.read(bottomNavBarVisibleProvider.notifier).state = false;
              } else if (notification.direction == ScrollDirection.forward) {
                // Scrolling up, show nav bar
                ref.read(bottomNavBarVisibleProvider.notifier).state = true;
              }
              return true;
            },
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  expandedHeight: 130, // Increased height to prevent overflow
                  title: Row(
                    children: [
                      const Text('物品列表'),
                      const Spacer(),
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
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(70), // Increased height
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), // Adjusted padding
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
          ),
          Positioned(
            left: _fabPosition.dx,
            top: _fabPosition.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _fabPosition += details.delta;
                  // Clamp position to screen bounds
                  double dx = _fabPosition.dx.clamp(0.0, size.width - 56);
                  double dy = _fabPosition.dy.clamp(0.0, size.height - 56);
                  _fabPosition = Offset(dx, dy);
                });
              },
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AddDeviceScreen()),
                  );
                },
                child: const Icon(Icons.add),
              ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  IconData _getCategoryIcon(String? categoryName) {
    final item = CategoryConfig.getItem(categoryName);
    return _getIconData(item.iconPath);
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'phone_android': return Icons.phone_android;
      case 'computer': return Icons.computer;
      case 'tablet_mac': return Icons.tablet_mac;
      case 'headphones': return Icons.headphones;
      case 'camera_alt': return Icons.camera_alt;
      case 'videogame_asset': return Icons.videogame_asset;
      case 'kitchen': return Icons.kitchen;
      case 'home_mini': return Icons.home_mini;
      case 'watch': return Icons.watch;
      case 'piano': return Icons.piano;
      case 'directions_bike': return Icons.directions_bike;
      case 'menu_book': return Icons.menu_book;
      case 'devices_other': return Icons.devices_other;
      case 'local_convenience_store': return Icons.local_convenience_store;
      case 'print': return Icons.print;
      case 'checkroom': return Icons.checkroom;
      case 'face': return Icons.face;
      case 'child_care': return Icons.child_care;
      case 'restaurant': return Icons.restaurant;
      case 'chair': return Icons.chair;
      case 'directions_car': return Icons.directions_car;
      case 'cloud': return Icons.cloud;
      default: return Icons.category;
    }
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AddDeviceScreen(device: device)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoryColor = CategoryUtils.getCategoryColor(device.category.value?.name);
    final categoryIcon = _getCategoryIcon(device.category.value?.name);
    final dailyCost = device.dailyCost;
    final costColor = CostConfig.getCostColor(dailyCost);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey(device.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (context) => _navigateToEdit(context),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: '编辑',
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            ),
            SlidableAction(
              onPressed: (context) {
                _showDeleteDialog(context, ref);
              },
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: '删除',
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
            ),
          ],
        ),
        child: BaseCard(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
          onTap: () => _navigateToEdit(context),
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
                  categoryIcon,
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
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '¥${device.price.toStringAsFixed(0)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const WidgetSpan(child: SizedBox(width: 8)),
                          TextSpan(
                            text: '¥${dailyCost.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: costColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: '/天',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${device.daysUsed}天',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusBadges(device),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除?'),
        content: Text('确定要删除 ${device.name} 吗?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              ref.read(deviceRepositoryProvider).deleteDevice(device.id);
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadges(Device device) {
    List<Widget> badges = [];

    if (device.status == 'scrap') {
      badges.add(const StatusBadge(text: '报废', color: Colors.grey));
    } else {
      if (device.status == 'backup') {
        badges.add(const StatusBadge(text: '备用', color: Colors.blue));
      }
      if (device.warrantyEndDate != null && device.warrantyEndDate!.isBefore(DateTime.now())) {
        badges.add(const StatusBadge(text: '过保', color: Colors.red));
      }
      // Always show "In Use" if not scrapped, even if over warranty or backup
      badges.add(const StatusBadge(text: '在用', color: Colors.green));
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.end,
      children: badges,
    );
  }
}

class _DeviceGridItem extends ConsumerWidget {
  final Device device;

  const _DeviceGridItem({required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final listItem = _DeviceListItem(device: device);
    final categoryColor = CategoryUtils.getCategoryColor(device.category.value?.name);
    final categoryIcon = listItem._getCategoryIcon(device.category.value?.name);
    final dailyCost = device.dailyCost;
    final costColor = CostConfig.getCostColor(dailyCost);
    
    return BaseCard(
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
      onTap: () => listItem._navigateToEdit(context),
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
                  listItem._navigateToEdit(context);
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
              child: Icon(categoryIcon, size: 48, color: categoryColor),
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
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '¥${device.price.toStringAsFixed(0)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const WidgetSpan(child: SizedBox(width: 4)),
                    TextSpan(
                      text: '¥${dailyCost.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: costColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: '/天',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${device.daysUsed}天',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DeviceListItem(device: device)._buildStatusBadges(device),
        ],
      ),
    ).animate().fadeIn().scale();
  }
}
