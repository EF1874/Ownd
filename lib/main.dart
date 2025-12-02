import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/app_router.dart';
import 'data/services/database_service.dart';
import 'data/services/backup_service.dart';
import 'data/services/preferences_service.dart';
import 'data/repositories/category_repository.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize DatabaseService manually
  final dbService = DatabaseService();
  await dbService.init();

  // Initialize BackupService manually
  final backupService = BackupService(dbService.isar);
  await backupService.init();

  // Perform startup backup and cleanup
  await backupService.createBackup();
  await backupService.cleanupOldBackups();

  // 2. Initialize PreferencesService
  final prefs = await SharedPreferences.getInstance();
  final preferencesService = PreferencesService(prefs);

  // 3. Create ProviderContainer with the initialized services
  final container = ProviderContainer(
    overrides: [
      databaseServiceProvider.overrideWithValue(dbService),
      backupServiceProvider.overrideWithValue(backupService),
      preferencesServiceProvider.overrideWithValue(preferencesService),
    ],
  );
  
  // 4. Initialize default data using the container
  final categoryRepo = container.read(categoryRepositoryProvider);
  await categoryRepo.initDefaultCategories();

  // 5. Set high refresh rate
  try {
    await FlutterDisplayMode.setHighRefreshRate();
  } catch (e) {
    debugPrint('Error setting high refresh rate: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: '物历',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CH'),
        Locale('en', 'US'),
      ],
    );
  }
}
