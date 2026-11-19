import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';
import 'app/theme/app_colors.dart';
import 'core/services/auth_service.dart';
import 'core/services/crash_reporter.dart';
import 'core/services/notification_service.dart';
import 'core/services/persistence_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Custom parchment ErrorWidget builder preventing grey/red crash screens
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF1B221E),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.antiqueGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.antiqueGold, width: 1.5),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 48,
                  color: AppColors.antiqueGold,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'A Windmill in the Path!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFFAF6EE),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Don Quixote encountered an unexpected tilt. Thy progress is safely preserved in local records.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFDFD7CA),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  };

  // Initialize local device persistence, Supabase session & on-device crash diagnostics
  final persistence = await PersistenceService.create();
  CrashReporter.instance.init(persistence.prefs);
  await AuthService.instance.init();

  // Initialize native phone push & local notification channels
  await NotificationService().init();

  // Set system UI overlay styling for parchment aesthetic
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(QuixoriaApp(persistence: persistence));
}
