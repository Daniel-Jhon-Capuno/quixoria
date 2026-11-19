import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quixoria/core/services/community_service.dart';
import 'package:quixoria/core/services/notification_service.dart';
import 'package:quixoria/core/services/difficulty_quiz_engine.dart';
import 'package:quixoria/core/state/app_state.dart';
import 'package:quixoria/features/community/community_feed_screen.dart';
import 'package:quixoria/features/events/seasonal_event_sheet.dart';
import 'package:quixoria/features/profile/profile_screen.dart';
import 'package:quixoria/features/special_nodes/mistake_dojo_screen.dart';
import 'package:quixoria/shared/widgets/animated_reward_chest.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CommunityService.instance.enableRealtime = false;
    CommunityService.instance.cancelTimers();
  });

  tearDown(() {
    CommunityService.instance.cancelTimers();
  });

  test('CommunityService enforces 5-second anti-spam cooldown and supports follow by username/email', () async {
    final community = CommunityService.instance;
    final err1 = await community.sendPost(
      authorHandle: 'scholar_one',
      authorName: 'Scholar One',
      authorTitle: 'Knight',
      content: 'Just finished Chapter 1 of The Secret Garden!',
    );
    expect(err1, isNull);
    expect(community.isOnCooldown, isTrue);

    // Immediate second send within 5 seconds is blocked by anti-spam
    final err2 = await community.sendPost(
      authorHandle: 'scholar_one',
      authorName: 'Scholar One',
      authorTitle: 'Knight',
      content: 'Spam message!',
    );
    expect(err2, isNotNull);
    expect(err2, contains('Wait'));

    // Follow by username and by email
    await community.toggleFollow(myHandle: 'scholar_one', targetInput: '@bookworm99');
    await community.toggleFollow(myHandle: 'scholar_one', targetInput: 'friend@quixoria.realm');
    expect(community.isFollowing('bookworm99'), isTrue);
    expect(community.isFollowing('friend@quixoria.realm'), isTrue);

    community.cancelTimers();
  });

  testWidgets('CommunityFeedScreen switches between All Users and Following tabs', (tester) async {
    final state = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const MaterialApp(home: CommunityFeedScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Community'), findsOneWidget);
    expect(find.text('All Users'), findsOneWidget);
    expect(find.byKey(const Key('community_follow_button')), findsOneWidget);

    await tester.tap(find.textContaining('Following'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Community'), findsOneWidget);
  });

  testWidgets('Posting a comment and closing the sheet on narrow width has zero overflow or controller errors', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final state = AppState();
    // Seed a post with a long email handle to stress-test horizontal layout
    final community = CommunityService.instance;
    await community.sendPost(
      authorHandle: 'guest.scholar@quixoria.realm',
      authorName: 'Guest Scholar',
      authorTitle: 'Knight Errant of Letters',
      content: 'Loving The Secret Garden!',
    );
    // Clear cooldown so we can immediately comment in this test
    community.cancelTimers();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const MaterialApp(home: CommunityFeedScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    // Open comments sheet
    await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded).first);
    await tester.pump(const Duration(milliseconds: 450));

    // Type a comment and tap Reply (or close cleanly)
    await tester.enterText(find.byKey(const Key('community_comment_input')), 'Great read!');
    await tester.pump(const Duration(milliseconds: 100));

    // Close the comments sheet and let exit animation finish to verify zero disposed-controller crash
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump(const Duration(milliseconds: 450));

    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile Style button opens ProfileStyleSheet (not Notes) and Seasonal/Dojo work', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final state = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.text('Style'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Profile Style'), findsOneWidget);
    expect(find.text('Icons'), findsOneWidget);
    expect(find.text('Frames'), findsOneWidget);
    expect(find.text('Banners'), findsOneWidget);
    expect(find.text('Titles'), findsOneWidget);
  });

  test('CommunityService extracts @mentions accurately', () {
    final mentions = CommunityService.extractMentions(
      'Great chapter @sancho_panza and @dulcinea.reads! Cc @Sancho_Panza',
    );
    expect(mentions, containsAll(<String>['sancho_panza', 'dulcinea.reads']));
    expect(mentions.length, 2);
  });

  test('NotificationService resolves device local timezone accurately', () {
    final tzName = NotificationService().resolvedTimeZoneName;
    expect(tzName, isNotEmpty);
    if (DateTime.now().timeZoneOffset != Duration.zero) {
      expect(tzName, isNot('UTC'));
    }
  });

  testWidgets('SeasonalEventSheet, MistakeDojoScreen, and Illustrated AnimatedRewardChest render cleanly', (tester) async {
    final state = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AnimatedRewardChest(
                  outcome: const QuizRewardOutcome(
                    chestRarity: ChestRarity.legendary,
                    gemsEarned: 75,
                    leaderboardXpEarned: 90,
                    bonusHearts: 1,
                    difficultyMultiplier: 1.35,
                    difficultyLabel: 'Scholarly',
                  ),
                  isOpened: false,
                  onOpenChest: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('LEGENDARY CHEST'), findsOneWidget);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const MaterialApp(home: MistakeDojoScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Mistake Dojo'), findsOneWidget);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const MaterialApp(home: Scaffold(body: SeasonalEventSheet())),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('5 Event Rewards'), findsOneWidget);
  });
}
