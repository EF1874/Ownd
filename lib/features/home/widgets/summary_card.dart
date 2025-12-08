import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/models/device.dart';
import '../../../shared/widgets/base_card.dart';
import '../../../shared/config/category_config.dart';

class SummaryCard extends StatelessWidget {
  final List<Device> filteredDevices;
  final List<Device> allDevices;
  final String? categoryName;

  const SummaryCard({
    super.key,
    required this.filteredDevices,
    required this.allDevices,
    this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    // Requirements:
    // 1. If filtered list is empty (e.g. category has no items), show ALL items stats.
    // 2. Title changes based on filter (e.g., "Digital Assets" or "Total Assets").
    // 3. Status label changes (Expired for Subs, Retired for Physical).
    // 4. Value shows single sum (not split).

    final bool useAll = filteredDevices.isEmpty;
    final List<Device> targetDevices = useAll ? allDevices : filteredDevices;

    final String? displayCategory = useAll ? null : categoryName;

    double totalValue = 0;
    double dailyCost = 0;
    int scrapCount = 0;

    final now = DateTime.now();

    for (var d in targetDevices) {
      totalValue += d.price;
      dailyCost += d.dailyCost;

      bool isScrapOrExpired = false;
      if (d.status == 'scrap') {
        isScrapOrExpired = true;
      } else {
        if (CategoryConfig.getMajorCategory(d.category.value?.name) == '虚拟订阅') {
          if (!d.isAutoRenew &&
              d.nextBillingDate != null &&
              d.nextBillingDate!.isBefore(now)) {
            isScrapOrExpired = true;
          }
        }
      }
      if (isScrapOrExpired) scrapCount++;
    }

    // Determine Title
    String title = '总资产';
    if (displayCategory != null && displayCategory != '全部') {
      title = '$displayCategory资产';
    }

    // Determine Scrap Label
    String scrapLabel = '已退役/已到期';
    final majorCat = CategoryConfig.getMajorCategory(displayCategory);
    if (majorCat == '虚拟订阅') {
      scrapLabel = '已到期';
    } else if (majorCat != null) {
      // Assume physical for others
      scrapLabel = '已退役';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: BaseCard(
        color: Theme.of(context).colorScheme.primary,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(
                    context,
                    title,
                    '¥${totalValue.toStringAsFixed(0)}',
                    isLight: true,
                  ),
                  _buildStatItem(
                    context,
                    '日均花费',
                    '¥${dailyCost.toStringAsFixed(2)}',
                    isLight: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '总数: ${targetDevices.length}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    '$scrapLabel: $scrapCount',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value, {
    bool isLight = false,
  }) {
    final color = isLight
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: color.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
