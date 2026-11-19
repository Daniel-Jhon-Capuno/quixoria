import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quixoria/core/services/streak_service.dart';
import 'package:quixoria/core/state/app_state.dart';
import 'package:quixoria/models/user_profile.dart';
import 'package:quixoria/shared/widgets/streak_overview_card.dart';

void main() {
  group('StreakService Automatic Logic & Edge Cases', () {
    test('First day starts streak at 1 and only increments once per local calendar day', () {
      final profile = UserProfile(streakDays: 0, longestStreak: 0, totalDaysRead: 0);
      final day1Morning = DateTime(2026, 11, 20, 8, 30);
      final day1Evening = DateTime(2026, 11, 20, 21, 15);

      final res1 = StreakService.recordQualifiedActivity(
        profile,
        completedLevelOrQuiz: true,
        minutesAdded: 5,
        now: day1Morning,
      );
      expect(res1.streakExtended, isTrue);
      expect(profile.streakDays, 1);
      expect(profile.longestStreak, 1);
      expect(profile.totalDaysRead, 1);
      expect(profile.streakHistory['2026-11-20'], 'completed');
      expect(StreakService.computeStatus(profile, now: day1Morning), StreakStatus.activeToday);

      // Second activity on the same day must NOT double-increment
      final res2 = StreakService.recordQualifiedActivity(
        profile,
        completedLevelOrQuiz: true,
        minutesAdded: 10,
        now: day1Evening,
      );
      expect(res2.streakExtended, isFalse);
      expect(profile.streakDays, 1);
      expect(profile.totalDaysRead, 1);
      expect(profile.dailyMinutesReadToday, 15);
    });

    test('Consecutive days extend streak, reset daily minutes at midnight, and auto-award 3-day milestone', () {
      final profile = UserProfile(streakDays: 0, longestStreak: 0, totalDaysRead: 0, gems: 100);

      // Day 1
      StreakService.recordQualifiedActivity(
        profile,
        completedLevelOrQuiz: true,
        minutesAdded: 15,
        now: DateTime(2026, 11, 20, 10, 0),
      );
      expect(profile.streakDays, 1);

      // Day 2 open -> midnight resets dailyMinutesReadToday to 0, status is atRiskToday
      final eval2 = StreakService.evaluateOnAppOpenOrResume(
        profile,
        now: DateTime(2026, 11, 21, 7, 0),
      );
      expect(eval2.dailyMinutesReset, isTrue);
      expect(profile.dailyMinutesReadToday, 0);
      expect(StreakService.computeStatus(profile, now: DateTime(2026, 11, 21, 7, 0)), StreakStatus.atRiskToday);

      // Day 2 activity via reading minutes reaching goal (no quiz needed)
      final res2 = StreakService.recordQualifiedActivity(
        profile,
        completedLevelOrQuiz: false,
        minutesAdded: 15,
        now: DateTime(2026, 11, 21, 14, 0),
      );
      expect(res2.streakExtended, isTrue);
      expect(profile.streakDays, 2);

      // Day 3 -> hits 3-day milestone (+75 gems automatically!)
      final res3 = StreakService.recordQualifiedActivity(
        profile,
        completedLevelOrQuiz: true,
        now: DateTime(2026, 11, 22, 9, 0),
      );
      expect(res3.streakExtended, isTrue);
      expect(profile.streakDays, 3);
      expect(res3.newlyReachedMilestones.length, 1);
      expect(res3.newlyReachedMilestones.first.days, 3);
      expect(profile.gems, 175);
      expect(profile.claimedStreakMilestones, contains(3));
    });

    test('Multiple missed days are protected when user has enough Streak Freezes', () {
      final profile = UserProfile(streakDays: 0, longestStreak: 0, totalDaysRead: 0, streakFreezes: 2);
      StreakService.recordQualifiedActivity(
        profile,
        completedLevelOrQuiz: true,
        now: DateTime(2026, 11, 10, 12, 0),
      );
      expect(profile.streakDays, 1);

      // Miss Nov 11 and Nov 12, return Nov 13 -> 2 freezes auto-consumed!
      final eval = StreakService.evaluateOnAppOpenOrResume(
        profile,
        now: DateTime(2026, 11, 13, 9, 0),
      );
      expect(eval.freezesConsumed, 2);
      expect(eval.streakBroken, isFalse);
      expect(profile.streakFreezes, 0);
      expect(profile.streakDays, 1);
      expect(profile.streakHistory['2026-11-11'], 'frozen');
      expect(profile.streakHistory['2026-11-12'], 'frozen');

      // Completing activity on Nov 13 extends streak to 2!
      final act = StreakService.recordQualifiedActivity(
        profile,
        completedLevelOrQuiz: true,
        now: DateTime(2026, 11, 13, 10, 0),
      );
      expect(act.streakExtended, isTrue);
      expect(profile.streakDays, 2);
    });

    test('Missing days without enough freezes breaks streak and opens 48-hour repair window', () {
      final profile = UserProfile(streakDays: 0, longestStreak: 0, totalDaysRead: 0, gems: 300, streakFreezes: 0);
      // Build 2-day streak
      StreakService.recordQualifiedActivity(profile, completedLevelOrQuiz: true, now: DateTime(2026, 11, 1, 12, 0));
      StreakService.recordQualifiedActivity(profile, completedLevelOrQuiz: true, now: DateTime(2026, 11, 2, 12, 0));
      expect(profile.streakDays, 2);

      // Miss Nov 3, open on Nov 4 -> broken with repair window
      final nov4 = DateTime(2026, 11, 4, 10, 0);
      final eval = StreakService.evaluateOnAppOpenOrResume(profile, now: nov4);
      expect(eval.streakBroken, isTrue);
      expect(profile.streakDays, 0);
      expect(StreakService.canRepairStreak(profile, now: nov4), isTrue);

      // Repair within 48 hours for 150 gems
      final repaired = StreakService.repairBrokenStreak(profile, now: nov4.add(const Duration(hours: 2)));
      expect(repaired, isTrue);
      expect(profile.streakDays, 2);
      expect(profile.gems, 150);
      expect(profile.streakHistory['2026-11-03'], 'frozen');
    });

    test('Anti-cheat rejects device clock rolled backward', () {
      final profile = UserProfile(streakDays: 0, longestStreak: 0, totalDaysRead: 0);
      final t1 = DateTime(2026, 11, 20, 15, 0);
      StreakService.recordQualifiedActivity(profile, completedLevelOrQuiz: true, now: t1);

      // Roll clock backward by 3 hours
      final tampered = t1.subtract(const Duration(hours: 3));
      final eval = StreakService.evaluateOnAppOpenOrResume(profile, now: tampered);
      expect(eval.clockTampered, isTrue);

      final act = StreakService.recordQualifiedActivity(profile, completedLevelOrQuiz: true, now: tampered);
      expect(act.clockTampered, isTrue);
      expect(act.streakExtended, isFalse);
      expect(profile.streakDays, 1);
    });

    test('Offline + Cloud merge preserves all completed/frozen days without double-counting', () {
      final local = UserProfile(
        streakDays: 3,
        longestStreak: 5,
        totalDaysRead: 5,
        streakHistory: {'2026-11-18': 'completed', '2026-11-19': 'frozen'},
        claimedStreakMilestones: [3],
      );
      final cloud = UserProfile(
        streakDays: 2,
        longestStreak: 7,
        totalDaysRead: 7,
        streakHistory: {'2026-11-19': 'completed', '2026-11-20': 'completed'},
        claimedStreakMilestones: [3, 7],
      );

      StreakService.mergeOfflineWithCloud(local, cloud);
      expect(local.streakHistory['2026-11-18'], 'completed');
      expect(local.streakHistory['2026-11-19'], 'completed'); // completed beats frozen
      expect(local.streakHistory['2026-11-20'], 'completed');
      expect(local.longestStreak, 7);
      expect(local.claimedStreakMilestones, containsAll([3, 7]));
    });

    test('Weekly calendar returns 7 Mon-Sun days with accurate states', () {
      final profile = UserProfile(
        streakHistory: {'2026-11-16': 'completed', '2026-11-17': 'frozen'},
      );
      // Wednesday Nov 18, 2026
      final week = StreakService.getWeeklyCalendar(profile, now: DateTime(2026, 11, 18, 12, 0));
      expect(week.length, 7);
      expect(week[0].shortLabel, 'Mon');
      expect(week[0].state, WeeklyDayState.completed);
      expect(week[1].state, WeeklyDayState.frozen);
      expect(week[2].state, WeeklyDayState.todayPending);
      expect(week[2].isToday, isTrue);
      expect(week[3].state, WeeklyDayState.future);
    });

    testWidgets('StreakOverviewCard renders automatic progress, weekly calendar, and milestones with no claim button', (tester) async {
      final state = AppState();
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: const MaterialApp(
            home: Scaffold(body: SingleChildScrollView(child: StreakOverviewCard())),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
      expect(find.text('Longest'), findsOneWidget);
      expect(find.text('Total Days'), findsOneWidget);
      expect(find.text('AUTOMATIC STREAK MILESTONES'), findsOneWidget);
      expect(find.textContaining('Claim Streak'), findsNothing);
    });

    test('Reader 4-color highlights and passage bookmarks persist via UserProfile JSON', () {
      final state = AppState();
      const key = 'don_quixote|lvl_1|2';
      expect(state.getParagraphHighlight(key), isNull);
      expect(state.isPassageBookmarked(key), isFalse);

      state.setParagraphHighlight(key, 'gold');
      state.togglePassageBookmark(key);
      expect(state.getParagraphHighlight(key), 'gold');
      expect(state.isPassageBookmarked(key), isTrue);

      final restored = UserProfile.fromJson(state.profile.toJson());
      expect(restored.paragraphHighlights[key], 'gold');
      expect(restored.bookmarkedPassages, contains(key));
    });
  });
}
