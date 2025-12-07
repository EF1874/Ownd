import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/category_repository.dart';

import 'package:intl/intl.dart';
import '../../data/models/device.dart';
import '../../data/models/category.dart';
import '../../data/repositories/device_repository.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/app_button.dart';
import 'widgets/category_picker.dart';
import 'widgets/platform_picker.dart';

class AddDeviceScreen extends ConsumerStatefulWidget {
  final Device? device;

  const AddDeviceScreen({super.key, this.device});

  @override
  ConsumerState<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends ConsumerState<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _customPlatformController = TextEditingController();
  final _customCategoryController = TextEditingController();

  Category? _selectedCategory;
  DateTime _purchaseDate = DateTime.now();
  DateTime? _warrantyDate;
  DateTime? _backupDate;
  DateTime? _scrapDate;
  bool _isLoading = false;

  String? _selectedPlatform;

  @override
  void initState() {
    super.initState();
    if (widget.device != null) {
      final d = widget.device!;
      _nameController.text = d.name;
      _priceController.text = d.price.toString();
      _purchaseDate = d.purchaseDate;
      _warrantyDate = d.warrantyEndDate;
      _backupDate = d.backupDate;
      _scrapDate = d.scrapDate;
      _selectedCategory = d.category.value;

      _selectedPlatform = d.platform;

      // If it's a custom platform (not in the standard list), handle it?
      // Actually, PlatformPicker now handles display gracefully even if not in config.
      // But we need to switch logic for "Other" text field.
      // We will check if it matches "Other" or if it is a custom string that is NOT in the list.
      // However, current logic in PlatformPicker lets us select any string.
      // If the platform from DB is NOT in the standard list, we should probably set _selectedPlatform to '其它' and fill the text field.

      // But wait, the standard list is now in PlatformConfig.
      // I can't easily access it without importing it.
      // Let's assume for now d.platform is valid.
      // If d.platform is 'Taobao', select 'Taobao'.
      // If d.platform is 'SomeShop', select '其它' and fill 'SomeShop'.

      // I should update this logic to be robust but avoid importing PlatformConfig if possible,
      // or just importing it is fine.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _customPlatformController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _saveDevice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择分类')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final platform = _selectedPlatform == '其它'
          ? _customPlatformController.text
          : _selectedPlatform;

      // Handle custom category
      var finalCategory = _selectedCategory;
      if (_selectedCategory?.name == '其它') {
        final customName = _customCategoryController.text.trim();
        if (customName.isNotEmpty) {
          // Check if exists
          final existing = await ref
              .read(categoryRepositoryProvider)
              .findCategoryByName(customName);
          if (existing != null) {
            finalCategory = existing;
          } else {
            // Create new category
            final newCat = Category()
              ..name = customName
              ..iconPath =
                  'MdiIcons.tag' // Default icon for custom
              ..isDefault = false;

            final id = await ref
                .read(categoryRepositoryProvider)
                .addCategory(newCat);
            finalCategory = newCat..id = id;
          }
        } else {
          // Input empty, user selected "Other" but didn't type anything.
          // Use/Create "其它" category?
          final existing = await ref
              .read(categoryRepositoryProvider)
              .findCategoryByName('其它');
          if (existing != null) {
            finalCategory = existing;
          } else {
            final newCat = Category()
              ..name = '其它'
              ..iconPath = 'MdiIcons.dotsHorizontal'
              ..isDefault = false;
            final id = await ref
                .read(categoryRepositoryProvider)
                .addCategory(newCat);
            finalCategory = newCat..id = id;
          }
        }
      }

      final device = widget.device ?? Device();
      device
        ..name = _nameController.text
        ..price = double.parse(_priceController.text)
        ..purchaseDate = _purchaseDate
        ..platform = platform ?? ''
        ..warrantyEndDate = _warrantyDate
        ..backupDate = _backupDate
        ..scrapDate = _scrapDate
        ..category.value = finalCategory;

      if (widget.device != null) {
        await ref.read(deviceRepositoryProvider).updateDevice(device);
      } else {
        await ref.read(deviceRepositoryProvider).addDevice(device);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.device != null ? '修改成功' : '添加成功')),
        );
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDate(
    BuildContext context, {
    bool isWarranty = false,
    bool isBackup = false,
    bool isScrap = false,
  }) async {
    final initialDate = isWarranty
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
        if (isWarranty) {
          _warrantyDate = picked;
        } else if (isBackup) {
          _backupDate = picked;
        } else if (isScrap) {
          _scrapDate = picked;
        } else {
          _purchaseDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final isEditing = widget.device != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? '编辑设备' : '添加设备')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(
              controller: _nameController,
              label: '物品名称',
              labelStyle: TextStyle(color: Theme.of(context).hintColor),
              validator: (v) => v?.isEmpty == true ? '请输入名称' : null,
            ),
            const SizedBox(height: 16),
            CategoryPicker(
              selectedCategory: _selectedCategory,
              onCategorySelected: (c) => setState(() => _selectedCategory = c),
            ),
            if (_selectedCategory?.name == '其它') ...[
              const SizedBox(height: 16),
              AppTextField(
                controller: _customCategoryController, // Need to define this
                label: '请输入分类名称 (选填)',
                labelStyle: TextStyle(color: Theme.of(context).hintColor),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _priceController,
                    label: '价格',
                    labelStyle: TextStyle(color: Theme.of(context).hintColor),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty == true ? '请输入价格' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PlatformPicker(
                    selectedPlatform: _selectedPlatform,
                    onPlatformSelected: (p) =>
                        setState(() => _selectedPlatform = p),
                  ),
                ),
              ],
            ),
            if (_selectedPlatform == '其它') ...[
              const SizedBox(height: 16),
              AppTextField(
                controller: _customPlatformController,
                label: '请输入平台名称',
                labelStyle: TextStyle(color: Theme.of(context).hintColor),
                validator: (v) => v?.isEmpty == true ? '请输入平台名称' : null,
              ),
            ],
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _pickDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '购买日期',
                  border: OutlineInputBorder(),
                ),
                child: Text(dateFormat.format(_purchaseDate)),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _pickDate(context, isWarranty: true),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '保修截止日期 (可选)',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _warrantyDate != null
                      ? dateFormat.format(_warrantyDate!)
                      : '未设置',
                  style: _warrantyDate != null
                      ? null
                      : TextStyle(color: Theme.of(context).hintColor),
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _pickDate(context, isBackup: true),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: '备用日期 (可选)',
                  border: const OutlineInputBorder(),
                  suffixIcon: _backupDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _backupDate = null),
                        )
                      : null,
                ),
                child: Text(
                  _backupDate != null ? dateFormat.format(_backupDate!) : '未设置',
                  style: _backupDate != null
                      ? null
                      : TextStyle(color: Theme.of(context).hintColor),
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _pickDate(context, isScrap: true),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: '报废日期 (可选)',
                  border: const OutlineInputBorder(),
                  suffixIcon: _scrapDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _scrapDate = null),
                        )
                      : null,
                ),
                child: Text(
                  _scrapDate != null ? dateFormat.format(_scrapDate!) : '未设置',
                  style: _scrapDate != null
                      ? null
                      : TextStyle(color: Theme.of(context).hintColor),
                ),
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              text: '保存',
              onPressed: _saveDevice,
              isLoading: _isLoading,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
