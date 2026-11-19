import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quixoria/app/app.dart';
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

    await tester.pumpWidget(const QuixoriaApp());
    await tester.pump();

    // Initially shows Duolingo-style launch splash screen
    expect(find.text('QUIXORIA'), findsOneWidget);

    // Tap to finish splash screen and enter onboarding
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // If Auth screen is presented, bypass with Continue as Guest (Skip)
    if (find.text('Continue as Guest (Skip)').evaluate().isNotEmpty) {
      await tester.tap(find.text('Continue as Guest (Skip)'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    }

    // Verify Onboarding Screen is active for fresh installs
    expect(find.text('Knighthood Initiation'), findsOneWidget);
    expect(find.text('What is Thy Preferred Language?'), findsOneWidget);

    // Tap through knighthood initiation preference steps until reaching candidate masterwork selection
    while (find.text('Continue').evaluate().isNotEmpty) {
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump(const Duration(milliseconds: 450));
    }
    // On Step 5: Tap Confirm Starter Masterwork button
    await tester.tap(find.text('Confirm Starter Masterwork (+100 Gems)'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    // Confirm choice in dialog
    if (find.text('Enter Quixoria & Tour Realm').evaluate().isNotEmpty) {
      await tester.tap(find.text('Enter Quixoria & Tour Realm'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
    }

    // Skip or finish tour to reveal main quest view
    if (find.text('Skip Tour').evaluate().isNotEmpty) {
      await tester.tap(find.text('Skip Tour'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
    }

    // Now in main adventure navigation
    expect(find.text('Quest'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Bazaar'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    NetworkMonitorService.instance.stopMonitoring();
  });
}
