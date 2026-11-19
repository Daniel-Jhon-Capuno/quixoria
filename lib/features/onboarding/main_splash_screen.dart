import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/network_service.dart';
import '../../core/services/sound_service.dart';

/// Full-bleed illustrated launch & loading screen for Quixoria.
/// Displays the classic Don Quixote & Sancho Panza watercolor spanning the full
/// phone viewport with an illuminated antique-gold loading dock at the bottom.
class MainSplashScreen extends StatefulWidget {
  final VoidCallback onLoaded;

  const MainSplashScreen({super.key, required this.onLoaded});

  @override
  State<MainSplashScreen> createState() => _MainSplashScreenState();
}

class _MainSplashScreenState extends State<MainSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _ambientController;
  late Animation<double> _progressAnimation;
  late Animation<double> _kenBurnsAnimation;

  int _quoteIndex = 0;
  Timer? _quoteTimer;
  bool _hasCompleted = false;

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

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _kenBurnsAnimation = Tween<double>(begin: 1.0, end: 1.055).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutQuad),
    );

    // Concurrently verify auto-saved login info & Wi-Fi connectivity during loading screen
    AuthService.instance.init().then((_) {
      if (mounted) setState(() {});
    });

    NetworkMonitorService.instance.checkConnection();

    _progressController.forward().then((_) {
      if (mounted && !_hasCompleted) {
        Future.delayed(const Duration(milliseconds: 260), _finishSplash);
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

  void _finishSplash() {
    if (!mounted || _hasCompleted) return;
    _hasCompleted = true;
    widget.onLoaded();
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    _progressController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A140F),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          SoundService.instance.play(Sfx.welcome);
          _finishSplash();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Full-bleed illustrated watercolor spanning the entire phone screen
            AnimatedBuilder(
              animation: _kenBurnsAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _kenBurnsAnimation.value,
                  alignment: const Alignment(0.0, -0.15),
                  child: child,
                );
              },
              child: Image.asset(
                'assets/images/splash_loading_bg.png',
                fit: BoxFit.cover,
                alignment: const Alignment(0.0, -0.08),
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2B2219), Color(0xFF17120D)],
                    ),
                  ),
                ),
              ),
            ),

            // 2. Whisper-soft upper parchment mist for crisp brand wordmark in the sky
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.28,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF1A140F).withValues(alpha: 0.64),
                        const Color(0xFF1A140F).withValues(alpha: 0.28),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.52, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Warm sepia-espresso bottom vignette melting seamlessly into the road
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: MediaQuery.of(context).size.height * 0.44,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF1A140F).withValues(alpha: 0.55),
                        const Color(0xFF16100B).withValues(alpha: 0.88),
                        const Color(0xFF120D09).withValues(alpha: 0.96),
                      ],
                      stops: const [0.0, 0.36, 0.72, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 4. Gentle drifting sunlit dust motes
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _ambientController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _SunlitDustPainter(_ambientController.value),
                  );
                },
              ),
            ),

            // 5. Foreground overlay: Regal top wordmark + Sleek bottom loading dock
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 18, 26, 22),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Brand Wordmark (leaves middle artwork 100% unobstructed)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'QUIXORIA',
                          textAlign: TextAlign.center,
                          style: AppTypography.displayLarge.copyWith(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6.0,
                            color: const Color(0xFFFFF8E8),
                            shadows: [
                              Shadow(
                                color: const Color(0xFF120D09).withValues(alpha: 0.75),
                                blurRadius: 14,
                                offset: const Offset(0, 2),
                              ),
                              Shadow(
                                color: AppColors.antiqueGold.withValues(alpha: 0.45),
                                blurRadius: 22,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 28,
                              height: 1.2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppColors.antiqueGold.withValues(alpha: 0.9),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'CHIVALRIC LITERATURE COMPANION',
                                style: AppTypography.labelSmall.copyWith(
                                  color: const Color(0xFFF3D99B),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.8,
                                  fontSize: 9.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.7),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: 28,
                              height: 1.2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.antiqueGold.withValues(alpha: 0.9),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Bottom Illuminated Loading Dock
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Cycling Cervantes quote with smooth crossfade
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 450),
                          child: Padding(
                            key: ValueKey<int>(_quoteIndex),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              _cervantesQuotes[_quoteIndex],
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.quote.copyWith(
                                fontSize: 13.0,
                                color: const Color(0xFFF5ECD8).withValues(alpha: 0.92),
                                height: 1.42,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Sleek Illuminated Antique-Gold Progress Bar (clean, zero clutter)
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _progressAnimation,
                            _ambientController,
                          ]),
                          builder: (context, _) {
                            final val = _progressAnimation.value.clamp(0.0, 1.0);
                            final shimmer = _ambientController.value;

                            return Container(
                              height: 10,
                              width: double.infinity,
                              padding: const EdgeInsets.all(1.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.antiqueGold.withValues(alpha: 0.45),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final fillWidth = math.max(
                                    8.0,
                                    constraints.maxWidth * val,
                                  );
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      width: fillWidth,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(999),
                                        gradient: LinearGradient(
                                          begin: Alignment(-1.2 + shimmer * 2.4, 0),
                                          end: Alignment(0.2 + shimmer * 2.4, 0),
                                          colors: const [
                                            Color(0xFFC5932C),
                                            Color(0xFFF7DC8B),
                                            Color(0xFFD9A63A),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.antiqueGold.withValues(alpha: 0.65),
                                            blurRadius: 10,
                                            spreadRadius: 0.5,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
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

class _SunlitDustPainter extends CustomPainter {
  final double progress;
  _SunlitDustPainter(this.progress);

  static const _motes = [
    (0.14, 0.22, 1.8, 0.35),
    (0.82, 0.18, 2.2, 0.50),
    (0.28, 0.52, 1.5, 0.28),
    (0.74, 0.44, 2.0, 0.40),
    (0.50, 0.32, 1.6, 0.30),
    (0.88, 0.66, 1.9, 0.38),
    (0.18, 0.72, 1.7, 0.32),
    (0.62, 0.78, 2.1, 0.42),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < _motes.length; i++) {
      final (bx, by, radius, maxAlpha) = _motes[i];
      final phase = (progress + i * 0.17) % 1.0;
      final x = size.width * bx + math.sin(phase * math.pi * 2 + i) * 10;
      final y = size.height * ((by - phase * 0.14) % 1.0);
      final alpha = (math.sin(phase * math.pi) * maxAlpha).clamp(0.0, 1.0);
      paint.color = const Color(0xFFFFEAB0).withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SunlitDustPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
