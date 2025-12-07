import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/device.dart';
import '../../data/repositories/device_repository.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/config/category_config.dart';
import '../../data/services/preferences_service.dart';
import '../add_device/add_device_screen.dart';
import '../navigation/navigation_provider.dart';
import 'widgets/summary_card.dart';
import 'widgets/device_list_item.dart';
import 'widgets/device_grid_item.dart';
import 'widgets/sticky_filter_delegate.dart';

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

  String? _selectedFilterCategory;

  @override
  void initState() {
    super.initState();
    // Initialize state from preferences
    final prefs = ref.read(preferencesServiceProvider);
    _isGridView = prefs.isGridView;
    _sortBy = prefs.sortBy;
  }

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
      result = result
          .where((d) => d.name.toLowerCase().contains(query))
          .toList();
    }

    // Category Filter
    if (_selectedFilterCategory != null) {
      result = result.where((d) {
        final major = CategoryConfig.getMajorCategory(d.category.value?.name);
        return major == _selectedFilterCategory;
      }).toList();
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
                      const Text('Canghe 物历'),
                      const Spacer(),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.menu),
                        onSelected: (v) {
                          if (v == 'theme') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('主题切换暂未实现')),
                            );
                          } else if (v.startsWith('sort_')) {
                            // Sort logic
                            final sortKey = v.substring(5);
                            setState(() => _sortBy = sortKey);
                            ref
                                .read(preferencesServiceProvider)
                                .setSortBy(sortKey);
                          } else if (v == 'view_toggle') {
                            setState(() => _isGridView = !_isGridView);
                            ref
                                .read(preferencesServiceProvider)
                                .setGridView(_isGridView);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'view_toggle',
                            child: Row(
                              children: [
                                Icon(
                                  _isGridView
                                      ? Icons.view_list
                                      : Icons.grid_view,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(_isGridView ? '列表视图' : '网格视图'),
                              ],
                            ),
                          ),
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
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'sort_date_desc',
                            child: Text('购买日期 (新→旧)'),
                          ),
                          const PopupMenuItem(
                            value: 'sort_date_asc',
                            child: Text('购买日期 (旧→新)'),
                          ),
                          const PopupMenuItem(
                            value: 'sort_price_desc',
                            child: Text('价格 (高→低)'),
                          ),
                          const PopupMenuItem(
                            value: 'sort_price_asc',
                            child: Text('价格 (低→高)'),
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
                        controller: _searchController,
                        label: '搜索设备...',
                        onChanged: (_) => setState(() {}),
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SummaryCard(devicesAsync: devicesAsync),
                ),
                // Sticky Header
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickyFilterDelegate(
                    selectedCategory: _selectedFilterCategory,
                    onCategorySelected: (category) {
                      setState(() => _selectedFilterCategory = category);
                    },
                  ),
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
                                (context, index) =>
                                    DeviceGridItem(device: processed[index]),
                                childCount: processed.length,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.75,
                                  ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) =>
                                    DeviceListItem(device: processed[index]),
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
                    MaterialPageRoute(
                      builder: (context) => const AddDeviceScreen(),
                    ),
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
}
