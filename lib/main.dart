import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/auth_gate.dart';
import 'services/achievement_service.dart';
import 'services/auth_service.dart';
import 'services/completion_service.dart';
import 'services/custom_category_service.dart';
import 'services/gamification_service.dart';
import 'services/notification_service.dart';
import 'services/prayer_service.dart';
import 'services/storage_service.dart';
import 'services/theme_service.dart';
import 'utils/app_theme_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await StorageService.instance.init();
  await CompletionService.instance.init();
  await CustomCategoryService.instance.init();
  await AchievementService.instance.init();
  await GamificationService.instance.init();
  await NotificationService.instance.init();
  await PrayerService.instance.init();
  await ThemeService.instance.init();
  await AuthService.instance.init();
  runApp(const PlannerApp());
}

class PlannerApp extends StatelessWidget {
  const PlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box>(
      valueListenable: ThemeService.instance.settingsListenable,
      builder: (context, _, _) {
        return MaterialApp(
          title: 'Weekly Planner',
          debugShowCheckedModeBanner: false,
          theme: buildThemeData(ThemeService.instance.currentTheme),
          home: const AuthGate(),
        );
      },
    );
  }
}
