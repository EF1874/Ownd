import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/models/device.dart';
import '../../../data/repositories/device_repository.dart';
import '../../../shared/utils/icon_utils.dart';
import '../../../shared/utils/category_utils.dart';
import '../../../shared/config/category_config.dart';
import '../../../shared/config/cost_config.dart';
import '../../../shared/widgets/base_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/utils/format_utils.dart';
import '../../add_device/add_device_screen.dart';

class DeviceListItem extends ConsumerWidget {
  final Device device;

  const DeviceListItem({super.key, required this.device});

  IconData _getCategoryIcon(String? categoryName) {
    final item = CategoryConfig.getItem(categoryName);
    return IconUtils.getIconData(item.iconPath);
  }

  void navigateToEdit(BuildContext context) {
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

    final isSubscription =
        CategoryConfig.getMajorCategory(device.category.value?.name) == '虚拟订阅';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey(device.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (context) => navigateToEdit(context),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: '编辑',
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
            ),
            SlidableAction(
              onPressed: (context) {
                _showDeleteDialog(context, ref);
              },
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: '删除',
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(12),
              ),
            ),
          ],
        ),
        child: BaseCard(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(
            102,
          ), // 0.4 * 255
          onTap: () => navigateToEdit(context),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: effectiveCategoryColor.withAlpha(25), // 0.1 * 255
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(categoryIcon, color: effectiveCategoryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text:
                                '¥${FormatUtils.formatCurrency(isSubscription && device.totalAccumulatedPrice > 0 ? device.totalAccumulatedPrice : device.price)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18, // Increase slightly for emphasis
                              color: const Color(0xFFcf3d69),
                            ),
                          ),
                          const WidgetSpan(child: SizedBox(width: 8)),
                          TextSpan(
                            text:
                                '¥${FormatUtils.formatCurrency(device.dailyCost)}/天',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  (costColor ??
                                          theme.colorScheme.onSurfaceVariant)
                                      .withValues(alpha: 0.7),
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
                  RichText(
                    text: TextSpan(
                      children: [
                        if (isSubscription) ...[
                          TextSpan(
                            text: '剩余 ',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextSpan(
                            text: () {
                              if (device.nextBillingDate == null) return '0';
                              final diff =
                                  device.nextBillingDate!
                                      .difference(DateTime.now())
                                      .inDays +
                                  1;
                              return (diff < 0 ? 0 : diff).toString();
                            }(),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                              fontSize: 18,
                            ),
                          ),
                          TextSpan(
                            text: ' 天',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ] else ...[
                          TextSpan(
                            text: '使用 ',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextSpan(
                            text: '${device.daysUsed}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                              fontSize: 18,
                            ),
                          ),
                          TextSpan(
                            text: ' 天',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  buildStatusBadges(device),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
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

  Widget buildStatusBadges(Device device) {
    List<Widget> badges = [];

    // Subscription Logic
    final isSubscription =
        CategoryConfig.getMajorCategory(device.category.value?.name) == '虚拟订阅';
    if (isSubscription) {
      if (device.status == 'scrap') {
        badges.add(const StatusBadge(text: '已停用', color: Colors.grey));
      } else {
        final now = DateTime.now();
        final nextDate = device.nextBillingDate;

        if (nextDate != null) {
          final diff = nextDate.difference(now).inDays;
          // Note: difference implies (next - now).
          // If next is tomorrow, diff is 0 or 1 depending on hours.
          // Use .inDays + 1 for "days remaining" inclusive logic or just standard check.
          // Standard check:
          // If nextDate is 2024-12-10, Now is 2024-12-07. Diff is ~3.

          if (device.isAutoRenew) {
            // Auto Renew
            if (diff <= (device.reminderDays > 0 ? device.reminderDays : 3) &&
                diff >= 0) {
              badges.add(const StatusBadge(text: '即将续费', color: Colors.orange));
            } else {
              badges.add(const StatusBadge(text: '自动续费', color: Colors.green));
            }
          } else {
            // Manual
            if (diff < 0) {
              badges.add(const StatusBadge(text: '已过期', color: Colors.grey));
            } else if (diff <=
                (device.reminderDays > 0 ? device.reminderDays : 3)) {
              badges.add(const StatusBadge(text: '即将到期', color: Colors.red));
            }
          }
        } else {
          badges.add(const StatusBadge(text: '无日期', color: Colors.grey));
        }
      }
    } else {
      // Normal Device Logic
      if (device.status == 'scrap') {
        badges.add(const StatusBadge(text: '报废', color: Colors.grey));
      } else {
        if (device.backupDate != null) {
          badges.add(const StatusBadge(text: '备用', color: Colors.blue));
        } else if (device.warrantyEndDate != null &&
            device.warrantyEndDate!.isBefore(DateTime.now())) {
          badges.add(const StatusBadge(text: '过保', color: Colors.orange));
        }
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
