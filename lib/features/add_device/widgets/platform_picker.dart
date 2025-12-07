import 'package:flutter/material.dart';
import '../../../shared/config/platform_config.dart';

class PlatformPicker extends StatelessWidget {
  final String? selectedPlatform;
  final ValueChanged<String> onPlatformSelected;

  const PlatformPicker({
    super.key,
    this.selectedPlatform,
    required this.onPlatformSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Find the current platform model, or default to custom/unknown
    final selectedModel = PlatformConfig.shoppingPlatforms.firstWhere(
      (p) => p.name == selectedPlatform,
      orElse: () => PlatformModel(
        name: selectedPlatform ?? '',
        icon: Icons.shopping_bag,
        color: Colors.grey,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showPlatformSheet(context),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: '购买平台',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
            child: selectedPlatform != null && selectedPlatform!.isNotEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selectedModel.icon,
                        size: 20,
                        color: selectedModel.color,
                      ),
                      const SizedBox(width: 8),
                      Text(selectedPlatform!),
                    ],
                  )
                : const Text('请选择平台', style: TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );
  }

  void _showPlatformSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        height: 500, // Fixed height for existing scroll
        child: Column(
          children: [
            Text('选择购买平台', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: PlatformConfig.shoppingPlatforms.map((platform) {
                    final isSelected = selectedPlatform == platform.name;
                    return ChoiceChip(
                      label: Text(platform.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          onPlatformSelected(platform.name);
                          Navigator.pop(ctx);
                        }
                      },
                      avatar: Icon(
                        platform.icon,
                        size: 18,
                        color: platform.color,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
