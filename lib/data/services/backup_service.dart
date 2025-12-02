import 'dart:io';
import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';
import '../models/category.dart';
import '../models/device.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return BackupService(dbService.isar);
});

class BackupService {
  final Isar _isar;
  late String _backupDirectory;

  BackupService(this._isar);

  Future<void> init() async {
    if (Platform.isAndroid) {
      _backupDirectory = '/storage/emulated/0/Download/DeviceManager';
    } else {
      final downloadDir = await getDownloadsDirectory();
      final baseDir = downloadDir ?? await getApplicationDocumentsDirectory();
      _backupDirectory = p.join(baseDir.path, 'DeviceManager');
    }

    final backupDir = Directory(_backupDirectory);
    if (!await backupDir.exists()) {
      try {
        await backupDir.create(recursive: true);
      } catch (e) {
        debugPrint('Error creating backup directory: $e');
        // Fallback to internal storage if external creation fails
        final internalDir = await getApplicationDocumentsDirectory();
        _backupDirectory = p.join(internalDir.path, 'backups');
        await Directory(_backupDirectory).create(recursive: true);
      }
    }
  }

  Future<void> createBackup() async {
    try {
      // Fetch all data
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

      final now = DateTime.now();
      final formatter = DateFormat('yyyy-MM-dd');
      final dateStr = formatter.format(now);
      final backupFileName = 'auto_backup_$dateStr.json';
      final backupFile = File(p.join(_backupDirectory, backupFileName));

      await backupFile.writeAsString(jsonString);
      debugPrint('Backup created: ${backupFile.path}');
    } catch (e) {
      debugPrint('Error creating backup: $e');
    }
  }

  Future<void> cleanupOldBackups() async {
    try {
      final backupDir = Directory(_backupDirectory);
      if (!await backupDir.exists()) return;

      final List<FileSystemEntity> files = await backupDir.list().toList();
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      // Regex matches backup_YYYY-MM-DD.json
      final fileNameRegex = RegExp(r'backup_(\d{4}-\d{2}-\d{2})\.json');

      for (final file in files) {
        if (file is File) {
          final filename = p.basename(file.path);
          final match = fileNameRegex.firstMatch(filename);
          
          if (match != null) {
            final dateStr = match.group(1)!;
            try {
              final fileDate = DateTime.parse(dateStr);
              // Compare dates (ignoring time)
              final sevenDaysAgoDateOnly = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);
              if (fileDate.isBefore(sevenDaysAgoDateOnly)) {
                await file.delete();
                debugPrint('Deleted old backup: ${file.path}');
              }
            } catch (e) {
              debugPrint('Error parsing date or deleting file: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up backups: $e');
    }
  }
}
