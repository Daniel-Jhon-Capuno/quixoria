import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/state/app_state.dart';
import '../../models/app_theme_preset.dart';
import '../../models/quest_level.dart';
import 'quixote_mascot.dart';
import 'offline_warning_dialog.dart';

class WindingPathView extends StatefulWidget {
  final List<QuestLevel> levels;
  final Function(QuestLevel level) onLevelTap;

  const WindingPathView({
    super.key,
    required this.levels,
    required this.onLevelTap,
  });

  @override
  State<WindingPathView> createState() => _WindingPathViewState();
}

class _WindingPathViewState extends State<WindingPathView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.levels.isEmpty) {
      return const Center(child: Text('No quest levels available'));
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<AppState>();
    final preset = state.activeThemePreset;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const double nodeSpacing = 130.0;

        // Group levels dynamically by chapterIndex (or chunk into 5-6 levels per zone)
        final zone0 = <QuestLevel>[];
        final zone1 = <QuestLevel>[];
        final zone2 = <QuestLevel>[];

        for (final lvl in widget.levels) {
          if (lvl.chapterIndex == 0) {
            zone0.add(lvl);
          } else if (lvl.chapterIndex == 1) {
            zone1.add(lvl);
          } else {
            zone2.add(lvl);
          }
        }

        // Fallback: if all levels have chapterIndex 0 or empty, chunk them evenly
        if (zone1.isEmpty && zone2.isEmpty && widget.levels.length >= 6) {
          final chunkSize = (widget.levels.length / 3).ceil();
          zone0.clear();
          zone1.clear();
          zone2.clear();
          for (int i = 0; i < widget.levels.length; i++) {
            if (i < chunkSize) {
              zone0.add(widget.levels[i]);
            } else if (i < chunkSize * 2) {
              zone1.add(widget.levels[i]);
            } else {
              zone2.add(widget.levels[i]);
            }
          }
        }

        int startIdx0 = 0;
        int startIdx1 = zone0.length;
        int startIdx2 = zone0.length + zone1.length;

