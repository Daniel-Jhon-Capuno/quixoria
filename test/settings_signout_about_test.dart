import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quixoria/core/services/auth_service.dart';
import 'package:quixoria/core/state/app_state.dart';
import 'package:quixoria/features/auth/auth_screen.dart';
import 'package:quixoria/features/profile/profile_screen.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AuthScreen 7 Microinteraction Patterns Test', () {
    testWidgets('AuthScreen renders Floating Label, Bouncy Checkbox, and Load Success Button', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool authSucceeded = false;
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(
            initialPage: AuthPage.signUp,
            onAuthSuccess: () => authSucceeded = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));

      // Verify Header
      expect(find.text('QUIXORIA'), findsOneWidget);
      expect(find.text('Create Your Account'), findsOneWidget);

      // Verify Floating Label fields
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(authSucceeded, isFalse);

      // Verify Bouncy Checkbox for Terms
      expect(find.text('Terms & Conditions'), findsOneWidget);

      // Verify Push Slide Tab switching to Log In
      await tester.tap(find.text('Log In'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Welcome Back! Log In'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Remember Me'), findsOneWidget);

      // Tap Remember Me bouncy checkbox to trigger bounce and check draw
      await tester.tap(find.text('Remember Me'));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 200));
    });
  });

  group('Settings Sign Out & About Quixoria Tests', () {
    testWidgets('Settings shows About Quixoria sheet with mission, features, and future roadmap', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = AppState();
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: const MaterialApp(
            home: Scaffold(body: ProfileScreen()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));

      // Scroll to reveal About Quixoria tile
      final aboutFinder = find.text('About Quixoria');
      await tester.scrollUntilVisible(aboutFinder, 300, scrollable: find.byType(Scrollable).first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(aboutFinder, findsOneWidget);

      await tester.tap(aboutFinder);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // Verify Mission, Arsenal, and Grand Horizon roadmap are present
      expect(find.text('1. Our Noble Mission'), findsOneWidget);
      expect(find.text('2. Realm Arsenal (Features Live Today)'), findsOneWidget);
      expect(find.text('3. The Grand Horizon (Future Roadmap)'), findsOneWidget);
      expect(find.text('Cloud Synchronization & Firebase Backup'), findsOneWidget);
      expect(find.text('Theatrical Voiced Storybook Narration'), findsOneWidget);
    });

    testWidgets('Sign Out tile shows warning dialog; Cancel stays in settings, Proceed logs out', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await AuthService.instance.login(email: 'knight@quixoria.realm', password: 'secretpassword');
      expect(AuthService.instance.isAuthenticated, isTrue);

      final state = AppState();
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: const MaterialApp(
            home: Scaffold(body: ProfileScreen()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));

      // Scroll to reveal Sign Out tile
      final signOutFinder = find.text('Sign Out / Log Out');
      await tester.scrollUntilVisible(signOutFinder, 300, scrollable: find.byType(Scrollable).first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(signOutFinder, findsOneWidget);

      // Tap Sign Out tile -> Pop up warning dialog appears
      await tester.tap(signOutFinder);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Depart the Realm?'), findsOneWidget);
      expect(find.text('Cancel (Stay)'), findsOneWidget);
      expect(find.text('Proceed (Sign Out)'), findsOneWidget);

      // 1. Test Cancel button -> stays in settings, still authenticated
      await tester.tap(find.text('Cancel (Stay)'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Depart the Realm?'), findsNothing);
      expect(AuthService.instance.isAuthenticated, isTrue);

      // 2. Open dialog again and click Proceed (Sign Out)
      await tester.tap(find.text('Sign Out / Log Out'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Proceed (Sign Out)'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // User session is cleared
      expect(AuthService.instance.isAuthenticated, isFalse);
    });
  });

  group('The La Mancha Theme Preset Tests', () {
    test('MockThemePresets includes The La Mancha with Cream White FFFDD0 60%, Terracotta Orange 30%, and Obsidian Black outlines', () {
      final state = AppState();
      final laMancha = state.themePresets.firstWhere(
        (p) => p.id == 'theme_the_la_mancha',
        orElse: () => throw Exception('Theme The La Mancha not found'),
      );

      expect(laMancha.name, 'The La Mancha');
      // Terracotta Orange (30%)
      expect(laMancha.primary, const Color(0xFFD95B30));
      // Obsidian black outline & text
      expect(laMancha.border, const Color(0xFF121214));
      expect(laMancha.textPrimary, const Color(0xFF121214));
      // Cream White FFFDD0 (60%) background & surface
      expect(laMancha.background, const Color(0xFFFFFDD0));
      expect(laMancha.surface, const Color(0xFFFFFDD0));

      // Owned and ready to equip
      expect(laMancha.isOwned, isTrue);

      // Equip and verify activeThemePreset & currentThemeData
      state.applyThemePreset('theme_the_la_mancha');
      expect(state.activeThemePresetId, 'theme_the_la_mancha');
      expect(state.activeThemePreset.name, 'The La Mancha');

      final themeData = state.currentThemeData;
      expect(themeData.scaffoldBackgroundColor, const Color(0xFFFFFDD0));
      expect(themeData.colorScheme.surface, const Color(0xFFFFFDD0));
      expect(themeData.colorScheme.primary, const Color(0xFFD95B30));
      expect(themeData.colorScheme.outline, const Color(0xFF121214));
    });
  });
}
