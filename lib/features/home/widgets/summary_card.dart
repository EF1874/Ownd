import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/models/device.dart';
import '../../../shared/widgets/base_card.dart';

class SummaryCard extends StatelessWidget {
  final AsyncValue<List<Device>> devicesAsync;

  const SummaryCard({super.key, required this.devicesAsync});

  @override
  Widget build(BuildContext context) {
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
                        '总资产',
                        '¥${totalValue.toStringAsFixed(0)}',
                        isLight: true,
                      ),
                      _buildStatItem(
                        context,
                        '日均消耗',
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
                        '设备总数: ${devices.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '已报废: $scrapCount',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
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
