import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/auth_service.dart';
import '../core/services/community_service.dart';
import '../core/services/haptic_service.dart';
import '../core/services/network_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/persistence_service.dart';
import '../core/services/sound_service.dart';
import '../core/state/app_state.dart';
import '../features/auth/auth_screen.dart';
import '../features/community/community_feed_screen.dart';
import '../features/library/library_screen.dart';
import '../features/notes/notes_screen.dart';
import '../features/onboarding/main_splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/quest/quest_screen.dart';
import '../features/shop/shop_screen.dart';
import '../shared/widgets/blur_dissolve_transition.dart';
import '../shared/widgets/offline_warning_dialog.dart';
import '../shared/widgets/quixote_guided_tour_overlay.dart';
import '../shared/widgets/reward_celebration.dart';
import '../shared/widgets/theme_shift_overlay.dart';
import '../shared/widgets/whats_new_sheet.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

class QuixoriaApp extends StatelessWidget {
  final PersistenceService? persistence;

  const QuixoriaApp({super.key, this.persistence});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(persistence),
      child: Consumer<AppState>(
        builder: (context, state, _) {
          return MaterialApp(
            title: 'Quixoria',
            debugShowCheckedModeBanner: false,
            theme: state.currentThemeData,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light, // currentThemeData handles dynamic preset & dark mode
            themeAnimationDuration: const Duration(milliseconds: 480),
            themeAnimationCurve: Curves.easeInOutCubic,
            builder: (context, child) {
              return ThemeShiftOverlay(
                isDarkMode: state.isDarkMode,
                themePresetId: state.activeThemePreset.id,
                child: RewardCelebrationOverlay(
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
            home: const _MainNavigationScaffold(),
          );
        },
      ),
    );
  }
}

class _MainNavigationScaffold extends StatefulWidget {
  const _MainNavigationScaffold();

  @override
  State<_MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<_MainNavigationScaffold>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  int _shopInitialTabIndex = 0;
  bool _isLoadingSplash = true;
  bool _hasTriggeredWelcome = false;
  bool _hasCheckedInitialNetwork = false;
  bool _hasScheduledWhatsNew = false;
  bool _isAppInForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initServices();
  }

