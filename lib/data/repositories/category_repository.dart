import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../../shared/config/category_config.dart';
import 'package:uuid/uuid.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return CategoryRepository(dbService.isar);
});

class CategoryRepository {
  final Isar _isar;

  CategoryRepository(this._isar);

  Future<List<Category>> getAllCategories() async {
    final categories = await _isar.categorys.where().findAll();
    
    // Sort based on the order in CategoryConfig.defaultCategories
    final orderMap = {
      for (var i = 0; i < CategoryConfig.defaultCategories.length; i++)
        CategoryConfig.defaultCategories[i].name: i
    };

    categories.sort((a, b) {
      final indexA = orderMap[a.name] ?? 999;
      final indexB = orderMap[b.name] ?? 999;
      return indexA.compareTo(indexB);
    });

    return categories;
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
    // 1. Get all defined category names from config
    final configNames = CategoryConfig.defaultCategories.map((e) => e.name).toSet();
    
    // 2. Get all existing categories from DB
    final existingCategories = await _isar.categorys.where().findAll();
    
    await _isar.writeTxn(() async {
      // 3. Delete categories that are not in config
      for (final category in existingCategories) {
        if (!configNames.contains(category.name)) {
          await _isar.categorys.delete(category.id);
        }
      }

      // 4. Add or update categories from config
      for (final item in CategoryConfig.defaultCategories) {
        final existing = await _isar.categorys.filter().nameEqualTo(item.name).findFirst();
        
        if (existing == null) {
          // Add new
          final category = Category()
            ..uuid = const Uuid().v4()
            ..name = item.name
            ..iconPath = item.iconPath
            ..isDefault = true;
          await _isar.categorys.put(category);
        } else {
          // Update existing (ensure icon is up to date)
          existing.iconPath = item.iconPath;
          await _isar.categorys.put(existing);
        }
      }
    });
  }
}
