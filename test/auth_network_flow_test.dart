import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quixoria/core/services/auth_service.dart';
import 'package:quixoria/core/services/network_service.dart';
import 'package:quixoria/core/services/persistence_service.dart';
import 'package:quixoria/core/state/app_state.dart';
import 'package:quixoria/features/auth/auth_screen.dart';
import 'package:quixoria/shared/widgets/offline_warning_dialog.dart';
import 'package:quixoria/shared/widgets/duo_level_preview_sheet.dart';
import 'package:quixoria/models/quest_level.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Auth & Enlistment Flow Tests', () {
    setUp(() async {
      await AuthService.instance.logout();
    });

    test('Fresh user starts unauthenticated and can request email code', () async {
      expect(AuthService.instance.isAuthenticated, isFalse);

      final code = await AuthService.instance.requestVerificationCode('scholar@quixoria.realm');
      expect(code, hasLength(6));
      expect(AuthService.instance.pendingCodeForDemo, equals(code));
    });

    test('Verifying code registers and auto-logs in the user', () async {
      final code = await AuthService.instance.requestVerificationCode('knight@quixoria.realm');
      final verified = await AuthService.instance.verifyAndRegister(
        email: 'knight@quixoria.realm',
        code: code,
        name: 'Don Quixote',
        acceptedTerms: true,
      );

      expect(verified, isTrue);
      expect(AuthService.instance.isAuthenticated, isTrue);
      expect(AuthService.instance.userEmail, equals('knight@quixoria.realm'));
    });

    testWidgets('AuthScreen greets user with Duolingo-style welcome and navigates to Sign Up on GET STARTED', (tester) async {
      bool authCompleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthScreen(
              onAuthSuccess: () => authCompleted = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Duolingo-style greeting
      expect(find.text('The most fun way to conquer classic books!'), findsOneWidget);
      expect(find.text('GET STARTED'), findsOneWidget);
      expect(find.text('I ALREADY HAVE AN ACCOUNT'), findsOneWidget);

      // Tap GET STARTED to navigate to Sign Up
      await tester.tap(find.text('GET STARTED'));
      await tester.pumpAndSettle();

      // Verify Sign Up heading and inputs
      expect(find.text('Create Your Account'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('Sign Up & Send Verification Code'), findsOneWidget);
      expect(find.text('SIGN IN WITH GOOGLE'), findsOneWidget);
      expect(find.text('SIGN IN WITH FACEBOOK'), findsOneWidget);
      expect(authCompleted, isFalse);
    });

    testWidgets('AuthScreen navigates to Log In on I ALREADY HAVE AN ACCOUNT', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthScreen(
              onAuthSuccess: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap I ALREADY HAVE AN ACCOUNT from Welcome screen
      await tester.tap(find.text('I ALREADY HAVE AN ACCOUNT'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back! Log In'), findsOneWidget);
      expect(find.text('Log In'), findsWidgets);
      expect(find.text('Remember Me'), findsOneWidget);
      expect(find.text('SIGN IN WITH GOOGLE'), findsOneWidget);
      expect(find.text('SIGN IN WITH FACEBOOK'), findsOneWidget);
    });

    testWidgets('AuthScreen back button navigates smoothly back to Welcome screen and previous forms', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthScreen(
              onAuthSuccess: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Go to Sign Up
      await tester.tap(find.text('GET STARTED'));
      await tester.pumpAndSettle();
      expect(find.text('Create Your Account'), findsOneWidget);

      // Tap top back button to return to Welcome
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(find.text('The most fun way to conquer classic books!'), findsOneWidget);

      // Go to Log In
      await tester.tap(find.text('I ALREADY HAVE AN ACCOUNT'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome Back! Log In'), findsOneWidget);

      // Tap top back button to return to Welcome
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(find.text('The most fun way to conquer classic books!'), findsOneWidget);
    });
  });

  group('Real-Time Network & Offline Warning Flow Tests', () {
    testWidgets('OfflineWarningDialog displays consequence bullets and action buttons', (tester) async {
      final state = AppState();
      state.toggleOnlineStatus(false);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: const MaterialApp(
            home: Scaffold(
              body: OfflineWarningDialog(),
            ),
          ),
        ),
      );

      await tester.pump();

      // Check key offline consequences and options
      expect(find.text('No Realm Wi-Fi Detected'), findsOneWidget);
      expect(find.text('No Gem Bounties or Level Coins'), findsOneWidget);
      expect(find.text('Daily Streak Progression Paused'), findsOneWidget);
      expect(find.text('Quizzes Locked (Reading Only)'), findsOneWidget);
      expect(find.text('Proceed Offline'), findsOneWidget);
      expect(find.text('Retry Wi-Fi'), findsOneWidget);
    });

    testWidgets('DuoLevelPreviewSheet locks quiz when offline but keeps reading open', (tester) async {
      final state = AppState();
      state.toggleOnlineStatus(false); // Simulate offline

      final quizLevel = QuestLevel(
        id: 'quiz_lvl_1',
        literatureId: 'lit_test',
        levelNumber: 2,
        title: 'Recall Quiz',
        description: 'Test passage knowledge',
        type: LevelType.recall,
        isCompleted: false,
        isLocked: false,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(
            home: Scaffold(
              body: DuoLevelPreviewSheet(
                literature: state.activeLiterature,
                level: quizLevel,
                onStart: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Quiz should show locked state requiring Wi-Fi
      expect(find.text('Quiz Locked (Wi-Fi Required)'), findsOneWidget);
      expect(find.textContaining('Reading chapters are available offline'), findsOneWidget);
    });

    test('Real-time network status changes propagate correctly', () async {
      NetworkMonitorService.instance.setOverride(false);
      expect(NetworkMonitorService.instance.isOnline, isFalse);

      NetworkMonitorService.instance.setOverride(true);
      expect(NetworkMonitorService.instance.isOnline, isTrue);

      NetworkMonitorService.instance.setOverride(null); // Reset override
    });

    test('No-email username registration, password verification, and per-account isolation work cleanly', () async {
      SharedPreferences.setMockInitialValues({});
      await AuthService.instance.logout();
      final persistence = await PersistenceService.create();
      final state = AppState(persistence);

      // 1. Register Account A without an email (Username + Password)
      final regA = await AuthService.instance.registerWithUsername(
        username: 'knight_alpha',
        password: 'password123',
        displayName: 'Alpha Scholar',
        acceptedTerms: true,
      );
      expect(regA.success, isTrue);
      expect(AuthService.instance.isUsernameAccount, isTrue);
      expect(AuthService.instance.accountKey, equals('user:knight_alpha'));

      await state.loadAccountOnLogin(
        name: AuthService.instance.userName,
        email: AuthService.instance.userEmail,
        isNewAccount: true,
      );
      state.addGems(250);
      state.updateUserProfile(name: 'Renamed Alpha');
      expect(state.profile.gems, equals(900));
      expect(state.profile.name, equals('Renamed Alpha'));

      // 2. Logout flushes Account A and resets in-memory state cleanly
      await state.logout();
      expect(AuthService.instance.isAuthenticated, isFalse);
      expect(state.profile.gems, equals(650));

      // 3. Register Account B without email — must NOT inherit Account A's gems
      final regB = await AuthService.instance.registerWithUsername(
        username: 'knight_beta',
        password: 'password456',
        displayName: 'Beta Scholar',
        acceptedTerms: true,
      );
      expect(regB.success, isTrue);
      await state.loadAccountOnLogin(
        name: AuthService.instance.userName,
        email: AuthService.instance.userEmail,
        isNewAccount: true,
      );
      expect(state.profile.gems, equals(650));
      expect(state.profile.name, equals('Beta Scholar'));

      await state.logout();

      // 4. Wrong password for Account A is rejected
      final badLogin = await AuthService.instance.loginWithUsername(
        username: 'knight_alpha',
        password: 'wrongpassword',
      );
      expect(badLogin.success, isFalse);
      expect(AuthService.instance.isAuthenticated, isFalse);

      // 5. Correct password for Account A restores Account A's exact gems and renamed username!
      final goodLogin = await AuthService.instance.loginWithUsername(
        username: 'knight_alpha',
        password: 'password123',
      );
      expect(goodLogin.success, isTrue);
      await state.loadAccountOnLogin(
        name: AuthService.instance.userName,
        email: AuthService.instance.userEmail,
        isNewAccount: false,
      );
      expect(state.profile.gems, equals(900));
      expect(state.profile.name, equals('Renamed Alpha'));
    });
  });
}