  @override
  void dispose() {
    CommunityService.instance.cancelTimers();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppInForeground = true;
      if (mounted && AuthService.instance.isAuthenticated) {
        context.read<AppState>().checkStreakOnAppOpenOrResume();
      }
      // Give Android Wi-Fi sockets a brief moment to wake up before checking
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && _isAppInForeground) {
          NetworkMonitorService.instance.startMonitoring();
        }
      });
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _isAppInForeground = false;
      NetworkMonitorService.instance.stopMonitoring();
      if (state == AppLifecycleState.paused && mounted && AuthService.instance.isAuthenticated) {
        context.read<AppState>().flushCloudSync();
      }
    }
  }

  Future<void> _initServices() async {
    await AuthService.instance.init();
    NetworkMonitorService.instance.startMonitoring();
    NetworkMonitorService.instance.onConnectivityChanged.listen((isOnline) {
      if (mounted && _isAppInForeground) {
        context.read<AppState>().toggleOnlineStatus(isOnline);
        // Real-time notification: popup offline warning only while actively in foreground
        if (!isOnline && AuthService.instance.isAuthenticated && !_isLoadingSplash) {
          OfflineWarningDialog.show(context);
        }
      }
    });
  }

  void _bindSocialFollowSync(AppState appState) {
    final myHandle = AuthService.instance.accountKey.trim().isNotEmpty
        ? AuthService.instance.accountKey
        : appState.profile.email;
    if (myHandle.trim().isEmpty) return;

    final community = CommunityService.instance;
    community.onNewFollowerReceived = (followerHandle, followerName) {
      appState.handleNewFollowerAlert(
        followerHandle: followerHandle,
        followerName: followerName,
      );
    };
    community.onMutualsChanged = (mutuals) {
      appState.syncMutualReadingBuddies(
        mutuals,
        community.displayNameForHandle,
      );
    };
    community.init(myHandle);
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openShopAtTab(int shopTabIndex) {
    setState(() {
      _shopInitialTabIndex = shopTabIndex;
      _currentIndex = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isAuthenticated = AuthService.instance.isAuthenticated;

    Widget currentScreen;

    if (_isLoadingSplash) {
      currentScreen = MainSplashScreen(
        key: const ValueKey('splash'),
        onLoaded: () async {
          await AuthService.instance.init();
          if (!context.mounted) return;
          if (AuthService.instance.isAuthenticated) {
            final appState = context.read<AppState>();
            appState.restoreAuthenticatedSession(markReadyForMainPage: true);
            appState.checkStreakOnAppOpenOrResume();
            NotificationService().scheduleDailyStreakReminders(
              userName: appState.profile.name,
              streakDays: appState.profile.streakDays,
              activeBook: appState.activeLiterature.title,
            );
            _bindSocialFollowSync(appState);
          }
          setState(() {
            _isLoadingSplash = false;
          });
          if (!kIsWeb) {
            SoundService.instance.play(Sfx.welcome);
          }

          // Real-time network check upon entering the realm
          if (!_hasCheckedInitialNetwork) {
            _hasCheckedInitialNetwork = true;
            final isOnline = await NetworkMonitorService.instance.checkConnection();
            if (!context.mounted) return;
            context.read<AppState>().toggleOnlineStatus(isOnline);
            if (!isOnline && AuthService.instance.isAuthenticated) {
              OfflineWarningDialog.show(context);
            }
          }
        },
      );
    } else if (!isAuthenticated) {
      currentScreen = AuthScreen(
        key: const ValueKey('auth'),
        onAuthSuccess: () async {
          setState(() {});
          if (mounted) {
            final appState = context.read<AppState>();
            NotificationService().scheduleDailyStreakReminders(
              userName: appState.profile.name,
              streakDays: appState.profile.streakDays,
              activeBook: appState.activeLiterature.title,
            );
            _bindSocialFollowSync(appState);
          }
          final isOnline = await NetworkMonitorService.instance.checkConnection();
          if (!context.mounted) return;
          context.read<AppState>().toggleOnlineStatus(isOnline);
          if (!isOnline) {
            OfflineWarningDialog.show(context);
          }
        },
      );
    } else if (!state.hasCompletedOnboarding) {
      currentScreen = OnboardingScreen(
        key: const ValueKey('onboarding'),
        onFinish: () {
          setState(() {});
        },
      );
    } else {
      final pages = [
        QuestScreen(
          onSwitchToShop: () => _openShopAtTab(0),
          onGemsTap: () => _openShopAtTab(3),
        ),
        LibraryScreen(onNavigateTab: _onTabSelected),
        const NotesScreen(),
        ShopScreen(
          onNavigateTab: _onTabSelected,
          initialTabIndex: _shopInitialTabIndex,
        ),
        const CommunityFeedScreen(),
        ProfileScreen(onNavigateTab: _onTabSelected),
      ];

      final theme = Theme.of(context);

      // Show "What's New" update popup once per app version after onboarding & tour
      if (!_hasScheduledWhatsNew &&
          state.hasCompletedOnboarding &&
          state.hasSeenGuidedTour &&
          state.shouldShowWhatsNew) {
        _hasScheduledWhatsNew = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 550), () {
            if (!mounted || !context.mounted) return;
            final s = context.read<AppState>();
            if (s.shouldShowWhatsNew && s.hasCompletedOnboarding && s.hasSeenGuidedTour) {
              WhatsNewSheet.show(context);
            }
          });
        });
      }

      currentScreen = Scaffold(
        key: const ValueKey('main_scaffold'),
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            if (!_hasTriggeredWelcome) {
              _hasTriggeredWelcome = true;
              SoundService.instance.play(Sfx.welcome);
            }
          },
          child: Stack(
            children: [
              BlurDissolveSwitcher(
                key: ValueKey<int>(_currentIndex),
                duration: const Duration(milliseconds: 260),
                maxBlur: 6.0,
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentIndex),
                  child: pages[_currentIndex],
                ),
              ),
              if (state.hasCompletedOnboarding && !state.hasSeenGuidedTour)
                QuixoteGuidedTourOverlay(
                  onFinishTour: () {
                    state.completeGuidedTour();
                  },
                ),
            ],
          ),
        ),
        bottomNavigationBar: _ElasticSlidingBottomBar(
          selectedIndex: _currentIndex,
          onTabSelected: _onTabSelected,
          theme: theme,
          questBadgeCount: state.questBadgeCount,
        ),
      );
    }

    return BlurDissolveSwitcher(
      duration: const Duration(milliseconds: 280),
      child: currentScreen,
    );
  }
}

class _ElasticSlidingBottomBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final ThemeData theme;
  final int questBadgeCount;

  const _ElasticSlidingBottomBar({
    required this.selectedIndex,
    required this.onTabSelected,
    required this.theme,
    this.questBadgeCount = 0,
  });

  @override
  State<_ElasticSlidingBottomBar> createState() => _ElasticSlidingBottomBarState();
}

