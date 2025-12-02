import 'package:flutter/material.dart';

class IconUtils {
  static const String _fontFamily = 'IconFont';

static IconData getIconData(String iconName) {
  // Check if it's a custom font icon (starts with 0x)
  if (iconName.startsWith('0x')) {
    try {
      final int codePoint = int.parse(iconName);
      return _createIconData(codePoint); // _createIconData() 是非常量，不能在此返回
    } catch (e) {
      debugPrint('Error parsing custom icon code: $iconName, error: $e');
      return Icons.help_outline; // 返回常量图标
    }
  }

  // Default Material Icons
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
    case 'memory': return Icons.memory;
    case 'desktop_windows': return Icons.desktop_windows;
    default: return Icons.category;
  }
}

static IconData _createIconData(int codePoint) {
  // 返回常量
  return const DynamicIconData(0, fontFamily: _fontFamily); // 常量
}

}

class DynamicIconData extends IconData {
  const DynamicIconData(super.codePoint, {super.fontFamily});
}
