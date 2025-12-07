import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'category_item.dart';
import 'categories/digital.dart';
import 'categories/subscriptions.dart';
import 'categories/home_appliances.dart';
import 'categories/furniture.dart';
import 'categories/clothing.dart';
import 'categories/personal_care.dart';
import 'categories/sports.dart';
import 'categories/vehicles.dart';
import 'categories/books.dart';
import 'categories/health.dart';
import 'categories/other.dart';

export 'category_item.dart';

class CategoryConfig {
  static final List<CategoryItem> defaultCategories = [
    ...digitalCategories,
    ...subscriptionCategories,
    ...homeApplianceCategories,
    ...furnitureCategories,
    ...clothingCategories,
    ...personalCareCategories,
    ...sportsCategories,
    ...vehiclesCategories,
    ...booksCategories,
    ...healthCategories,
    ...otherCategories,
  ];

  static final Map<String, List<String>> hierarchy = {
    '数码电子': digitalCategories.map((e) => e.name).toList(),
    '虚拟订阅 & 会员': subscriptionCategories.map((e) => e.name).toList(),
    '家用电器': homeApplianceCategories.map((e) => e.name).toList(),
    '家具家装': furnitureCategories.map((e) => e.name).toList(),
    '服饰鞋包': clothingCategories.map((e) => e.name).toList(),
    '个护美妆': personalCareCategories.map((e) => e.name).toList(),
    '户外运动': sportsCategories.map((e) => e.name).toList(),
    '出行交通': vehiclesCategories.map((e) => e.name).toList(),
    '书籍影音': booksCategories.map((e) => e.name).toList(),
    '医疗健康': healthCategories.map((e) => e.name).toList(),
  };

  static final Map<String, IconData> majorCategoryIcons = {
    '数码电子': MdiIcons.cellphone,
    '虚拟订阅 & 会员': MdiIcons.youtubeSubscription,
    '家用电器': MdiIcons.washingMachine,
    '家具家装': MdiIcons.sofa,
    '服饰鞋包': MdiIcons.tshirtCrew,
    '个护美妆': MdiIcons.lipstick,
    '户外运动': MdiIcons.basketball,
    '出行交通': MdiIcons.car,
    '书籍影音': MdiIcons.bookOpenPageVariant,
    '医疗健康': MdiIcons.medicalBag,
  };

  static CategoryItem getItem(String? name) {
    return defaultCategories.firstWhere(
      (item) => item.name == name,
      orElse: () => defaultCategories.last,
    );
  }

  static String getMajorCategory(String? itemName) {
    if (itemName == null) return '其它';
    for (var entry in hierarchy.entries) {
      if (entry.value.contains(itemName)) {
        return entry.key;
      }
    }
    return '其它';
  }
}
