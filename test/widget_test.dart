import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quixoria/app/app.dart';
import 'package:quixoria/core/services/auth_service.dart';
import 'package:quixoria/core/services/network_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('QuixoriaApp smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(() => NetworkMonitorService.instance.stopMonitoring());

    NetworkMonitorService.instance.setOverride(true);
    await AuthService.instance.login(
      email: 'smoke@quixoria.realm',
      password: 'password123',
    );

    await tester.pumpWidget(const QuixoriaApp());
    await tester.pump();

    // Initially shows Duolingo-style launch splash screen
    expect(find.text('QUIXORIA'), findsOneWidget);

    // Tap to finish splash screen and enter the main realm
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Guest option is no longer shown and main app scaffold loads cleanly
    expect(find.text('Continue as Guest (Skip)'), findsNothing);
    expect(find.byKey(const ValueKey('main_scaffold')), findsOneWidget);
    expect(find.text('Quest'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    NetworkMonitorService.instance.stopMonitoring();
  });
}
