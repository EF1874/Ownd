import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/device.dart';
import '../../../data/repositories/device_repository.dart';
import '../../../shared/utils/icon_utils.dart';
import '../../../shared/utils/category_utils.dart';
import '../../../shared/config/category_config.dart';
import '../../../shared/config/cost_config.dart';
import '../../../shared/widgets/base_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../add_device/add_device_screen.dart';

class DeviceGridItem extends ConsumerWidget {
  final Device device;

  const DeviceGridItem({super.key, required this.device});

  IconData _getCategoryIcon(String? categoryName) {
    final item = CategoryConfig.getItem(categoryName);
    return IconUtils.getIconData(item.iconPath);
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AddDeviceScreen(device: device)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoryColor = CategoryUtils.getCategoryColor(
      device.category.value?.name,
    );
    final categoryIcon = _getCategoryIcon(device.category.value?.name);
    final dailyCost = device.dailyCost;
    final costColor = CostConfig.getCostColor(dailyCost);

    // Handle adaptive color for null categoryColor
    final effectiveCategoryColor = categoryColor ?? theme.colorScheme.onSurface;

    return BaseCard(
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(
        102,
      ), // 0.4 * 255
      onTap: () => _navigateToEdit(context),
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
                  _navigateToEdit(context);
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
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: effectiveCategoryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(categoryIcon, size: 28, color: effectiveCategoryColor),
          ),
          const SizedBox(height: 8),
          Text(
            device.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${device.daysUsed}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                    fontSize: 20,
                  ),
                ),
                TextSpan(
                  text: '天',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: '¥${device.price.toStringAsFixed(0)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF1581BF),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const WidgetSpan(child: SizedBox(width: 4)),
                TextSpan(
                  text: '¥${dailyCost.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: (costColor ?? theme.colorScheme.onSurfaceVariant)
                        .withValues(alpha: 0.7),
                  ),
                ),
                TextSpan(
                  text: '/天',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.7,
                    ),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 24,
            child: Center(
              child: Transform.scale(
                scale: 0.8,
                child: _buildStatusBadges(device),
              ),
            ),
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
      if (device.backupDate != null) {
        badges.add(const StatusBadge(text: '备用', color: Colors.blue));
      } else if (device.warrantyEndDate != null &&
          device.warrantyEndDate!.isBefore(DateTime.now())) {
        badges.add(const StatusBadge(text: '过期', color: Colors.orange));
      } else {
        badges.add(const StatusBadge(text: '在用', color: Color(0xFF5D3FD3)));
      }
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.end,
      children: badges,
    );
  }
}
