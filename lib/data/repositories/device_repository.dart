import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device.dart';
import '../services/database_service.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return DeviceRepository(dbService.isar);
});

class DeviceRepository {
  final Isar _isar;

  DeviceRepository(this._isar);

  Future<List<Device>> getAllDevices() async {
    return await _isar.devices.where().findAll();
  }

  Stream<List<Device>> watchAllDevices() {
    return _isar.devices.where().watch(fireImmediately: true);
  }

  Future<void> addDevice(Device device) async {
    await _isar.writeTxn(() async {
      await _isar.devices.put(device);
      await device.category.save();
    });
  }

  Future<void> updateDevice(Device device) async {
    await _isar.writeTxn(() async {
      await _isar.devices.put(device);
      await device.category.save();
    });
  }

  Future<void> deleteDevice(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.devices.delete(id);
    });
  }
}
