import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
// Need to add share_plus
// Need to add file_picker
import '../models/category.dart';
import '../models/device.dart';
import 'database_service.dart';

// Note: Need to add share_plus and file_picker to pubspec.yaml

final dataTransferServiceProvider = Provider<DataTransferService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return DataTransferService(dbService.isar);
});

class DataTransferService {
  final Isar _isar;

  DataTransferService(this._isar);

  Future<void> exportData() async {
    // 1. Ensure all data has UUIDs (Migration)
    await _isar.writeTxn(() async {
      final devices = await _isar.devices.where().findAll();
      for (final device in devices) {
        if (device.uuid == null) {
          device.uuid = const Uuid().v4();
          await _isar.devices.put(device);
        }
      }
      final categories = await _isar.categorys.where().findAll();
      for (final category in categories) {
        if (category.uuid == null) {
          category.uuid = const Uuid().v4();
          await _isar.categorys.put(category);
        }
      }
    });

    final devices = await _isar.devices.where().findAll();
    final categories = await _isar.categorys.where().findAll();

    final data = {
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'categories': categories.map((e) => {
        'uuid': e.uuid,
        'name': e.name,
        'iconPath': e.iconPath,
        'isDefault': e.isDefault,
      }).toList(),
      'devices': devices.map((e) => {
        'uuid': e.uuid,
        'name': e.name,
        'categoryName': e.category.value?.name,
        'price': e.price,
        'purchaseDate': e.purchaseDate.toIso8601String(),
        'platform': e.platform,
        'warrantyEndDate': e.warrantyEndDate?.toIso8601String(),
        'scrapDate': e.scrapDate?.toIso8601String(),
        'backupDate': e.backupDate?.toIso8601String(),
      }).toList(),
    };

    final jsonString = jsonEncode(data);
    
    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download/DeviceManager');
    } else {
      final downloadDir = await getDownloadsDirectory();
      if (downloadDir != null) {
        directory = Directory('${downloadDir.path}/DeviceManager');
      }
    }
    
    // Fallback if downloads is not available
    if (directory == null) {
       final docDir = await getApplicationDocumentsDirectory();
       directory = Directory('${docDir.path}/DeviceManager');
    }

    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    final file = File('${directory.path}/user_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonString);
  }

  Future<void> importData() async {
    try {
      // Use FileType.any to allow using third-party file managers and avoid
      // system picker filtering out JSON files on some ROMs.
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        
        // Basic validation
        if (!path.toLowerCase().endsWith('.json')) {
           // We could throw error, but let's try to parse anyway in case of weird naming
           // or just log a warning. For now, let's proceed but be ready to catch json error.
        }

        final file = File(path);
        final jsonString = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(jsonString);

        await _isar.writeTxn(() async {
          // 1. Restore Categories
          final categoryMap = <String, Category>{};
          if (data['categories'] != null) {
            final categoriesList = data['categories'] as List;
            for (final catData in categoriesList) {
              final uuid = catData['uuid'];
              final name = catData['name'];
              
              // Check if exists by UUID first, then by Name
              Category? category;
              if (uuid != null) {
                 category = await _isar.categorys.filter().uuidEqualTo(uuid).findFirst();
              }
              if (category == null) {
                 category = await _isar.categorys.filter().nameEqualTo(name).findFirst();
              }
              
              if (category == null) {
                category = Category()
                  ..uuid = uuid ?? const Uuid().v4()
                  ..name = name
                  ..iconPath = catData['iconPath']
                  ..isDefault = catData['isDefault'] ?? false;
                await _isar.categorys.put(category);
              } else {
                 // Update existing category if needed? For now, just map it.
                 // Maybe update uuid if missing locally
                 if (category.uuid == null && uuid != null) {
                    category.uuid = uuid;
                    await _isar.categorys.put(category);
                 }
              }
              categoryMap[name] = category; // Map by name for device linking (legacy support)
              if (uuid != null) categoryMap[uuid] = category; // Map by UUID
            }
          }

          // 2. Restore Devices
          if (data['devices'] != null) {
            final devicesList = data['devices'] as List;
            for (final devData in devicesList) {
              final uuid = devData['uuid'];
              
              // Check deduplication by UUID
              if (uuid != null) {
                 final existing = await _isar.devices.filter().uuidEqualTo(uuid).findFirst();
                 if (existing != null) {
                    continue; // Skip duplicate
                 }
              }

              final device = Device()
                ..uuid = uuid ?? const Uuid().v4()
                ..name = devData['name']
                ..price = (devData['price'] as num).toDouble()
                ..purchaseDate = DateTime.parse(devData['purchaseDate'])
                ..platform = devData['platform']
                ..warrantyEndDate = devData['warrantyEndDate'] != null ? DateTime.parse(devData['warrantyEndDate']) : null
                ..scrapDate = devData['scrapDate'] != null ? DateTime.parse(devData['scrapDate']) : null
                ..backupDate = devData['backupDate'] != null ? DateTime.parse(devData['backupDate']) : null;
              
              await _isar.devices.put(device);
              
              final catName = devData['categoryName'];
              // Try to link category
              if (catName != null && categoryMap.containsKey(catName)) {
                device.category.value = categoryMap[catName];
                await device.category.save();
              }
            }
          }
        });
      }
    } catch (e) {
      throw 'Import failed: $e';
    }
  }

  Future<String> getBackupDirectoryPath() async {
    if (Platform.isAndroid) {
      return '/storage/emulated/0/Download/DeviceManager';
    }
    final downloadDir = await getDownloadsDirectory();
    final baseDir = downloadDir ?? await getApplicationDocumentsDirectory();
    return '${baseDir.path}/DeviceManager';
  }
}
