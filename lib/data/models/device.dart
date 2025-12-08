import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'category.dart';
import '../../shared/utils/subscription_utils.dart';

part 'device.g.dart';

enum CycleType { daily, weekly, monthly, quarterly, yearly, oneTime }

@Collection()
class Device {
  Id id = Isar.autoIncrement;

  String uuid = const Uuid().v4();

  late String name;

  double price = 0.0;

  double? firstPeriodPrice;
  double? periodPrice;
  double _totalAccumulatedPrice = 0.0;

  DateTime purchaseDate = DateTime.now();

  DateTime? warrantyEndDate;
  DateTime? backupDate;
  DateTime? scrapDate;
  String? platform;

  final category = IsarLink<Category>();

  @Enumerated(EnumType.name)
  CycleType? cycleType;

  bool isAutoRenew = false;
  DateTime? nextBillingDate;
  int reminderDays = 1;
  bool hasReminder = false;

  List<SubscriptionHistory> history = [];

  double get totalAccumulatedPrice {
    return _totalAccumulatedPrice > 0 ? _totalAccumulatedPrice : price;
  }

  set totalAccumulatedPrice(double value) {
    _totalAccumulatedPrice = value;
  }

  double get dailyCost {
    if (cycleType == null) return 0.0;
    final cost = periodPrice ?? price;
    switch (cycleType!) {
      case CycleType.daily:
        return cost;
      case CycleType.weekly:
        return cost / 7;
      case CycleType.monthly:
        return cost / 30;
      case CycleType.quarterly:
        return cost / 90;
      case CycleType.yearly:
        return cost / 365;
      case CycleType.oneTime:
        return 0.0;
    }
  }

  int get daysUsed {
    final end = scrapDate ?? DateTime.now();
    return end.difference(purchaseDate).inDays;
  }

  String get status {
    if (scrapDate != null && scrapDate!.isBefore(DateTime.now())) {
      return 'scrap';
    }
    if (backupDate != null && backupDate!.isBefore(DateTime.now())) {
      return 'backup';
    }
    return 'active';
  }

  void snapshotCurrentSubscription({
    required DateTime endDate,
    DateTime? recordDate,
  }) {
    if (cycleType == null) return;

    final historyEntry = SubscriptionHistory()
      ..endDate = endDate
      ..price = price
      ..isAutoRenew = false
      ..cycleType = cycleType!
      ..recordDate = recordDate;

    DateTime calculatedStart = endDate.subtract(
      SubscriptionUtils.getDuration(cycleType!),
    );

    if (history.isNotEmpty && history.last.endDate != null) {
      calculatedStart = history.last.endDate!;
    } else {
      if (calculatedStart.isBefore(purchaseDate)) {
        calculatedStart = purchaseDate;
      }
    }

    // Ensure list is growable
    history = history.toList();
    historyEntry.startDate = calculatedStart;
    history.add(historyEntry);
  }
}

@Embedded()
class SubscriptionHistory {
  DateTime? startDate;
  DateTime? endDate;
  double price = 0.0;

  @Enumerated(EnumType.name)
  CycleType cycleType = CycleType.monthly;

  bool isAutoRenew = false;

  DateTime? recordDate;
  String? note;
}
