import 'package:flutter/material.dart';
import '../category_item.dart';

final List<CategoryItem> vehiclesCategories = [
  const CategoryItem(
    name: '轿车',
    iconPath: 'MdiIcons.car',
    color: Colors.blueGrey,
  ),
  const CategoryItem(
    name: '摩托车',
    iconPath: 'MdiIcons.motorbike',
    color: Colors.red,
  ),
  const CategoryItem(
    name: '电动车/小电驴',
    iconPath: 'MdiIcons.moped',
    color: Colors.green,
  ),
  const CategoryItem(
    name: '车钥匙',
    iconPath: 'MdiIcons.carKey',
    color: Colors.grey,
  ),
  const CategoryItem(
    name: '交通卡/地铁卡',
    iconPath: 'MdiIcons.cardBulleted',
    color: Colors.blue,
  ),
];
