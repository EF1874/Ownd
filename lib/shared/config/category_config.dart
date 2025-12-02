import 'package:flutter/material.dart';

class CategoryItem {
  final String name;
  final String iconPath;
  final Color color;

  const CategoryItem({
    required this.name,
    required this.iconPath,
    required this.color,
  });
}

class CategoryConfig {
  static const List<CategoryItem> defaultCategories = [
    CategoryItem(name: '手机', iconPath: 'phone_android', color: Colors.blue),
    CategoryItem(name: '笔记本', iconPath: 'computer', color: Colors.indigo),
    CategoryItem(name: '主机', iconPath: 'desktop_windows', color: Colors.indigoAccent),
    CategoryItem(name: '显示器', iconPath: 'monitor', color: Colors.blueAccent),
    CategoryItem(name: '显卡', iconPath: 'memory', color: Colors.blueGrey),
    CategoryItem(name: '平板', iconPath: 'tablet_mac', color: Colors.deepPurple),
    CategoryItem(name: '耳机', iconPath: 'headphones', color: Colors.teal),
    CategoryItem(name: '相机', iconPath: 'camera_alt', color: Colors.brown),
    CategoryItem(name: '游戏机', iconPath: 'videogame_asset', color: Colors.deepOrange),
    CategoryItem(name: '智能家居', iconPath: 'home_mini', color: Colors.cyan),
    CategoryItem(name: '穿戴设备', iconPath: 'watch', color: Colors.pinkAccent),
    CategoryItem(name: '乐器', iconPath: 'piano', color: Colors.amber),
    CategoryItem(name: '户外运动', iconPath: 'directions_bike', color: Colors.green),
    CategoryItem(name: '书籍', iconPath: 'menu_book', color: Colors.lime),
    CategoryItem(name: '家电', iconPath: 'kitchen', color: Colors.orange),
    CategoryItem(name: '生活用品', iconPath: 'local_convenience_store', color: Colors.lightGreen),
    CategoryItem(name: '办公用品', iconPath: 'print', color: Colors.blueGrey),
    CategoryItem(name: '服饰鞋包', iconPath: 'checkroom', color: Colors.purple),
    CategoryItem(name: '美妆护肤', iconPath: 'face', color: Colors.pink),
    CategoryItem(name: '母婴用品', iconPath: 'child_care', color: Colors.redAccent),
    CategoryItem(name: '食品饮料', iconPath: 'restaurant', color: Colors.orangeAccent),
    CategoryItem(name: '家具家装', iconPath: 'chair', color: Colors.brown),
    CategoryItem(name: '汽车用品', iconPath: 'directions_car', color: Colors.grey),
    CategoryItem(name: '虚拟商品', iconPath: 'cloud', color: Colors.lightBlue),
    CategoryItem(name: '其它', iconPath: 'devices_other', color: Colors.blueGrey),
  ];

  static CategoryItem getItem(String? name) {
    return defaultCategories.firstWhere(
      (item) => item.name == name,
      orElse: () => defaultCategories.last,
    );
  }
}
