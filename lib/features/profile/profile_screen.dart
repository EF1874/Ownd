import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/services/data_transfer_service.dart';

import '../../shared/widgets/base_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transferService = ref.watch(dataTransferServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('个人中心')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, '数据管理'),
          const SizedBox(height: 8),
          BaseCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('导出数据'),
                  subtitle: const Text('备份数据到 Downloads 文件夹'),
                  onTap: () async {
                    try {
                      if (Platform.isAndroid) {
                        // Request Manage External Storage for Android 11+ to ensure write access
                        // This is required to write to the Downloads/DeviceManager folder reliably
                        if (await Permission.manageExternalStorage.request().isGranted) {
                           // Permission granted
                        } else if (await Permission.storage.request().isGranted) {
                           // Fallback for older Android
                        }
                      }
                      
                      await transferService.exportData();
                      if (context.mounted) {
                        _showSnackBar(context, '导出成功');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        _showSnackBar(context, '导出失败: $e');
                      }
                    }
                  },
                ),

                const Divider(),
                ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: const Text('打开备份文件夹'),
                  subtitle: const Text('查看 Downloads/DeviceManager 文件夹'),
                  onTap: () async {
                    final path = await transferService.getBackupDirectoryPath();
                    if (Platform.isAndroid) {
                      await _openDownloadFolder(context, path);
                    } else {
                        // iOS or others
                        final uri = Uri.parse('file://$path');
                        try {
                          // Try open_file_plus first for desktop/iOS
                          final result = await OpenFile.open(path);
                          if (result.type != ResultType.done) {
                             if (!await launchUrl(uri)) {
                                throw 'Could not launch $uri';
                             }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            _showPathDialog(context, path);
                          }
                        }
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.upload),
                  title: const Text('导入数据'),
                  subtitle: const Text('从备份文件恢复数据'),
                  onTap: () async {
                    try {
                      _showSnackBar(context, '请选择备份文件...');
                      
                      await transferService.importData();
                      
                      if (context.mounted) {
                        _showSnackBar(context, '导入成功');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        _showSnackBar(context, '导入失败: $e');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, '关于'),
          const SizedBox(height: 8),
          const BaseCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('版本'),
                  trailing: Text('1.0.0'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openDownloadFolder(BuildContext context, String path) async {
    // Construct the specific URI for the DeviceManager subfolder
    // Note: The path must be encoded: primary:Download/DeviceManager -> primary%3ADownload%2FDeviceManager
    const uri = 'content://com.android.externalstorage.documents/document/primary%3ADownload%2FDeviceManager';
    
    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      data: uri,
      type: 'vnd.android.document/directory',
      flags: <int>[
        Flag.FLAG_ACTIVITY_NEW_TASK,
        Flag.FLAG_GRANT_READ_URI_PERMISSION,
      ],
    );

    try {
      await intent.launch();
    } catch (e) {
      debugPrint('Specific intent failed: $e');
      // Fallback: Try OpenFile with the path
      try {
        final result = await OpenFile.open(path);
        if (result.type != ResultType.done) {
           throw 'OpenFile failed';
        }
      } catch (e) {
        if (context.mounted) {
          _showPathDialog(context, path);
        }
      }
    }
  }
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showPathDialog(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('无法直接打开文件夹'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('请手动在文件管理器中找到以下路径:'),
            const SizedBox(height: 8),
            SelectableText(path, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: path));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('路径已复制')),
              );
              Navigator.pop(ctx);
            },
            child: const Text('复制路径'),
          ),
        ],
      ),
    );
  }
}
