import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'services/achievement_service.dart';
import 'services/completion_service.dart';
import 'services/custom_category_service.dart';
import 'services/gamification_service.dart';
import 'services/notification_service.dart';
import 'services/prayer_service.dart';
import 'services/storage_service.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.init();
  await CompletionService.instance.init();
  await CustomCategoryService.instance.init();
  await AchievementService.instance.init();
  await GamificationService.instance.init();
  await NotificationService.instance.init();
  await PrayerService.instance.init();
  await ThemeService.instance.init();
  runApp(const PlannerApp());
}

class PlannerApp extends StatelessWidget {
  const PlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final seedColor = ThemeService.instance.seedColor;
        return MaterialApp(
          title: 'Weekly Planner',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: ThemeService.instance.themeMode,
          home: const HomeShell(),
        );
      },
    );
  }
}