        return AnimatedBuilder(
          animation: _ambientController,
          builder: (context, _) {
            return Column(
              children: [
                // ZONE 1: SPRING / LA MANCHA
                if (zone0.isNotEmpty) ...[
                  _buildZoneHeader(
                    icon: Icons.wind_power_rounded,
                    title: 'ZONE I: PLAINS OF LA MANCHA',
                    subtitle: 'Spring • The Windmills & The Chivalric Calling',
                    completedCount: zone0.where((l) => l.isCompleted).length,
                    totalCount: zone0.length,
                    badgeColor: preset.accent,
                    theme: theme,
                  ),
                  _buildSubPath(
                    subLevels: zone0,
                    startIndex: startIdx0,
                    totalWidth: totalWidth,
                    nodeSpacing: nodeSpacing,
                    zoneType: _ZoneType.windmills,
                    isDark: isDark,
                    animValue: _ambientController.value,
                    preset: preset,
                  ),
                ],

                // ZONE 2: SUMMER / GREENWOOD & RIVERBANK
                if (zone1.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _buildZoneHeader(
                    icon: Icons.forest_rounded,
                    title: 'ZONE II: THE SECRET GREENWOOD',
                    subtitle: 'Summer • Ancient Moors, Willows & Hidden Keys',
                    completedCount: zone1.where((l) => l.isCompleted).length,
                    totalCount: zone1.length,
                    badgeColor: preset.secondary,
                    theme: theme,
                  ),
                  _buildSubPath(
                    subLevels: zone1,
                    startIndex: startIdx1,
                    totalWidth: totalWidth,
                    nodeSpacing: nodeSpacing,
                    zoneType: _ZoneType.riverAndCottage,
                    isDark: isDark,
                    animValue: _ambientController.value,
                    preset: preset,
                  ),
                ],

                // ZONE 3: AUTUMN / MEDIEVAL CITADEL
                if (zone2.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _buildZoneHeader(
                    icon: Icons.fort_rounded,
                    title: 'ZONE III: THE MEDIEVAL CITADEL',
                    subtitle: 'Autumn • Chivalric Stone Keeps & The Grand Exam',
                    completedCount: zone2.where((l) => l.isCompleted).length,
                    totalCount: zone2.length,
                    badgeColor: preset.primary,
                    theme: theme,
                  ),
                  _buildSubPath(
                    subLevels: zone2,
                    startIndex: startIdx2,
                    totalWidth: totalWidth,
                    nodeSpacing: nodeSpacing,
                    zoneType: _ZoneType.citadel,
                    isDark: isDark,
                    animValue: _ambientController.value,
                    preset: preset,
                  ),
                ],

                const SizedBox(height: 28),

                // FINAL APEX LANDMARK: CASTLE OF MASTERY
                _buildCastleApex(totalWidth, theme),
                const SizedBox(height: 40),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildZoneHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required int completedCount,
    required int totalCount,
    required Color badgeColor,
    required ThemeData theme,
  }) {
    final isAllCompleted = completedCount == totalCount && totalCount > 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: badgeColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelSmall.copyWith(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isAllCompleted
                  ? AppColors.antiqueGold.withValues(alpha: 0.2)
                  : badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isAllCompleted ? AppColors.antiqueGold : badgeColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAllCompleted) ...[
                  const Icon(Icons.check_circle_rounded, size: 13, color: AppColors.antiqueGold),
                  const SizedBox(width: 4),
                ],
                Text(
                  '$completedCount / $totalCount',
                  style: AppTypography.labelSmall.copyWith(
                    color: isAllCompleted ? AppColors.antiqueGold : badgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubPath({
    required List<QuestLevel> subLevels,
    required int startIndex,
    required double totalWidth,
    required double nodeSpacing,
    required _ZoneType zoneType,
    required bool isDark,
    required double animValue,
    required AppThemePreset preset,
  }) {
    if (subLevels.isEmpty) return const SizedBox.shrink();

    final height = subLevels.length * nodeSpacing + 50.0;
    final offsets = [0.0, 0.55, -0.55, 0.45, -0.45];

    final points = <Offset>[];
    for (int i = 0; i < subLevels.length; i++) {
      final globalIndex = startIndex + i;
      final xRatio = offsets[globalIndex % offsets.length];
      final x = (totalWidth / 2) + (xRatio * (totalWidth * 0.28));
      final y = 60.0 + (i * nodeSpacing);
      points.add(Offset(x, y));
    }

    return Container(
      width: totalWidth,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Rich Fantasy Adventure Map Painter (Contour lines, Windmills, Rivers, Castles, Houses, Trees, 'X')
          Positioned.fill(
            child: CustomPaint(
              painter: _FantasyAdventureMapPainter(
                points: points,
                zoneType: zoneType,
                isDark: isDark,
                animValue: animValue,
                preset: preset,
              ),
            ),
          ),

          // 2. Animated 3D Duolingo Level Nodes with Active Pulse and Floating "START" Badge
          for (int i = 0; i < subLevels.length; i++)
            Positioned(
              left: points[i].dx - 40,
              top: points[i].dy - 40,
              child: _DuoLevelNode(
                level: subLevels[i],
                isCurrent: !subLevels[i].isCompleted && !subLevels[i].isLocked,
                isLeftAligned: points[i].dx < totalWidth / 2,
                onTap: () => widget.onLevelTap(subLevels[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCastleApex(double totalWidth, ThemeData theme) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.antiqueGold.withValues(alpha: 0.4), width: 4),
              ),
            ),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C3E50), Color(0xFF1A252F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.antiqueGold, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.antiqueGold.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.military_tech_rounded,
                  size: 48,
                  color: AppColors.antiqueGold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Castle of Mastery',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Celestial Era • The Golden Key Sanctuary',
          style: AppTypography.bodySmall.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

enum _ZoneType { windmills, riverAndCottage, citadel }

class _DuoLevelNode extends StatefulWidget {
  final QuestLevel level;
  final bool isCurrent;
  final bool isLeftAligned;
  final VoidCallback onTap;

  const _DuoLevelNode({
    required this.level,
    required this.isCurrent,
    this.isLeftAligned = true,
    required this.onTap,
  });

  @override
  State<_DuoLevelNode> createState() => _DuoLevelNodeState();
}

class _DuoLevelNodeState extends State<_DuoLevelNode>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _bounceController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
    );

    // 3800ms total cycle: 800ms dynamic bounce hop sequence + 3000ms idle pause (3 seconds gap between bounces)
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    if (widget.isCurrent) {
      _pulseController.repeat(reverse: true);
      _bounceController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _DuoLevelNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isCurrent && _pulseController.isAnimating) {
      _pulseController.stop();
    }

    if (widget.isCurrent && !_bounceController.isAnimating) {
      _bounceController.repeat();
    } else if (!widget.isCurrent && _bounceController.isAnimating) {
      _bounceController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  (double offsetY, double scaleX, double scaleY) _calculateBounceTransform(double t) {
    // Total cycle: 3800ms
    // Active bounce hop: 800ms (t in 0.0 .. 0.2105)
    // Stationary pause: 3000ms (exactly 3.0 seconds gap, t in 0.2105 .. 1.0)
    const activeCutoff = 800.0 / 3800.0;
    if (t >= activeCutoff) {
      return (0.0, 1.0, 1.0);
    }

    final p = t / activeCutoff; // 0.0 to 1.0 during the 800ms bounce

    if (p < 0.48) {
      // 1. Initial High Jump (up to -24px)
      final jump = p / 0.48;
      final arc = sin(jump * pi);
      final offsetY = -arc * 24.0;
      final scaleY = 1.0 + (arc * 0.12);
      final scaleX = 1.0 - (arc * 0.08);
      return (offsetY, scaleX, scaleY);
    } else if (p < 0.62) {
      // 2. Landing Squash & Impact
      final squash = (p - 0.48) / 0.14;
      final arc = sin(squash * pi);
      final scaleY = 1.0 - (arc * 0.16);
      final scaleX = 1.0 + (arc * 0.14);
      return (0.0, scaleX, scaleY);
    } else if (p < 0.88) {
      // 3. Secondary Rebound Hop (-10px)
      final rebound = (p - 0.62) / 0.26;
      final arc = sin(rebound * pi);
      final offsetY = -arc * 10.0;
      final scaleY = 1.0 + (arc * 0.06);
      final scaleX = 1.0 - (arc * 0.04);
      return (offsetY, scaleX, scaleY);
    } else {
      // 4. Settling back to flat ground
      return (0.0, 1.0, 1.0);
    }
  }

  void _handleTapDown(TapDownDetails _, bool isEffectivelyLocked) {
    if (isEffectivelyLocked) return;
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _, bool isOfflineQuizLocked) {
    setState(() => _isPressed = false);
    if (isOfflineQuizLocked) {
      OfflineWarningDialog.show(context);
      return;
    }
    if (widget.level.isLocked) return;
    widget.onTap();
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    const double bevelDepth = 5.0;

    // Real-time offline detection: quizzes lock offline, only reading parts stay open
    final appState = context.watch<AppState>();
    final isOnline = appState.isOnline;
    final isQuiz = level.type != LevelType.read;
    final isOfflineQuizLocked = !isOnline && isQuiz && !level.isCompleted;
    final isEffectivelyLocked = level.isLocked || isOfflineQuizLocked;

    Color faceColor;
    Color bevelColor;
    Color borderColor;
    Color iconColor;

    if (level.isCompleted) {
      faceColor = primary;
      bevelColor = Color.alphaBlend(Colors.black.withValues(alpha: isDark ? 0.45 : 0.35), primary);
      borderColor = AppColors.antiqueGold;
      iconColor = theme.colorScheme.onPrimary;
    } else if (isOfflineQuizLocked) {
      faceColor = isDark ? const Color(0xFF2A231C) : const Color(0xFFE5DDD3);
      bevelColor = isDark ? const Color(0xFF1E1812) : const Color(0xFFC3B6AA);
      borderColor = AppColors.streakOrange.withValues(alpha: 0.85);
      iconColor = AppColors.streakOrange;
    } else if (widget.isCurrent) {
      faceColor = AppColors.antiqueGold;
      bevelColor = const Color(0xFF8E660E);
      borderColor = primary;
      iconColor = isDark ? const Color(0xFF121212) : AppColors.inkDark;
    } else {
      faceColor = isDark ? const Color(0xFF282828) : const Color(0xFFD7CDBF);
      bevelColor = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFB5A998);
      borderColor = isDark ? const Color(0xFF383838) : const Color(0xFFC5B9A6);
      iconColor = isDark ? const Color(0xFF666666) : const Color(0xFF8A7F70);
    }

    // Steady shadow depth
    const shadowOffsetY = bevelDepth + 2.0;
    const shadowBlur = 6.0;

    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Dual Concentric Beating Golden Halo / Ring (Glow on outer side; Positioned.fill so it NEVER resizes Stack)
          if (widget.isCurrent)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) {
                  final pulse = _pulseAnimation.value;
                  final auraSize = 86.0 + (pulse * 8.0);
                  final outerAuraSize = 98.0 + (pulse * 12.0);
                  final auraOpacity = (1.0 - pulse * 0.45).clamp(0.0, 1.0);
                  return Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: outerAuraSize,
                          height: outerAuraSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.antiqueGold.withValues(alpha: 0.35 * auraOpacity),
                              width: 2.0,
                            ),
                          ),
                        ),
                        Container(
                          width: auraSize,
                          height: auraSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.antiqueGold.withValues(alpha: 0.70 * auraOpacity),
                              width: 3.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.antiqueGold.withValues(alpha: 0.40 * auraOpacity),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // 2. The Level Node with Button and Badges (Bounces with a 3 seconds gap between each bounce)
          AnimatedBuilder(
            animation: _bounceController,
            builder: (context, child) {
              final (offsetY, scaleX, scaleY) = widget.isCurrent
                  ? _calculateBounceTransform(_bounceController.value)
                  : (0.0, 1.0, 1.0);
              return Transform.translate(
                offset: Offset(0, offsetY),
                child: Transform.scale(
                  scaleX: scaleX,
                  scaleY: scaleY,
                  alignment: Alignment.bottomCenter,
                  child: child,
                ),
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTapDown: (details) => _handleTapDown(details, isEffectivelyLocked),
                  onTapUp: (details) => _handleTapUp(details, isOfflineQuizLocked),
                  onTapCancel: _handleTapCancel,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: faceColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 3.2),
                      boxShadow: _isPressed
                          ? []
                          : [
                              BoxShadow(
                                color: bevelColor,
                                offset: const Offset(0, bevelDepth),
                                blurRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: widget.isCurrent ? 0.22 : 0.15),
                                offset: const Offset(0, shadowOffsetY),
                                blurRadius: shadowBlur,
                              ),
                            ],
                    ),
                    child: Center(
                      child: Icon(
                        _getNodeIcon(level.type, level.isCompleted, level.isLocked, isOfflineQuizLocked),
                        color: iconColor,
                        size: 34,
                      ),
                    ),
                  ),
                ),

                // New Unconquered Level Badge with Number Badge (or Wi-Fi Lock indicator)
                if (widget.isCurrent && !level.isCompleted)
                  Positioned(
                    top: -8,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isOfflineQuizLocked ? AppColors.streakOrange : AppColors.vermillion,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 1.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isOfflineQuizLocked ? 'WI-FI' : 'NEW',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: isOfflineQuizLocked
                                  ? const Icon(
                                      Icons.lock_rounded,
                                      size: 9,
                                      color: AppColors.streakOrange,
                                    )
                                  : const Text(
                                      '1',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.vermillion,
                                        height: 1.0,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 3. Completed Laurel Checkmark Badge
                if (level.isCompleted)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.antiqueGold,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: isDark ? const Color(0xFF121212) : primary,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 4. Don Quixote Character on Active Node (Stationary, standing still, no pill below him)
          if (widget.isCurrent)
            Positioned(
              right: widget.isLeftAligned ? null : 84,
              left: widget.isLeftAligned ? 84 : null,
              top: 6,
              child: GestureDetector(
                onTap: widget.onTap,
                child: const QuixoteMascot(
                  size: 64,
                  expression: QuixoteExpression.idle,
                  showSpeechBubble: false,
                  interactive: false,
                  stationary: true,
                  showShadow: false,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getNodeIcon(LevelType type, bool isCompleted, bool isLocked, bool isOfflineQuizLocked) {
    if (isOfflineQuizLocked) {
      return Icons.wifi_off_rounded;
    }
    if (isLocked) {
      return Icons.lock_rounded;
    }
    switch (type) {
      case LevelType.read:
        return Icons.auto_stories_rounded;
      case LevelType.recall:
        return Icons.psychology_rounded;
      case LevelType.practice:
        return Icons.shield_rounded;
      case LevelType.analysis:
        return Icons.visibility_rounded;
      case LevelType.finalTest:
        return Icons.military_tech_rounded;
    }
  }
}

/// Rich Fantasy Adventure Map Painter
/// Renders authentic cartographic features:
/// - Parchment terrain with subtle topographic elevation lines
/// - Broken dashed winding quest path with stepping stones
/// - Animated spinning Windmill sails of La Mancha
/// - Meandering blue river with rustic wooden bridge
/// - Rural village thatched cottage with smoking chimney
/// - Medieval stone fortress with battlements & flying pennant
/// - Mystery "X" Marks the Spot with treasure chest
/// - Clustered pine and oak groves, and vintage Compass Rose
class _FantasyAdventureMapPainter extends CustomPainter {
  final List<Offset> points;
  final _ZoneType zoneType;
  final bool isDark;
  final double animValue;
  final AppThemePreset preset;

  _FantasyAdventureMapPainter({
    required this.points,
    required this.zoneType,
    required this.isDark,
    required this.animValue,
    required this.preset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Map Canvas Background & Topographic Contours
    _drawTerrainAndContours(canvas, size);

    // 2. Zone Specific Illustrated Landmarks (Windmills, Castles, Houses, Trees, River, X)
    switch (zoneType) {
      case _ZoneType.windmills:
        _drawWindmillZone(canvas, size);
        break;
      case _ZoneType.riverAndCottage:
        _drawRiverAndCottageZone(canvas, size);
        break;
      case _ZoneType.citadel:
        _drawCitadelZone(canvas, size);
        break;
    }

    // 3. Broken / Dashed Quest Trail connecting nodes
    _drawBrokenDashedTrail(canvas, size);
  }

  void _drawTerrainAndContours(Canvas canvas, Size size) {
    final isSnowy = preset.interfaceStyle == ThemeInterfaceStyle.snowy;
    final isPink = preset.id == 'theme_cute_meadow';
    final isMedieval = preset.interfaceStyle == ThemeInterfaceStyle.medieval;

    List<Color> bgColors;
    if (isDark) {
      bgColors = [
        const Color(0xFF141414),
        const Color(0xFF101010),
        const Color(0xFF0C0C0C),
      ];
    } else if (isSnowy) {
      bgColors = [
        const Color(0xFFF0F6FA),
        const Color(0xFFE4F0F7),
        const Color(0xFFD6E7F2),
      ];
    } else if (isPink) {
      bgColors = [
        const Color(0xFFFFF0F4),
        const Color(0xFFFCE4EC),
        const Color(0xFFF8BBD0),
      ];
    } else if (isMedieval) {
      bgColors = [
        const Color(0xFFFDF7F7),
        const Color(0xFFF7EDED),
        const Color(0xFFEFE2E2),
      ];
    } else {
      bgColors = [
        const Color(0xFFFAF5E8),
        const Color(0xFFF3E7D0),
        const Color(0xFFEBE0C7),
      ];
    }

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: bgColors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    Color hill1;
    Color hill2;
    Color contour;
    Color neatline;
    Color grassColor;

    if (isDark) {
      hill1 = const Color(0xFF1B1B1B);
      hill2 = const Color(0xFF151515);
      contour = const Color(0xFF282828);
      neatline = const Color(0xFF2E2E2E);
      grassColor = const Color(0xFF333333);
    } else if (isSnowy) {
      hill1 = const Color(0xFFD2E6F2);
      hill2 = const Color(0xFFC3DEF0);
      contour = const Color(0xFFA5CDE5);
      neatline = const Color(0xFFBCE0F0);
      grassColor = const Color(0xFF7FA8C9);
    } else if (isPink) {
      hill1 = const Color(0xFFFCE4EC);
      hill2 = const Color(0xFFF8BBD0);
      contour = const Color(0xFFF48FB1);
      neatline = const Color(0xFFF7BCCB);
      grassColor = const Color(0xFFD85A82);
    } else if (isMedieval) {
      hill1 = const Color(0xFFEADFD8);
      hill2 = const Color(0xFFE2D4CD);
      contour = const Color(0xFFD2B9B4);
      neatline = const Color(0xFFE8C2C8);
      grassColor = const Color(0xFFBA2D42);
    } else {
      hill1 = const Color(0xFFE5DAC4);
      hill2 = const Color(0xFFDDD0B8);
      contour = const Color(0xFFD6C5AA);
      neatline = const Color(0xFFDAC7AB);
      grassColor = const Color(0xFF7A8D7E);
    }

    final hillPaint1 = Paint()
      ..color = hill1.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    final h1 = Path()
      ..moveTo(0, size.height * 0.35)
      ..cubicTo(size.width * 0.35, size.height * 0.28, size.width * 0.65, size.height * 0.42, size.width, size.height * 0.32)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(h1, hillPaint1);

    final hillPaint2 = Paint()
      ..color = hill2.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    final h2 = Path()
      ..moveTo(0, size.height * 0.72)
      ..cubicTo(size.width * 0.40, size.height * 0.78, size.width * 0.70, size.height * 0.66, size.width, size.height * 0.74)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(h2, hillPaint2);

    // 3. Topographic Elevation Contour Lines
    final contourPaint = Paint()
      ..color = contour.withValues(alpha: 0.55)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    final c1 = Path();
    c1.moveTo(0, size.height * 0.18);
    c1.cubicTo(size.width * 0.3, size.height * 0.12, size.width * 0.7, size.height * 0.24, size.width, size.height * 0.18);
    canvas.drawPath(c1, contourPaint);

    final c2 = Path();
    c2.moveTo(0, size.height * 0.52);
    c2.cubicTo(size.width * 0.28, size.height * 0.58, size.width * 0.72, size.height * 0.46, size.width, size.height * 0.54);
    canvas.drawPath(c2, contourPaint);

    final c3 = Path();
    c3.moveTo(0, size.height * 0.88);
    c3.cubicTo(size.width * 0.32, size.height * 0.82, size.width * 0.68, size.height * 0.94, size.width, size.height * 0.86);
    canvas.drawPath(c3, contourPaint);

    // 4. Cartographic Neatline / Double Border Frame with Corner Fleurons
    _drawCartographicNeatline(canvas, size, neatline);

    // 5. Scattered Meadow Grass Tufts (Hand-drawn clusters)
    _drawGrassTuft(canvas, Offset(24, size.height * 0.22), grassColor);
    _drawGrassTuft(canvas, Offset(size.width - 38, size.height * 0.16), grassColor);
    _drawGrassTuft(canvas, Offset(42, size.height * 0.58), grassColor);
    _drawGrassTuft(canvas, Offset(size.width - 28, size.height * 0.62), grassColor);
    _drawGrassTuft(canvas, Offset(30, size.height * 0.92), grassColor);
    _drawGrassTuft(canvas, Offset(size.width - 44, size.height * 0.88), grassColor);

    // 6. Flying Birds (Gliding V-silhouettes in open sky)
    _drawBirds(canvas, Offset(size.width * 0.22, size.height * 0.12));
    _drawBirds(canvas, Offset(size.width * 0.75, size.height * 0.42));

    // 7. Cartographic Compass Rose in corner of Zone 1
    if (zoneType == _ZoneType.windmills) {
      _drawCompassRose(canvas, Offset(size.width - 45, 45));
    }
  }

  void _drawCartographicNeatline(Canvas canvas, Size size, Color neatlineColor) {
    const margin = 10.0;
    final neatlinePaint = Paint()
      ..color = neatlineColor.withValues(alpha: 0.65)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final outerRect = Rect.fromLTWH(margin, margin, size.width - margin * 2, size.height - margin * 2);
    canvas.drawRect(outerRect, neatlinePaint);

    // Corner diamond accents
    final diamondPaint = Paint()
      ..color = (isDark ? AppColors.antiqueGold.withValues(alpha: 0.5) : const Color(0xFFB59A75))
      ..style = PaintingStyle.fill;

    for (final corner in [
      Offset(margin, margin),
      Offset(size.width - margin, margin),
      Offset(margin, size.height - margin),
      Offset(size.width - margin, size.height - margin),
    ]) {
      final p = Path()
        ..moveTo(corner.dx, corner.dy - 3)
        ..lineTo(corner.dx + 3, corner.dy)
        ..lineTo(corner.dx, corner.dy + 3)
        ..lineTo(corner.dx - 3, corner.dy)
        ..close();
      canvas.drawPath(p, diamondPaint);
    }
  }

  void _drawGrassTuft(Canvas canvas, Offset pos, Color color) {
    final grassPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // 3 small blades: left, middle, right
    canvas.drawLine(pos, Offset(pos.dx - 3, pos.dy - 6), grassPaint);
    canvas.drawLine(pos, Offset(pos.dx, pos.dy - 8), grassPaint);
    canvas.drawLine(pos, Offset(pos.dx + 3, pos.dy - 6), grassPaint);
  }

  void _drawBirds(Canvas canvas, Offset pos) {
    final birdPaint = Paint()
      ..color = (isDark ? const Color(0xFF666666) : const Color(0xFF8C7D68)).withValues(alpha: 0.65)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 2; i++) {
      final ox = pos.dx + (i * 12);
      final oy = pos.dy + (i * 5);
      final bp = Path()
        ..moveTo(ox - 5, oy)
        ..quadraticBezierTo(ox - 2.5, oy - 3, ox, oy)
        ..quadraticBezierTo(ox + 2.5, oy - 3, ox + 5, oy);
      canvas.drawPath(bp, birdPaint);
    }
  }

  void _drawBrokenDashedTrail(Canvas canvas, Size size) {
    if (points.length < 2) return;

    // Build the cubic smooth path between points
    final fullPath = Path();
    fullPath.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midY = (p0.dy + p1.dy) / 2;
      fullPath.cubicTo(p0.dx, midY, p1.dx, midY, p1.dx, p1.dy);
    }

    // 1. Under-trail border (dirt track / trail bed)
    final isSnowy = preset.interfaceStyle == ThemeInterfaceStyle.snowy;
    final isPink = preset.id == 'theme_cute_meadow';
    final isMedieval = preset.interfaceStyle == ThemeInterfaceStyle.medieval;

    Color trailBed;
    Color dashColor;
    if (isDark) {
      trailBed = const Color(0xFF181818);
      dashColor = const Color(0xFFE5B842);
    } else if (isSnowy) {
      trailBed = const Color(0xFFDDEAF4);
      dashColor = const Color(0xFF1B4965);
    } else if (isPink) {
      trailBed = const Color(0xFFFFE1E8);
      dashColor = const Color(0xFFC24168);
    } else if (isMedieval) {
      trailBed = const Color(0xFFFCEBEB);
      dashColor = const Color(0xFF991B2D);
    } else {
      trailBed = const Color(0xFFE4D6C3);
      dashColor = const Color(0xFF8B5E3C);
    }

    final trailBedPaint = Paint()
      ..color = trailBed
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(fullPath, trailBedPaint);

    // 2. Broken / Dashed line (- - - -)
    final dashPaint = Paint()
      ..color = dashColor.withValues(alpha: 0.85)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Approximate dashed path by sampling points along the path metrics
    final pathMetrics = fullPath.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0.0;
      const double dashLength = 8.0;
      const double gapLength = 6.0;

      while (distance < metric.length) {
        final extractLen = min(dashLength, metric.length - distance);
        final segment = metric.extractPath(distance, distance + extractLen);
        canvas.drawPath(segment, dashPaint);
        distance += dashLength + gapLength;
      }
    }
  }

  void _drawWindmillZone(Canvas canvas, Size size) {
    // 1. Don Quixote's Famous Spanish Windmill on Left Hill
    final wmCenter = Offset(52, size.height * 0.42);
    _drawWindmill(canvas, wmCenter, animValue);

    // 2. Rural Thatched Cottage Farm on Right
    final farmCenter = Offset(size.width - 55, size.height * 0.70);
    _drawCottage(canvas, farmCenter);

    // 3. Clustered Pine & Oak Trees
    _drawTree(canvas, Offset(26, size.height * 0.78), 16);
    _drawTree(canvas, Offset(42, size.height * 0.84), 13);
    _drawTree(canvas, Offset(size.width - 34, size.height * 0.28), 14);

    // 4. Mystery "X" Marks the Spot (Lore Cache)
    _drawTreasureX(canvas, Offset(size.width - 50, size.height * 0.50));
  }

  void _drawRiverAndCottageZone(Canvas canvas, Size size) {
    // 1. Winding Blue River cutting across the path
    final riverPaint = Paint()
      ..color = const Color(0xFF5DADE2).withValues(alpha: isDark ? 0.35 : 0.45)
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final riverPath = Path();
    riverPath.moveTo(0, size.height * 0.48);
    riverPath.cubicTo(size.width * 0.35, size.height * 0.40, size.width * 0.65, size.height * 0.58, size.width, size.height * 0.52);
    canvas.drawPath(riverPath, riverPaint);

    // Wooden Bridge Planks where trail intersects
    final bridgePaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final bridgeX = size.width * 0.5;
    final bridgeY = size.height * 0.49;
    for (int i = -3; i <= 3; i++) {
      canvas.drawLine(
        Offset(bridgeX + i * 5, bridgeY - 14),
        Offset(bridgeX + i * 5, bridgeY + 14),
        bridgePaint,
      );
    }

    // 2. Riverbank Cottage with Thatched Roof
    _drawCottage(canvas, Offset(56, size.height * 0.32));

    // 3. Dense Forest of Willow and Pine Trees
    _drawTree(canvas, Offset(28, size.height * 0.62), 17);
    _drawTree(canvas, Offset(45, size.height * 0.70), 14);
    _drawTree(canvas, Offset(size.width - 48, size.height * 0.25), 18);
    _drawTree(canvas, Offset(size.width - 32, size.height * 0.33), 13);
    _drawTree(canvas, Offset(size.width - 52, size.height * 0.75), 15);

    // 4. Hidden Treasure "X"
    _drawTreasureX(canvas, Offset(46, size.height * 0.85));
  }

  void _drawCitadelZone(Canvas canvas, Size size) {
    // 1. Medieval Fortress / Castle Turrets on Right Cliff
    _drawCastleKeep(canvas, Offset(size.width - 58, size.height * 0.38));

    // 2. Second Windmill on Left
    _drawWindmill(canvas, Offset(50, size.height * 0.72), animValue + 0.5);

    // 3. Mountain Ridge Peaks
    _drawMountainPeaks(canvas, Offset(35, size.height * 0.22));

    // 4. Guard Watchpost & Trees
    _drawTree(canvas, Offset(size.width - 36, size.height * 0.68), 16);
    _drawTree(canvas, Offset(size.width - 54, size.height * 0.76), 14);

    // 5. Grand Quest "X" Marks the Spot
    _drawTreasureX(canvas, Offset(52, size.height * 0.48));
  }

  void _drawWindmill(Canvas canvas, Offset pos, double rotProgress) {
    final bodyPaint = Paint()..color = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFC7B79E);
    final roofPaint = Paint()..color = const Color(0xFF8B2635);
    final sailPaint = Paint()
      ..color = isDark ? const Color(0xFFD4A338) : const Color(0xFF5D4037)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    // Windmill Tower Base
    final towerPath = Path();
    towerPath.moveTo(pos.dx - 14, pos.dy + 18);
    towerPath.lineTo(pos.dx - 9, pos.dy - 12);
    towerPath.lineTo(pos.dx + 9, pos.dy - 12);
    towerPath.lineTo(pos.dx + 14, pos.dy + 18);
    towerPath.close();
    canvas.drawPath(towerPath, bodyPaint);

    // Conical Roof
    final roofPath = Path();
    roofPath.moveTo(pos.dx - 12, pos.dy - 12);
    roofPath.lineTo(pos.dx, pos.dy - 24);
    roofPath.lineTo(pos.dx + 12, pos.dy - 12);
    roofPath.close();
    canvas.drawPath(roofPath, roofPaint);

    // Little Door
    final doorPaint = Paint()..color = const Color(0xFF3E2723);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(pos.dx, pos.dy + 12), width: 6, height: 10),
        const Radius.circular(2),
      ),
      doorPaint,
    );

    // Animated Rotating Sails (Blades)
    canvas.save();
    canvas.translate(pos.dx, pos.dy - 12);
    canvas.rotate(rotProgress * 2 * pi);

    for (int i = 0; i < 4; i++) {
      canvas.save();
      canvas.rotate(i * pi / 2);
      canvas.drawLine(Offset.zero, const Offset(0, -26), sailPaint);

      // Sail lattice rect
      final latticePaint = Paint()
        ..color = (isDark ? const Color(0xFFF0EBE1) : const Color(0xFFEDE0D0)).withValues(alpha: 0.75)
        ..style = PaintingStyle.fill;
      canvas.drawRect(const Rect.fromLTWH(2, -24, 6, 18), latticePaint);
      canvas.restore();
    }
    canvas.restore();
  }

  void _drawCottage(Canvas canvas, Offset pos) {
    final wallPaint = Paint()..color = isDark ? const Color(0xFF262626) : const Color(0xFFD5C4A1);
    final thatchRoof = Paint()..color = const Color(0xFF9E6B38);
    final chimneyPaint = Paint()..color = const Color(0xFF5D4037);

    // Chimney
    canvas.drawRect(Rect.fromLTWH(pos.dx + 6, pos.dy - 18, 5, 10), chimneyPaint);

    // Chimney Smoke Puffs (animated)
    final smokePaint = Paint()
      ..color = (isDark ? Colors.white54 : Colors.grey.withValues(alpha: 0.4))
      ..style = PaintingStyle.fill;
    final smokeOffset = (animValue * 10) % 12;
    canvas.drawCircle(Offset(pos.dx + 8, pos.dy - 22 - smokeOffset), 2.5, smokePaint);
    canvas.drawCircle(Offset(pos.dx + 10, pos.dy - 28 - smokeOffset), 3.5, smokePaint);

    // House Walls
    canvas.drawRect(Rect.fromLTWH(pos.dx - 14, pos.dy - 6, 28, 18), wallPaint);

    // Thatched Triangular Roof
    final roof = Path();
    roof.moveTo(pos.dx - 18, pos.dy - 6);
    roof.lineTo(pos.dx, pos.dy - 20);
    roof.lineTo(pos.dx + 18, pos.dy - 6);
    roof.close();
    canvas.drawPath(roof, thatchRoof);

    // Door and Window
    final doorPaint = Paint()..color = const Color(0xFF4A3423);
    canvas.drawRect(Rect.fromLTWH(pos.dx - 3, pos.dy + 2, 7, 10), doorPaint);
  }

  void _drawCastleKeep(Canvas canvas, Offset pos) {
    final stonePaint = Paint()..color = isDark ? const Color(0xFF242424) : const Color(0xFFB8A99A);
    final flagPaint = Paint()..color = const Color(0xFFC84B31);

    // Central keep
    canvas.drawRect(Rect.fromLTWH(pos.dx - 16, pos.dy - 10, 32, 24), stonePaint);

    // Left tower & crenellations
    canvas.drawRect(Rect.fromLTWH(pos.dx - 22, pos.dy - 22, 10, 36), stonePaint);
    canvas.drawRect(Rect.fromLTWH(pos.dx - 22, pos.dy - 26, 3, 4), stonePaint);
    canvas.drawRect(Rect.fromLTWH(pos.dx - 15, pos.dy - 26, 3, 4), stonePaint);

    // Right tower & crenellations
    canvas.drawRect(Rect.fromLTWH(pos.dx + 12, pos.dy - 22, 10, 36), stonePaint);
    canvas.drawRect(Rect.fromLTWH(pos.dx + 12, pos.dy - 26, 3, 4), stonePaint);
    canvas.drawRect(Rect.fromLTWH(pos.dx + 19, pos.dy - 26, 3, 4), stonePaint);

    // Flagpole and animated waving banner
    final polePaint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(pos.dx + 17, pos.dy - 26), Offset(pos.dx + 17, pos.dy - 38), polePaint);

    final flagPath = Path();
    flagPath.moveTo(pos.dx + 17, pos.dy - 38);
    flagPath.lineTo(pos.dx + 27 + sin(animValue * pi * 4) * 2, pos.dy - 34);
    flagPath.lineTo(pos.dx + 17, pos.dy - 30);
    flagPath.close();
    canvas.drawPath(flagPath, flagPaint);

    // Portcullis arch
    final gatePaint = Paint()..color = isDark ? const Color(0xFF141414) : const Color(0xFF2B2421);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(pos.dx, pos.dy + 6), width: 10, height: 12),
        const Radius.circular(5),
      ),
      gatePaint,
    );
  }

  void _drawTree(Canvas canvas, Offset pos, double size) {
    final isSnowy = preset.interfaceStyle == ThemeInterfaceStyle.snowy;
    final isPink = preset.id == 'theme_cute_meadow';
    final isMedieval = preset.interfaceStyle == ThemeInterfaceStyle.medieval;

    // Trunk
    final trunkColor = isDark ? const Color(0xFF222222) : const Color(0xFF6D4C41);
    final trunkPaint = Paint()
      ..color = trunkColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pos, Offset(pos.dx, pos.dy + size * 0.7), trunkPaint);

    // Foliage
    Color foliage;
    if (isDark) {
      foliage = const Color(0xFF2C2C2C);
    } else if (isSnowy) {
      foliage = const Color(0xFF5D93B8); // Glacial sapphire, NO GREEN
    } else if (isPink) {
      foliage = const Color(0xFFC24168); // Sakura blossom, NO GREEN, NO BLUE
    } else if (isMedieval) {
      foliage = const Color(0xFF991B2D); // Crimson forest
    } else {
      foliage = const Color(0xFF4A7C59);
    }

    final foliagePaint = Paint()
      ..color = foliage.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(pos.dx, pos.dy), size * 0.65, foliagePaint);
    canvas.drawCircle(Offset(pos.dx - size * 0.3, pos.dy - size * 0.2), size * 0.45, foliagePaint);
    canvas.drawCircle(Offset(pos.dx + size * 0.3, pos.dy - size * 0.2), size * 0.45, foliagePaint);
  }

  void _drawTreasureX(Canvas canvas, Offset pos) {
    // Crimson 'X'
    final xPaint = Paint()
      ..color = const Color(0xFFC0392B)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const r = 9.0;
    canvas.drawLine(Offset(pos.dx - r, pos.dy - r), Offset(pos.dx + r, pos.dy + r), xPaint);
    canvas.drawLine(Offset(pos.dx + r, pos.dy - r), Offset(pos.dx - r, pos.dy + r), xPaint);

    // Mini Treasure Chest beside the X
    final chestPaint = Paint()..color = const Color(0xFFD4A338);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(pos.dx + 16, pos.dy), width: 14, height: 10),
        const Radius.circular(2),
      ),
      chestPaint,
    );
  }

  void _drawMountainPeaks(Canvas canvas, Offset pos) {
    final mountainPaint = Paint()..color = isDark ? const Color(0xFF262626) : const Color(0xFF9E8F7D);
    final snowPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);

    final m1 = Path();
    m1.moveTo(pos.dx - 18, pos.dy + 14);
    m1.lineTo(pos.dx, pos.dy - 16);
    m1.lineTo(pos.dx + 18, pos.dy + 14);
    m1.close();
    canvas.drawPath(m1, mountainPaint);

    final s1 = Path();
    s1.moveTo(pos.dx - 6, pos.dy - 6);
    s1.lineTo(pos.dx, pos.dy - 16);
    s1.lineTo(pos.dx + 6, pos.dy - 6);
    s1.close();
    canvas.drawPath(s1, snowPaint);
  }

  void _drawCompassRose(Canvas canvas, Offset pos) {
    final rosePaint = Paint()
      ..color = AppColors.antiqueGold.withValues(alpha: isDark ? 0.6 : 0.75)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(pos, 16, rosePaint);

    // 4 cardinal points
    final needlePaint = Paint()..color = const Color(0xFFC0392B);
    final northNeedle = Path();
    northNeedle.moveTo(pos.dx, pos.dy - 20);
    northNeedle.lineTo(pos.dx - 3, pos.dy);
    northNeedle.lineTo(pos.dx + 3, pos.dy);
    northNeedle.close();
    canvas.drawPath(northNeedle, needlePaint);

    final southPaint = Paint()..color = isDark ? Colors.white60 : Colors.black54;
    final southNeedle = Path();
    southNeedle.moveTo(pos.dx, pos.dy + 20);
    southNeedle.lineTo(pos.dx - 3, pos.dy);
    southNeedle.lineTo(pos.dx + 3, pos.dy);
    southNeedle.close();
    canvas.drawPath(southNeedle, southPaint);
  }

  @override
  bool shouldRepaint(covariant _FantasyAdventureMapPainter oldDelegate) => true;
}
