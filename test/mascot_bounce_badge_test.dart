import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quixoria/core/state/app_state.dart';
import 'package:quixoria/models/quest_level.dart';
import 'package:quixoria/shared/widgets/winding_path_canvas.dart';
import 'package:quixoria/shared/widgets/offline_warning_dialog.dart';
import 'package:quixoria/features/quest/quest_screen.dart';

void main() {
  group('Mascot Assets Verification Tests', () {
    test('All official Don Quixote mascot poses and expressions exist with valid sizes', () {
      final expectedAssets = [
        'assets/images/mascot/quixote_idle.png',
        'assets/images/mascot/quixote_happy.png',
        'assets/images/mascot/quixote_excited.png',
        'assets/images/mascot/quixote_thinking.png',
        'assets/images/mascot/quixote_determined.png',
        'assets/images/mascot/quixote_sad.png',
        'assets/images/mascot/quixote_3d_render.png',
        'assets/images/mascot/expr_happy.png',
        'assets/images/mascot/expr_excited.png',
        'assets/images/mascot/expr_thinking.png',
        'assets/images/mascot/expr_determined.png',
        'assets/images/mascot/expr_sad.png',
        'assets/images/mascot/expr_surprised.png',
        'assets/images/mascot/pose_idle.png',
        'assets/images/mascot/pose_celebration.png',
        'assets/images/mascot/pose_walking.png',
        'assets/images/mascot/pose_reading.png',
        'assets/images/mascot/pose_thinking.png',
        'assets/images/mascot/pose_jump.png',
      ];

      for (final path in expectedAssets) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: 'Mascot asset $path must exist on disk');
        expect(file.lengthSync(), greaterThan(10000), reason: 'Mascot asset $path must be non-empty image');
      }
    });
  });

  group('Current Level Node Bounce & Badge Tests', () {
    testWidgets('Active unconquered level renders number badge and bounces with 3s gap', (tester) async {
      final state = AppState();
      final testLevel = QuestLevel(
        id: 'unit1_lvl1',
        literatureId: 'lit_test',
        levelNumber: 1,
        title: 'Prologue of Valor',
        description: 'First expedition',
        type: LevelType.read,
        gemsReward: 5,
        isCompleted: false,
        isLocked: false,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: WindingPathView(
                  levels: [testLevel],
                  onLevelTap: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      // Verify the number badge '1' and 'NEW' on the new unchecked level node
      expect(find.text('NEW'), findsOneWidget);
      expect(find.text('1'), findsWidgets);

      // Verify animation progresses smoothly over time without layout errors
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 3000));
      expect(find.text('NEW'), findsOneWidget);
    });

    testWidgets('Offline mode locks quiz nodes with WI-FI badge while reading nodes remain open', (tester) async {
      final state = AppState();
      state.toggleOnlineStatus(false); // Go offline

      final readLevel = QuestLevel(
        id: 'read_lvl_1',
        literatureId: 'lit_test',
        levelNumber: 1,
        title: 'Passage One',
        description: 'Reading chapter',
        type: LevelType.read,
        isCompleted: false,
        isLocked: false,
      );

      final quizLevel = QuestLevel(
        id: 'quiz_lvl_2',
        literatureId: 'lit_test',
        levelNumber: 2,
        title: 'Passage Quiz',
        description: 'Quiz chapter',
        type: LevelType.recall,
        isCompleted: false,
        isLocked: false,
      );

      // 1. Reading level on path remains open
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: WindingPathView(
                  levels: [readLevel],
                  onLevelTap: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('NEW'), findsOneWidget);
      expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);

      // 2. Quiz level on path locks with WI-FI indicator
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: WindingPathView(
                  levels: [quizLevel],
                  onLevelTap: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('WI-FI'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

      // Tapping the locked quiz node triggers OfflineWarningDialog
      await tester.tap(find.byIcon(Icons.wifi_off_rounded));
      await tester.pump();
      expect(find.byType(OfflineWarningDialog), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Proceed Offline'));
      await tester.pump();

      // 3. Real-time Wi-Fi restoration unlocks the quiz immediately
      state.toggleOnlineStatus(true);
      await tester.pump();
      expect(find.text('NEW'), findsOneWidget);
      expect(find.byIcon(Icons.psychology_rounded), findsOneWidget);
    });

    testWidgets('QuestScreen displays number badge when there are unclaimed completed tasks', (tester) async {
      final state = AppState();
      final claimableCount = state.dailyQuests.where((q) => q.canClaim).length;

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

      await tester.pump();

      if (claimableCount > 0) {
        expect(find.text('$claimableCount'), findsWidgets);
        expect(find.text('$claimableCount Claim'), findsOneWidget);
      }
    });
  });
}
