import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quixoria/core/state/app_state.dart';
import 'package:quixoria/shared/widgets/currency_bar.dart';
import 'package:quixoria/shared/widgets/reward_celebration.dart';

void main() {
  testWidgets('RewardCelebrationOverlay mounts and emits flight particles without crash', (tester) async {
    final appState = AppState();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: MaterialApp(
          home: Scaffold(
            body: RewardCelebrationOverlay(
              child: Builder(
                builder: (context) {
                  return Column(
                    children: [
                      const CurrencyBar(),
                      ElevatedButton(
                        onPressed: () {
                          RewardCelebrationOverlay.openChest(
                            context,
                            gems: 50,
                            hearts: 2,
                            keys: 1,
                          );
                        },
                        child: const Text('Open Chest'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Open Chest'), findsOneWidget);
    expect(find.byType(CurrencyBar), findsOneWidget);

    // Tap Open Chest
    await tester.tap(find.text('Open Chest'));
    await tester.pump();

    // Pump midway through flight
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 600));

    // Complete flight animation
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();
  });

  testWidgets('Daily quest claim flight emits gems and completes successfully', (tester) async {
    final appState = AppState();

    bool completed = false;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: MaterialApp(
          home: Scaffold(
            body: RewardCelebrationOverlay(
              child: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      RewardCelebrationOverlay.claimDailyQuest(
                        context,
                        gems: 20,
                        onComplete: () {
                          completed = true;
                        },
                      );
                    },
                    child: const Text('Claim Quest'),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Claim Quest'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
  });
}
