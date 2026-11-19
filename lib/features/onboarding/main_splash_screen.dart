import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/sound_service.dart';
import '../../shared/widgets/quixote_mascot.dart';
import '../../core/services/network_service.dart';

/// A Duolingo-style animated launch & loading screen for Quixoria.
/// Features Don Quixote, cycling Cervantes quotes, and a chunky progress bar.
class MainSplashScreen extends StatefulWidget {
  final VoidCallback onLoaded;

  const MainSplashScreen({super.key, required this.onLoaded});

  @override
  State<MainSplashScreen> createState() => _MainSplashScreenState();
}

class _MainSplashScreenState extends State<MainSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;

  int _quoteIndex = 0;
  Timer? _quoteTimer;
  bool _isOnline = true;
  bool _hasCheckedWifi = false;

  static const List<String> _cervantesQuotes = [
    '“Too much sanity may be madness! To surrender dreams—this may be madness.”',
    '“Ready your lance, Alonso Quijano. The open plains of literature await.”',
    '“When life itself seems lunatic, who knows where madness lies?”',
    '“A voyage of a thousand pages begins with a single courageous passage.”',
    '“Virtue is more persecuted by the wicked than encouraged by the good.”',
  ];

  @override
  void initState() {
    super.initState();
    SoundService.instance.play(Sfx.appOpen);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    // Concurrently verify auto-saved login info & Wi-Fi connectivity during loading screen
    AuthService.instance.init().then((_) {
      if (mounted) setState(() {});
    });

    NetworkMonitorService.instance.checkConnection().then((online) {
      if (mounted) {
        setState(() {
          _isOnline = online;
          _hasCheckedWifi = true;
        });
      }
    });

    _progressController.forward().then((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 300), widget.onLoaded);
      }
    });

    _quoteTimer = Timer.periodic(const Duration(milliseconds: 1800), (timer) {
      if (mounted) {
        setState(() {
          _quoteIndex = (_quoteIndex + 1) % _cervantesQuotes.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _getLoadingStatus(double val) {
    final isSavedAuth = AuthService.instance.isAuthenticated;
    final savedName = AuthService.instance.userName;
    if (val < 0.35) {
      return 'Checking Auto-Saved Login Info... (${(val * 100).toInt()}%)';
    } else if (val < 0.70) {
      if (isSavedAuth) {
        final displayName = savedName.isNotEmpty ? savedName : 'Scholar';
        return 'Welcome Back, $displayName! Verifying Session... (${(val * 100).toInt()}%)';
      }
      return 'Checking Realm Wi-Fi Connection... (${(val * 100).toInt()}%)';
    } else {
      if (isSavedAuth) {
        return 'Login Verified • Directing to Main Page (${(val * 100).toInt()}%)';
      }
      if (_hasCheckedWifi && !_isOnline) {
        return 'No Wi-Fi Detected • Offline Mode Ready (${(val * 100).toInt()}%)';
      }
      return 'Realm Connected • Entering Quixoria (${(val * 100).toInt()}%)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          SoundService.instance.play(Sfx.welcome);
          widget.onLoaded();
        },
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Brand Tagline (Pure typography, no icons)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.antiqueGold.withValues(alpha: 0.4),
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            'CHIVALRIC LITERATURE COMPANION',
                            style: AppTypography.labelSmall.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Central Title & Brand Hero Area with New Knight Mascot
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const QuixoteMascot(
                          size: 115,
                          expression: QuixoteExpression.idle,
                          showSpeechBubble: false,
                        ),
                        const SizedBox(height: 12),
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) {
                            final pulse = _pulseController.value;
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Ambient Golden Aura glowing directly behind the title container
                                Container(
                                  width: 280 + (pulse * 30),
                                  height: 160 + (pulse * 20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        AppColors.antiqueGold.withValues(alpha: isDark ? 0.35 : 0.40),
                                        AppColors.antiqueGold.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),

                                // Main Title Frame
                                Container(
                                  width: math.min(340.0, MediaQuery.of(context).size.width - 48.0),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E2620) : const Color(0xFFFFFBF2),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: AppColors.antiqueGold.withValues(alpha: 0.45 + (pulse * 0.45)),
                                      width: 2.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.antiqueGold.withValues(alpha: isDark ? 0.28 : 0.18),
                                        blurRadius: 28 + (pulse * 10),
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.center,
                                          child: Text(
                                            'QUIXORIA',
                                            maxLines: 1,
                                            softWrap: false,
                                            overflow: TextOverflow.visible,
                                            textAlign: TextAlign.center,
                                            style: AppTypography.displayLarge.copyWith(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 2.0,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: 100,
                                        height: 2.5,
                                        decoration: BoxDecoration(
                                          color: AppColors.antiqueGold,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Subtitle
                        Text(
                          'Where Classical Masterpieces Become Living Quests',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),

                    // Bottom Progress & Cycling Literary Quotes
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Cycling Cervantes Quotes with smooth crossfade
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Container(
                            key: ValueKey<int>(_quoteIndex),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              _cervantesQuotes[_quoteIndex],
                              textAlign: TextAlign.center,
                              style: AppTypography.quote.copyWith(
                                fontSize: 13.5,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                height: 1.45,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Chunky Duolingo-style Progress Bar
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, _) {
                            final val = _progressAnimation.value;
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: 14,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.antiqueGold.withValues(alpha: 0.5),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      // Progress fill
                                      FractionallySizedBox(
                                        widthFactor: val.clamp(0.05, 1.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20),
                                            gradient: const LinearGradient(
                                              colors: [
                                                AppColors.antiqueGold,
                                                Color(0xFFE8B946),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.antiqueGold.withValues(alpha: 0.4),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getLoadingStatus(val),
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // Tap anywhere hint
                        Text(
                          'Tap anywhere to start instantly',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
