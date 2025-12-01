import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
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
    final devices = await _isar.devices.where().findAll();
    final categories = await _isar.categorys.where().findAll();

    final data = {
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'categories': categories.map((e) => {
        'name': e.name,
        'iconPath': e.iconPath,
        'isDefault': e.isDefault,
      }).toList(),
      'devices': devices.map((e) => {
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
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/device_manager_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonString);

    // Share the file
    // await Share.shareXFiles([XFile(file.path)], text: 'Device Manager Backup');
    // For now just return path or log, need share_plus
  }

  Future<void> importData() async {
    // Pick file
    // final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    // if (result != null) {
    //   final file = File(result.files.single.path!);
    //   final jsonString = await file.readAsString();
    //   final data = jsonDecode(jsonString);
    //   // Restore logic...
    // }
  }
}
