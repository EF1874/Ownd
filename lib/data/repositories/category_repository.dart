import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/database_service.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return CategoryRepository(dbService.isar);
});

class CategoryRepository {
  final Isar _isar;

  CategoryRepository(this._isar);

  Future<List<Category>> getAllCategories() async {
    return await _isar.categorys.where().findAll();
  }

  Future<void> addCategory(Category category) async {
    await _isar.writeTxn(() async {
      await _isar.categorys.put(category);
    });
  }

  Future<void> deleteCategory(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.categorys.delete(id);
    });
  }
  
  Future<void> initDefaultCategories() async {
    final count = await _isar.categorys.count();
    if (count == 0) {
      final defaults = [
        Category()..name = '手机'..iconPath = 'phone_android'..isDefault = true,
        Category()..name = '电脑'..iconPath = 'computer'..isDefault = true,
        Category()..name = '平板'..iconPath = 'tablet_mac'..isDefault = true,
        Category()..name = '耳机'..iconPath = 'headphones'..isDefault = true,
        Category()..name = '相机'..iconPath = 'camera_alt'..isDefault = true,
        Category()..name = '游戏机'..iconPath = 'videogame_asset'..isDefault = true,
        Category()..name = '智能家居'..iconPath = 'home_mini'..isDefault = true,
        Category()..name = '穿戴设备'..iconPath = 'watch'..isDefault = true,
        Category()..name = '乐器'..iconPath = 'piano'..isDefault = true,
        Category()..name = '户外运动'..iconPath = 'directions_bike'..isDefault = true,
        Category()..name = '书籍'..iconPath = 'menu_book'..isDefault = true,
        Category()..name = '家电'..iconPath = 'kitchen'..isDefault = true,
        Category()..name = '其它'..iconPath = 'devices_other'..isDefault = true,
      ];
      
      await _isar.writeTxn(() async {
        await _isar.categorys.putAll(defaults);
      });
    }
  }
}
