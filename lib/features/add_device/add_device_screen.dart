import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/category.dart';
import '../../data/models/device.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/device_repository.dart';
import '../../features/navigation/navigation_provider.dart';
import '../../shared/config/category_config.dart';
import '../../shared/utils/subscription_utils.dart';
import '../../shared/widgets/app_button.dart';

import 'widgets/basic_info_section.dart';
import 'widgets/date_section.dart';
import 'widgets/subscription_section.dart';
import 'widgets/renew_dialog.dart';

class AddDeviceScreen extends ConsumerStatefulWidget {
  final Device? device;
  const AddDeviceScreen({super.key, this.device});

  @override
  ConsumerState<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends ConsumerState<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtr = TextEditingController();
  final _priceCtr = TextEditingController();
  final _platformCtr = TextEditingController();
  final _catCtr = TextEditingController();
  final _firstPriceCtr = TextEditingController();

  Category? _selectedCategory;
  String? _selectedPlatform;
  bool _isLoading = false;

  DateTime _purchaseDate = DateTime.now();
  DateTime? _warrantyDate;
  DateTime? _backupDate;
  DateTime? _scrapDate;

  CycleType? _cycleType;
  bool _isAutoRenew = false;
  DateTime? _nextBillingDate;
  int _reminderDays = 1;
  bool _hasReminder = false;
  bool _discount = false;
  double _totalAccumulatedPrice = 0.0;

  bool get _isSub =>
      CategoryConfig.getMajorCategory(_selectedCategory?.name) == '虚拟订阅';

  @override
  void initState() {
    super.initState();
    if (widget.device != null) {
      final d = widget.device!;
      _nameCtr.text = d.name;
      _priceCtr.text = d.price.toString();
      _purchaseDate = d.purchaseDate;
      _warrantyDate = d.warrantyEndDate;
      _backupDate = d.backupDate;
      _scrapDate = d.scrapDate;
      _selectedCategory = d.category.value;
      _selectedPlatform = d.platform;
      _cycleType = d.cycleType;
      _isAutoRenew = d.isAutoRenew;
      _nextBillingDate = d.nextBillingDate;
      _reminderDays = d.reminderDays;
      _hasReminder = d.hasReminder;
      _firstPriceCtr.text = d.firstPeriodPrice?.toString() ?? '';
      _discount = d.firstPeriodPrice != null;
      _totalAccumulatedPrice = d.totalAccumulatedPrice;
    }
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _priceCtr.dispose();
    _platformCtr.dispose();
    _catCtr.dispose();
    _firstPriceCtr.dispose();
    super.dispose();
  }

  void _calculateNextBilling() {
    if (_cycleType == null || _cycleType == CycleType.oneTime) return;
    setState(
      () => _nextBillingDate = SubscriptionUtils.calculateNextBillingDate(
        _purchaseDate,
        _cycleType!,
      ),
    );
  }

