import 'package:isar/isar.dart';
import 'category.dart';

part 'device.g.dart';

@collection
class Device {
  Id id = Isar.autoIncrement;

  @Index()
  late String name;

  final category = IsarLink<Category>();

  late double price;

  late DateTime purchaseDate;

  late String platform;

  DateTime? warrantyEndDate;

  DateTime? scrapDate;

  DateTime? backupDate;

  @ignore
  String get status {
    if (scrapDate != null) return 'scrap';
    if (backupDate != null) return 'backup';
    return 'in_use';
  }

  @ignore
  double get dailyCost {
    final endDate = scrapDate ?? DateTime.now();
    final days = endDate.difference(purchaseDate).inDays;
    if (days <= 0) return price;
    return price / days;
  }
}