class _ElasticSlidingBottomBarState extends State<_ElasticSlidingBottomBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _springController;
  int _lastIndex = 0;

  @override
  void initState() {
    super.initState();
    _lastIndex = widget.selectedIndex;
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void didUpdateWidget(covariant _ElasticSlidingBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _lastIndex = oldWidget.selectedIndex;
      _springController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.brightness == Brightness.dark;

    final items = [
      (Icons.explore_rounded, Icons.explore_outlined, 'Quest'),
      (Icons.auto_stories_rounded, Icons.auto_stories_outlined, 'Library'),
      (Icons.book_rounded, Icons.book_outlined, 'Notes'),
      (Icons.storefront_rounded, Icons.storefront_outlined, 'Bazaar'),
      (Icons.forum_rounded, Icons.forum_outlined, 'Feed'),
      (Icons.shield_rounded, Icons.shield_outlined, 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.45),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final tabWidth = totalWidth / items.length;
              final pillBaseWidth = tabWidth * 0.90;

              return AnimatedBuilder(
                animation: _springController,
                builder: (context, _) {
                  final t = _springController.isAnimating
                      ? _springController.value
                      : 1.0;

                  final fromIndex = _lastIndex;
                  final toIndex = widget.selectedIndex;

                  final startX = (fromIndex * tabWidth) + ((tabWidth - pillBaseWidth) / 2);
                  final endX = (toIndex * tabWidth) + ((tabWidth - pillBaseWidth) / 2);

                  double left;
                  double width;

                  if (toIndex == fromIndex) {
                    left = endX;
                    width = pillBaseWidth;
                  } else {
                    final distanceTabs = (toIndex - fromIndex).abs();
                    if (toIndex > fromIndex) {
                      // Moving right: leading edge is right edge, trailing edge is left edge
                      final leadT = Curves.easeOutCubic.transform(math.min(1.0, t * 1.45));
                      final trailT = Curves.easeInQuad.transform(math.min(1.0, t * 1.05));
                      final rightPos = lerpDouble(startX + pillBaseWidth, endX + pillBaseWidth, leadT)!;
                      final leftPos = lerpDouble(startX, endX, trailT)!;
                      // Elongation stretch in direction of travel
                      final stretch = math.sin(t * math.pi) * (tabWidth * 0.35 * math.min(2.0, distanceTabs.toDouble()));
                      left = leftPos;
                      width = math.max(pillBaseWidth, (rightPos + stretch) - left);
                    } else {
                      // Moving left: leading edge is left edge, trailing edge is right edge
                      final leadT = Curves.easeOutCubic.transform(math.min(1.0, t * 1.45));
                      final trailT = Curves.easeInQuad.transform(math.min(1.0, t * 1.05));
                      final leftPos = lerpDouble(startX, endX, leadT)!;
                      final rightPos = lerpDouble(startX + pillBaseWidth, endX + pillBaseWidth, trailT)!;
                      // Elongation stretch in direction of travel
                      final stretch = math.sin(t * math.pi) * (tabWidth * 0.35 * math.min(2.0, distanceTabs.toDouble()));
                      left = leftPos - stretch;
                      width = math.max(pillBaseWidth, rightPos - left);
                    }
                  }

                  return Stack(
                    children: [
                      // Theme-Colored Spring-Stretching Sliding Pill Indicator
                      Positioned(
                        left: left,
                        top: 6,
                        width: width,
                        height: 54,
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.38),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Navigation items
                      Row(
                        children: List.generate(items.length, (index) {
                          final item = items[index];
                          final isSelected = widget.selectedIndex == index;
                          final activeColor = theme.colorScheme.onPrimary;
                          final inactiveColor = theme.colorScheme.onSurface.withValues(alpha: 0.60);

                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticService.instance.light();
                                widget.onTabSelected(index);
                              },
                              child: Center(
                                child: AnimatedScale(
                                  scale: isSelected ? 1.08 : 1.0,
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutBack,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Icon(
                                            isSelected ? item.$1 : item.$2,
                                            size: 22,
                                            color: isSelected ? activeColor : inactiveColor,
                                          ),
                                          if (index == 0 && widget.questBadgeCount > 0)
                                            Positioned(
                                              top: -4,
                                              right: -8,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: AppColors.vermillion,
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: Colors.white, width: 1.4),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.3),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 1),
                                                    ),
                                                  ],
                                                ),
                                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                                child: Center(
                                                  child: Text(
                                                    '${widget.questBadgeCount}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 2),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            item.$3,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                              color: isSelected ? activeColor : inactiveColor,
                                              letterSpacing: isSelected ? 0.15 : 0.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