  Future<void> _pickDate({
    bool isWarranty = false,
    bool isBackup = false,
    bool isScrap = false,
    bool isBilling = false,
  }) async {
    final initialDate = isBilling
        ? (_nextBillingDate ?? DateTime.now())
        : isWarranty
        ? (_warrantyDate ?? DateTime.now())
        : isBackup
        ? (_backupDate ?? DateTime.now())
        : isScrap
        ? (_scrapDate ?? DateTime.now())
        : _purchaseDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CH'),
    );
    if (picked != null) {
      setState(() {
        if (isBilling)
          _nextBillingDate = picked;
        else if (isWarranty)
          _warrantyDate = picked;
        else if (isBackup)
          _backupDate = picked;
        else if (isScrap)
          _scrapDate = picked;
        else {
          _purchaseDate = picked;
          if (_isSub) _calculateNextBilling();
        }
      });
    }
  }

  Future<void> _saveDevice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) return _showSnack('请选择分类');
    if (_isSub && _cycleType == null) return _showSnack('请选择周期类型');

    setState(() => _isLoading = true);
    try {
      Category finalCat = _selectedCategory!;
      if (_selectedCategory?.name == '其它') {
        final custom = _catCtr.text.trim();
        finalCat = await ref
            .read(categoryRepositoryProvider)
            .ensureCategory(custom.isNotEmpty ? custom : '其它');
      }

      final device = widget.device ?? Device();
      device
        ..name = _nameCtr.text.trim().isEmpty
            ? finalCat.name
            : _nameCtr.text.trim()
        ..price = double.parse(_priceCtr.text)
        ..purchaseDate = _purchaseDate
        ..platform =
            (_selectedPlatform == '其它'
                ? _platformCtr.text
                : _selectedPlatform) ??
            ''
        ..warrantyEndDate = _warrantyDate
        ..backupDate = _backupDate
        ..scrapDate = _scrapDate
        ..category.value = finalCat
        ..cycleType = _isSub ? _cycleType : null
        ..isAutoRenew = _isSub ? _isAutoRenew : true
        ..nextBillingDate = _isSub ? _nextBillingDate : null
        ..reminderDays = _isSub ? _reminderDays : 1
        ..hasReminder = _isSub ? _hasReminder : false
        ..firstPeriodPrice = (_isSub && _discount)
            ? double.tryParse(_firstPriceCtr.text)
            : null
        ..periodPrice = _isSub ? double.parse(_priceCtr.text) : null
        ..totalAccumulatedPrice = _totalAccumulatedPrice;

      if (widget.device == null && _isSub) {
        device.totalAccumulatedPrice = device.firstPeriodPrice ?? device.price;
      }

      if (widget.device != null)
        await ref.read(deviceRepositoryProvider).updateDevice(device);
      else
        await ref.read(deviceRepositoryProvider).addDevice(device);

      if (mounted) {
        _showSnack(widget.device != null ? '修改成功' : '添加成功');
        if (Navigator.canPop(context))
          Navigator.of(context).pop();
        else
          context.go('/');
      }
    } catch (e) {
      if (mounted) _showSnack('保存失败: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _showRenewDialog() async {
    if (_cycleType == null) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => RenewDialog(
        initialCycleType: _cycleType!,
        initialPrice: double.tryParse(_priceCtr.text) ?? 0.0,
      ),
    );

    if (result != null && mounted) {
      final newCycle = result['cycle'] as CycleType;
      final renewPrice = result['price'] as double;
      setState(() {
        if (widget.device != null)
          widget.device!.snapshotCurrentSubscription(
            endDate: _nextBillingDate ?? DateTime.now(),
          );
        _cycleType = newCycle;
        _nextBillingDate = SubscriptionUtils.calculateNextBillingDate(
          _nextBillingDate ?? DateTime.now(),
          newCycle,
        );
        _totalAccumulatedPrice += renewPrice;
        _priceCtr.text = renewPrice.toString();
      });
      _showSnack('已更新续费状态，请点击保存');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.device != null ? '编辑物品' : '添加物品')),
      body: Column(
        children: [
          Expanded(
            child: NotificationListener<UserScrollNotification>(
              onNotification: (n) {
                if (n.direction == ScrollDirection.reverse)
                  ref.read(bottomNavBarVisibleProvider.notifier).state = false;
                else if (n.direction == ScrollDirection.forward)
                  ref.read(bottomNavBarVisibleProvider.notifier).state = true;
                return true;
              },
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    BasicInfoSection(
                      nameController: _nameCtr,
                      priceController: _priceCtr,
                      customPlatformController: _platformCtr,
                      customCategoryController: _catCtr,
                      selectedCategory: _selectedCategory,
                      selectedPlatform: _selectedPlatform,
                      onCategorySelected: (c) {
                        setState(() {
                          _selectedCategory = c;
                          if (c != null) {
                            _nameCtr.text = c.name;
                          }
                          if (_isSub) {
                            if (_nextBillingDate == null)
                              _calculateNextBilling();
                            _isAutoRenew = false;
                            _hasReminder = false;
                          }
                        });
                      },
                      onPlatformSelected: (p) =>
                          setState(() => _selectedPlatform = p),
                    ),
                    const SizedBox(height: 16),
                    if (_isSub)
                      SubscriptionSection(
                        priceController: _priceCtr,
                        firstPeriodPriceController: _firstPriceCtr,
                        totalAccumulatedPrice: _totalAccumulatedPrice,
                        purchaseDate: _purchaseDate,
                        nextBillingDate: _nextBillingDate,
                        cycleType: _cycleType,
                        isAutoRenew: _isAutoRenew,
                        hasReminder: _hasReminder,
                        reminderDays: _reminderDays,
                        hasFirstPeriodDiscount: _discount,
                        device: widget.device,
                        onCycleTypeChanged: (v) => setState(() {
                          _cycleType = v;
                          _calculateNextBilling();
                        }),
                        onAutoRenewChanged: (v) => setState(() {
                          _isAutoRenew = v;
                          if (!v) _discount = false;
                        }),
                        onReminderChanged: (v) =>
                            setState(() => _hasReminder = v),
                        onReminderDaysChanged: (v) =>
                            setState(() => _reminderDays = v),
                        onDiscountChanged: (v) => setState(() => _discount = v),
                        onPickDate: () => _pickDate(),
                        onPickBillingDate: () => _pickDate(isBilling: true),
                        onShowRenewDialog: _showRenewDialog,
                      )
                    else
                      DateSection(
                        purchaseDate: _purchaseDate,
                        warrantyDate: _warrantyDate,
                        backupDate: _backupDate,
                        scrapDate: _scrapDate,
                        onPickDate: (w, b, s, billing) => _pickDate(
                          isWarranty: w,
                          isBackup: b,
                          isScrap: s,
                          isBilling: billing,
                        ),
                        onClearBackupDate: (_) =>
                            setState(() => _backupDate = null),
                        onClearScrapDate: (_) =>
                            setState(() => _scrapDate = null),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: AppButton(
                text: '保存',
                onPressed: _saveDevice,
                isLoading: _isLoading,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
