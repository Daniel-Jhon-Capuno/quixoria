import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quixoria/core/services/auth_service.dart';
import 'package:quixoria/core/state/app_state.dart';
import 'package:quixoria/features/auth/auth_screen.dart';
import 'package:quixoria/features/quest/quest_screen.dart';

void main() {
  setUpAll(() {
    WidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.instance.logout();
  });

  group('User Profile Auth Sync & Leaderboard Soon Tests', () {
    test('Password hashing produces salted SHA-256 hash and verifies accurately', () {
      const plainPassword = 'chivalricPassword123';
      final salt = AuthService.generateSalt();
      expect(salt, isNotEmpty);

      final hash = AuthService.hashPassword(plainPassword, salt);
      expect(hash, isNot(equals(plainPassword)));
      expect(hash, hasLength(64)); // Standard SHA-256 hex string length

      // Verify correct password
      expect(AuthService.verifyPassword(plainPassword, hash, salt), isTrue);

      // Verify wrong password fails
      expect(AuthService.verifyPassword('wrongPassword', hash, salt), isFalse);
    });

    test('Registering user hashes password into storage and enables hashed login', () async {
      final code = await AuthService.instance.requestVerificationCode('knight@la-mancha.realm');
      final registered = await AuthService.instance.verifyAndRegister(
        email: 'knight@la-mancha.realm',
        code: code,
        name: 'Don Quixote',
        acceptedTerms: true,
        password: 'rodrigo_de_bivar_1099',
      );

      expect(registered, isTrue);
      expect(AuthService.instance.hasRecordedPassword, isTrue);
      expect(AuthService.instance.passwordHash, isNot(contains('rodrigo_de_bivar_1099')));
      expect(AuthService.instance.passwordHash, hasLength(64));

      // Test login with valid password
      final loginSuccess = await AuthService.instance.login(
        email: 'knight@la-mancha.realm',
        password: 'rodrigo_de_bivar_1099',
      );
      expect(loginSuccess, isTrue);

      // Test login with invalid password
      final loginFail = await AuthService.instance.login(
        email: 'knight@la-mancha.realm',
        password: 'incorrect_passphrase',
      );
      expect(loginFail, isFalse);
    });

    testWidgets('Sign up displays warning indicators when email is invalid and password is under 6 chars', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthScreen(
              initialPage: AuthPage.signUp,
              onAuthSuccess: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Enter invalid email format and short password
      await tester.enterText(find.byType(TextField).at(1), 'invalid-email');
      await tester.enterText(find.byType(TextField).at(2), '123');
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Sign Up & Send Verification Code
      final sendCodeBtn = find.text('Sign Up & Send Verification Code');
      await tester.tap(sendCodeBtn);
      await tester.pump(const Duration(milliseconds: 300));

      // Verify inline warning indicators are shown
      expect(find.text('Please enter a valid email address (e.g. name@example.com).'), findsOneWidget);
      expect(find.text('Password must be at least 6 characters (currently 3/6).'), findsOneWidget);

      // Now enter valid email and valid 6+ character password
      await tester.enterText(find.byType(TextField).at(1), 'scholar@quixoria.realm');
      await tester.enterText(find.byType(TextField).at(2), 'secureKnighthood99');
      await tester.pump(const Duration(milliseconds: 200));

      // Verify errors disappeared and password strength indicator appeared
      expect(find.text('Please enter a valid email address (e.g. name@example.com).'), findsNothing);
      expect(find.text('Strong Password'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('Entering name and email during enlistment syncs with AppState and persists', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = AppState();
      bool authCompleted = false;

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(
            home: Scaffold(
              body: AuthScreen(
                initialPage: AuthPage.signUp,
                onAuthSuccess: () => authCompleted = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));

      // Enter name, email, password
      await tester.enterText(find.byType(TextField).at(0), 'Lady Dulcinea');
      await tester.enterText(find.byType(TextField).at(1), 'dulcinea@el-toboso.realm');
      await tester.enterText(find.byType(TextField).at(2), 'secretpass123');
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Checkbox square directly using key
      final checkboxBox = find.byKey(const ValueKey('terms_checkbox_box'));
      expect(checkboxBox, findsOneWidget);
      await tester.tap(checkboxBox);
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Sign Up & Send Verification Code
      final sendCodeBtn = find.text('Sign Up & Send Verification Code');
      expect(sendCodeBtn, findsOneWidget);
      await tester.tap(sendCodeBtn);

      // Wait for simulated dispatch (400ms) + AnimatedSwitcher (320ms)
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      // Enter 6-digit verification code into OTP field
      final otpFields = find.byType(TextField);
      expect(otpFields, findsOneWidget);
      await tester.enterText(otpFields.first, '777888');
      await tester.pump(const Duration(milliseconds: 200));

      // Submit verification
      final verifyBtn = find.text('Verify & Continue');
      expect(verifyBtn, findsOneWidget);
      await tester.tap(verifyBtn);

      // Wait for verification + 550ms completion delay
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 500));

      expect(authCompleted, isTrue);

      // Verify state.profile has the exact input name and email!
      expect(state.profile.name, 'Lady Dulcinea');
      expect(state.profile.email, 'dulcinea@el-toboso.realm');
      expect(AuthService.instance.userName, 'Lady Dulcinea');
      expect(AuthService.instance.userEmail, 'dulcinea@el-toboso.realm');
      expect(AuthService.instance.hasRecordedPassword, isTrue);
      expect(AuthService.instance.passwordHash, hasLength(64));
    });

    testWidgets('Tapping Leaderboard in QuestScreen shows Soon to be Established sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = AppState();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: const MaterialApp(
            home: Scaffold(
              body: QuestScreen(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Find Leaderboard button
      final leaderboardPill = find.text('Leaderboard');
      expect(leaderboardPill, findsOneWidget);

      await tester.tap(leaderboardPill);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Soon to be Established bottom sheet
      expect(find.text('Leaderboard • Soon to be Established'), findsOneWidget);
      expect(find.text('SOON TO BE ESTABLISHED • UNDER CONSTRUCTION'), findsOneWidget);
      expect(find.text('Understood, Good Knight'), findsOneWidget);

      // Tap Understood button to dismiss
      await tester.tap(find.text('Understood, Good Knight'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Leaderboard • Soon to be Established'), findsNothing);
    });
  });
}
