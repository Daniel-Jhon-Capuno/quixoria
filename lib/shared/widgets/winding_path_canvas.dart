import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/state/app_state.dart';
import '../../data/book_zone_data.dart';
import '../../models/app_theme_preset.dart';
import '../../models/quest_level.dart';
import 'living_biome_painter.dart';
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
        final bookWorld = BookZoneData.forLiterature(state.activeLiterature);

        return AnimatedBuilder(
          animation: _ambientController,
          builder: (context, _) {
            return Column(
              children: [
                // ZONE 1: BOOK-SPECIFIC OPENING SETTING
                if (zone0.isNotEmpty) ...[
                  _buildZoneHeader(
                    icon: bookWorld.zone1.icon,
                    title: bookWorld.zone1.title,
                    subtitle: bookWorld.zone1.subtitle,
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

                // ZONE 2: BOOK-SPECIFIC MID-JOURNEY SETTING
                if (zone1.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _buildZoneHeader(
                    icon: bookWorld.zone2.icon,
                    title: bookWorld.zone2.title,
                    subtitle: bookWorld.zone2.subtitle,
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

                // ZONE 3: BOOK-SPECIFIC CLIMAX SETTING
                if (zone2.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _buildZoneHeader(
                    icon: bookWorld.zone3.icon,
                    title: bookWorld.zone3.title,
                    subtitle: bookWorld.zone3.subtitle,
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

                // FINAL APEX LANDMARK: BOOK-SPECIFIC MASTERY SANCTUARY
                _buildCastleApex(totalWidth, theme, bookWorld),
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
          // 1. Rich Fantasy Adventure Map Painter (Isolated in RepaintBoundary for 60/120 FPS scrolling)
          Positioned.fill(
            child: RepaintBoundary(
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
          ),

          // 1b. Living World Biome Scenery Overlay (Full swaying trees, animated animals, ponds, coral & wildlife)
          if (preset.isLivingBiome)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: LivingBiomePainter(
                      biomeId: preset.biomeId!,
                      animValue: animValue,
                      isDark: isDark,
                      isPreview: false,
                    ),
                  ),
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

  Widget _buildCastleApex(double totalWidth, ThemeData theme, BookWorldSetting bookWorld) {
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
          bookWorld.apexTitle,
          textAlign: TextAlign.center,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          bookWorld.apexSubtitle,
          textAlign: TextAlign.center,
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

    // Real-time offline detection: standard quizzes lock offline, reading & special map encounters stay open
    final appState = context.watch<AppState>();
    final isOnline = appState.isOnline;
    final isQuiz = level.type != LevelType.read && !level.isSpecialNode;
    final isOfflineQuizLocked = !isOnline && isQuiz && !level.isCompleted;
    final isEffectivelyLocked = level.isLocked || isOfflineQuizLocked;

    final Color? specialTint = _specialNodeAccent(level.type);
    Color faceColor;
    Color bevelColor;
    Color borderColor;
    Color iconColor;

    if (level.isCompleted) {
      faceColor = specialTint ?? primary;
      bevelColor = Color.alphaBlend(
        Colors.black.withValues(alpha: isDark ? 0.45 : 0.35),
        faceColor,
      );
      borderColor = AppColors.antiqueGold;
      iconColor = Colors.white;
    } else if (isOfflineQuizLocked) {
      faceColor = isDark ? const Color(0xFF2A231C) : const Color(0xFFE5DDD3);
      bevelColor = isDark ? const Color(0xFF1E1812) : const Color(0xFFC3B6AA);
      borderColor = AppColors.streakOrange.withValues(alpha: 0.85);
      iconColor = AppColors.streakOrange;
    } else if (widget.isCurrent) {
      faceColor = specialTint ?? AppColors.antiqueGold;
      bevelColor = specialTint != null
          ? Color.alphaBlend(Colors.black.withValues(alpha: 0.38), specialTint)
          : const Color(0xFF8E660E);
      borderColor = specialTint != null ? AppColors.antiqueGold : primary;
      iconColor = specialTint != null
          ? Colors.white
          : (isDark ? const Color(0xFF121212) : AppColors.inkDark);
    } else if (specialTint != null) {
      // Locked special nodes display a subtle tinted silhouette so players can anticipate upcoming encounters!
      faceColor = isDark
          ? Color.alphaBlend(specialTint.withValues(alpha: 0.22), const Color(0xFF23232A))
          : Color.alphaBlend(specialTint.withValues(alpha: 0.16), const Color(0xFFDFD6C9));
      bevelColor = isDark
          ? Color.alphaBlend(specialTint.withValues(alpha: 0.14), const Color(0xFF17171D))
          : Color.alphaBlend(specialTint.withValues(alpha: 0.22), const Color(0xFFB5A998));
      borderColor = specialTint.withValues(alpha: isDark ? 0.55 : 0.6);
      iconColor = specialTint.withValues(alpha: isDark ? 0.85 : 0.78);
    } else {
      faceColor = isDark ? const Color(0xFF282828) : const Color(0xFFD7CDBF);
      bevelColor = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFB5A998);
      borderColor = isDark ? const Color(0xFF383838) : const Color(0xFFC5B9A6);
      iconColor = isDark ? const Color(0xFF666666) : const Color(0xFF8A7F70);
    }

    // Steady shadow depth
    const shadowOffsetY = bevelDepth + 2.0;
    const shadowBlur = 6.0;

    return RepaintBoundary(
      child: SizedBox(
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
    ),
    );
  }

  Color? _specialNodeAccent(LevelType type) {
    switch (type) {
      case LevelType.treasureChest:
        return const Color(0xFFD4A338);
      case LevelType.lightningDuel:
        return const Color(0xFF0EA5E9);
      case LevelType.campfireParley:
        return const Color(0xFFEA580C);
      case LevelType.quoteShrine:
        return const Color(0xFF8B5CF6);
      case LevelType.wordMatchBlitz:
        return const Color(0xFF0D9488);
      case LevelType.zoneGatekeeper:
        return const Color(0xFFE11D48);
      default:
        return null;
    }
  }

  IconData _getNodeIcon(LevelType type, bool isCompleted, bool isLocked, bool isOfflineQuizLocked) {
    if (isOfflineQuizLocked) {
      return Icons.wifi_off_rounded;
    }
    // Special nodes show their signature emblem even when upcoming on the map!
    switch (type) {
      case LevelType.treasureChest:
        return Icons.inventory_2_rounded;
      case LevelType.lightningDuel:
        return Icons.bolt_rounded;
      case LevelType.campfireParley:
        return Icons.local_fire_department_rounded;
      case LevelType.quoteShrine:
        return Icons.format_quote_rounded;
      case LevelType.wordMatchBlitz:
        return Icons.extension_rounded;
      case LevelType.zoneGatekeeper:
        return Icons.fort_rounded;
      default:
        break;
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
      default:
        return Icons.auto_stories_rounded;
    }
  }
}

enum _ThemeBiome {
  classicMedieval, // theme_classic: Crisp white-cream medieval countryside
  savannahMesa, // theme_the_la_mancha: White-cream sunlit savannah & terracotta mesas
  ironFortress, // theme_medieval: Weathered stone citadel & crimson heraldry
  gothicMidnight, // theme_plague: Moonlit obsidian forest & ruined spires
  autumnForest, // theme_cozy: Warm amber autumn woodland & cozy hearth
  winterFrost, // theme_snowy: Nordic snow biome, aurora & glacial peaks
  pinkBlossom, // theme_cute_meadow: Pink sakura garden, rose arches & fairytale gazebo
}

/// Theme-Aware Illustrated Adventure Map Painter.
/// Every single theme renders its own completely unique biome, palette, flora,
/// architecture, and animated atmospheric motifs — never repeating generic houses
/// across different themes.
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

  _ThemeBiome get _biome {
    switch (preset.id) {
      case 'theme_the_la_mancha':
        return _ThemeBiome.savannahMesa;
      case 'theme_medieval':
        return _ThemeBiome.ironFortress;
      case 'theme_plague':
        return _ThemeBiome.gothicMidnight;
      case 'theme_cozy':
        return _ThemeBiome.autumnForest;
      case 'theme_snowy':
        return _ThemeBiome.winterFrost;
      case 'theme_cute_meadow':
        return _ThemeBiome.pinkBlossom;
      case 'theme_classic':
      default:
        return _ThemeBiome.classicMedieval;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final biome = _biome;

    // 1. Biome Terrain, Hills, Contours & Neatline
    _drawTerrainAndContours(canvas, size, biome);

    // 2. Day / Night Sky Atmosphere (Sunbeam & Clouds in Light Mode; Stars, Moon & Fireflies in Dark Mode)
    _drawDayNightAtmosphere(canvas, size, biome);

    // 3. Completely Distinct Theme-Specific Biome Landmarks (Zero Repeated Motifs)
    switch (biome) {
      case _ThemeBiome.classicMedieval:
        _drawClassicMedievalBiome(canvas, size);
        break;
      case _ThemeBiome.savannahMesa:
        _drawSavannahMesaBiome(canvas, size);
        break;
      case _ThemeBiome.ironFortress:
        _drawIronFortressBiome(canvas, size);
        break;
      case _ThemeBiome.gothicMidnight:
        _drawGothicMidnightBiome(canvas, size);
        break;
      case _ThemeBiome.autumnForest:
        _drawAutumnForestBiome(canvas, size);
        break;
      case _ThemeBiome.winterFrost:
        _drawWinterFrostBiome(canvas, size);
        break;
      case _ThemeBiome.pinkBlossom:
        _drawPinkBlossomBiome(canvas, size);
        break;
    }

    // 4. Broken / Dashed Quest Trail connecting nodes
    _drawBrokenDashedTrail(canvas, size, biome);
  }

  void _drawDayNightAtmosphere(Canvas canvas, Size size, _ThemeBiome biome) {
    if (isDark || biome == _ThemeBiome.gothicMidnight) {
      // Twinkling starfield across the night sky
      for (int i = 0; i < 16; i++) {
        final sx = size.width * (0.07 + ((i * 59 + 13) % 86) / 100.0);
        final sy = size.height * (0.04 + ((i * 37 + 7) % 88) / 100.0);
        final twinkle = 0.28 + 0.52 * (0.5 + 0.5 * sin(animValue * 2 * pi + i * 1.1));
        canvas.drawCircle(
          Offset(sx, sy),
          (i % 3 == 0) ? 1.6 : 1.0,
          Paint()..color = const Color(0xFFFFF8E1).withValues(alpha: twinkle),
        );
      }

      // Glowing crescent moon in top-left sky for nighttime mode (except gothic which draws its own)
      if (biome != _ThemeBiome.gothicMidnight && zoneType == _ZoneType.windmills) {
        final moonPos = Offset(44, 42);
        canvas.drawCircle(
          moonPos,
          17,
          Paint()..color = const Color(0xFFE5B842).withValues(alpha: 0.14),
        );
        canvas.drawCircle(moonPos, 9.5, Paint()..color = const Color(0xFFF6E6B8));
        canvas.drawCircle(
          Offset(moonPos.dx + 4, moonPos.dy - 2),
          8.5,
          Paint()..color = _nightSkyTopColor(biome),
        );
      }

      // Warm drifting nighttime fireflies
      if (biome != _ThemeBiome.gothicMidnight) {
        final fireflyColor = biome == _ThemeBiome.pinkBlossom
            ? const Color(0xFFFF9EBB)
            : biome == _ThemeBiome.winterFrost
                ? const Color(0xFF7FDBFF)
                : const Color(0xFFF5D061);
        _drawDriftingParticles(
          canvas,
          size,
          color: fireflyColor,
          count: 8,
          isSnow: false,
          isPetal: false,
        );
      }
    } else {
      // Daytime Atmosphere: soft sunlit top-right radiance + gently drifting clouds
      final sunGlowPos = Offset(size.width * 0.86, 36);
      final sunGlowColor = biome == _ThemeBiome.pinkBlossom
          ? const Color(0xFFFFC1D6)
          : biome == _ThemeBiome.winterFrost
              ? const Color(0xFFFFFFFF)
              : const Color(0xFFFFE082);
      canvas.drawCircle(
        sunGlowPos,
        58,
        Paint()
          ..shader = RadialGradient(
            colors: [
              sunGlowColor.withValues(alpha: 0.22),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: sunGlowPos, radius: 58)),
      );

      // Gentle drifting daytime clouds
      final cloudColor = Colors.white.withValues(alpha: 0.45);
      final cloudShift = (animValue * 34) - 17;
      for (final c in [
        Offset(size.width * 0.24 + cloudShift, 34),
        Offset(size.width * 0.72 - cloudShift * 0.7, 58),
      ]) {
        final cp = Paint()..color = cloudColor;
        canvas.drawOval(Rect.fromCenter(center: c, width: 38, height: 12), cp);
        canvas.drawCircle(Offset(c.dx - 8, c.dy - 3), 7, cp);
        canvas.drawCircle(Offset(c.dx + 6, c.dy - 2), 6, cp);
      }
    }
  }

  Color _nightSkyTopColor(_ThemeBiome biome) {
    switch (biome) {
      case _ThemeBiome.classicMedieval:
        return const Color(0xFF111520);
      case _ThemeBiome.savannahMesa:
        return const Color(0xFF1A1210);
      case _ThemeBiome.ironFortress:
        return const Color(0xFF171012);
      case _ThemeBiome.gothicMidnight:
        return const Color(0xFF110F18);
      case _ThemeBiome.autumnForest:
        return const Color(0xFF18120E);
      case _ThemeBiome.winterFrost:
        return const Color(0xFF0C1824);
      case _ThemeBiome.pinkBlossom:
        return const Color(0xFF1C1018);
    }
  }

  void _drawTerrainAndContours(Canvas canvas, Size size, _ThemeBiome biome) {
    List<Color> bgColors;
    Color hill1;
    Color hill2;
    Color contour;
    Color neatline;

    if (isDark && biome != _ThemeBiome.gothicMidnight) {
      switch (biome) {
        case _ThemeBiome.classicMedieval:
          bgColors = const [Color(0xFF111520), Color(0xFF151B29), Color(0xFF1A2233)];
          hill1 = const Color(0xFF1F293D);
          hill2 = const Color(0xFF182030);
          contour = const Color(0xFF2D3B55);
          neatline = const Color(0xFF3A4966);
          break;
        case _ThemeBiome.savannahMesa:
          bgColors = const [Color(0xFF1A1210), Color(0xFF221714), Color(0xFF2A1C17)];
          hill1 = const Color(0xFF33221C);
          hill2 = const Color(0xFF291B16);
          contour = const Color(0xFF4D3228);
          neatline = const Color(0xFF5C3C30);
          break;
        case _ThemeBiome.ironFortress:
          bgColors = const [Color(0xFF171012), Color(0xFF1E1417), Color(0xFF26191D)];
          hill1 = const Color(0xFF2E1E23);
          hill2 = const Color(0xFF24171B);
          contour = const Color(0xFF4A2E37);
          neatline = const Color(0xFF593842);
          break;
        case _ThemeBiome.autumnForest:
          bgColors = const [Color(0xFF18120E), Color(0xFF211812), Color(0xFF291E16)];
          hill1 = const Color(0xFF32251B);
          hill2 = const Color(0xFF281D15);
          contour = const Color(0xFF4A3626);
          neatline = const Color(0xFF5A422F);
          break;
        case _ThemeBiome.winterFrost:
          bgColors = const [Color(0xFF0C1824), Color(0xFF102233), Color(0xFF142C42)];
          hill1 = const Color(0xFF1A3752);
          hill2 = const Color(0xFF142B40);
          contour = const Color(0xFF295278);
          neatline = const Color(0xFF34648F);
          break;
        case _ThemeBiome.pinkBlossom:
          bgColors = const [Color(0xFF1C1018), Color(0xFF251520), Color(0xFF2E1A28)];
          hill1 = const Color(0xFF382030);
          hill2 = const Color(0xFF2C1826);
          contour = const Color(0xFF57314A);
          neatline = const Color(0xFF6B3D5B);
          break;
        case _ThemeBiome.gothicMidnight:
          bgColors = const [Color(0xFF110F18), Color(0xFF171423), Color(0xFF1E192E)];
          hill1 = const Color(0xFF231D36);
          hill2 = const Color(0xFF1A1629);
          contour = const Color(0xFF392F57);
          neatline = const Color(0xFF473A6B);
          break;
      }
    } else {
      switch (biome) {
        case _ThemeBiome.classicMedieval:
          // Crisp White-Cream Medieval Parchment (yellow dramatically reduced)
          bgColors = const [Color(0xFFFAF8F4), Color(0xFFF5F1E9), Color(0xFFEEE8DD)];
          hill1 = const Color(0xFFE9E2D6);
          hill2 = const Color(0xFFE0D7C8);
          contour = const Color(0xFFD4C9B8);
          neatline = const Color(0xFFD8CEBF);
          break;
        case _ThemeBiome.savannahMesa:
          // Crisp White-Cream Sky & Warm Terracotta Savannah Horizon
          bgColors = const [Color(0xFFFAF8F3), Color(0xFFF5EFE5), Color(0xFFEDE2D3)];
          hill1 = const Color(0xFFE9D5C3);
          hill2 = const Color(0xFFE0C4AE);
          contour = const Color(0xFFD4A78C);
          neatline = const Color(0xFFD9B29A);
          break;
        case _ThemeBiome.ironFortress:
          // Weathered Stone Citadel & Crimson Heraldry
          bgColors = const [Color(0xFFFBF8F8), Color(0xFFF4ECEC), Color(0xFFEBE0E1)];
          hill1 = const Color(0xFFE6DADA);
          hill2 = const Color(0xFFDCCECE);
          contour = const Color(0xFFCBB4B7);
          neatline = const Color(0xFFD9BDC2);
          break;
        case _ThemeBiome.gothicMidnight:
          // Deep Crypt Obsidian & Apothecary Violet
          bgColors = const [Color(0xFF110F18), Color(0xFF171423), Color(0xFF1E192E)];
          hill1 = const Color(0xFF231D36);
          hill2 = const Color(0xFF1A1629);
          contour = const Color(0xFF392F57);
          neatline = const Color(0xFF473A6B);
          break;
        case _ThemeBiome.autumnForest:
          // Warm Fireside Cream & Russet Autumn Woodland
          bgColors = const [Color(0xFFFCF9F4), Color(0xFFF7EFE2), Color(0xFFEFE1CD)];
          hill1 = const Color(0xFFEBD8BF);
          hill2 = const Color(0xFFE2C9A8);
          contour = const Color(0xFFD4B28C);
          neatline = const Color(0xFFDCC09E);
          break;
        case _ThemeBiome.winterFrost:
          // Glacial Ice White-Blue Snow Biome
          bgColors = const [Color(0xFFF3F9FD), Color(0xFFE6F2FA), Color(0xFFD7E8F5)];
          hill1 = const Color(0xFFD2E6F4);
          hill2 = const Color(0xFFC2DDF0);
          contour = const Color(0xFFA2CBE4);
          neatline = const Color(0xFFBCE0F0);
          break;
        case _ThemeBiome.pinkBlossom:
          // Delicate Rose-Petal & Sakura Blossom Pink
          bgColors = const [Color(0xFFFFF5F8), Color(0xFFFDE8F0), Color(0xFFFAD8E5)];
          hill1 = const Color(0xFFF9D5E2);
          hill2 = const Color(0xFFF6C2D5);
          contour = const Color(0xFFEC9BB8);
          neatline = const Color(0xFFF3B2C8);
          break;
      }
    }

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: bgColors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Sweeping rolling horizon hills
    final hillPaint1 = Paint()
      ..color = hill1.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    final h1 = Path()
      ..moveTo(0, size.height * 0.34)
      ..cubicTo(size.width * 0.35, size.height * 0.27, size.width * 0.65, size.height * 0.41, size.width, size.height * 0.31)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(h1, hillPaint1);

    final hillPaint2 = Paint()
      ..color = hill2.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    final h2 = Path()
      ..moveTo(0, size.height * 0.72)
      ..cubicTo(size.width * 0.40, size.height * 0.78, size.width * 0.70, size.height * 0.66, size.width, size.height * 0.74)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(h2, hillPaint2);

    // Topographic elevation contour lines
    final contourPaint = Paint()
      ..color = contour.withValues(alpha: 0.48)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (final yRatio in [0.18, 0.52, 0.86]) {
      final c = Path()
        ..moveTo(0, size.height * yRatio)
        ..cubicTo(
          size.width * 0.3,
          size.height * (yRatio - 0.05),
          size.width * 0.7,
          size.height * (yRatio + 0.05),
          size.width,
          size.height * yRatio,
        );
      canvas.drawPath(c, contourPaint);
    }

    _drawCartographicNeatline(canvas, size, neatline);
  }

  void _drawCartographicNeatline(Canvas canvas, Size size, Color neatlineColor) {
    const margin = 10.0;
    final neatlinePaint = Paint()
      ..color = neatlineColor.withValues(alpha: 0.65)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTWH(margin, margin, size.width - margin * 2, size.height - margin * 2),
      neatlinePaint,
    );

    final diamondPaint = Paint()
      ..color = neatlineColor.withValues(alpha: 0.9)
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

  // ===========================================================================
  // BIOME 1: CLASSIC LA MANCHA — White-Cream Medieval Countryside
  // ===========================================================================
  void _drawClassicMedievalBiome(Canvas canvas, Size size) {
    if (zoneType == _ZoneType.windmills) {
      _drawCompassRose(canvas, Offset(size.width - 44, 44));
      _drawWindmill(canvas, Offset(52, size.height * 0.40), animValue);
      _drawCypressTree(canvas, Offset(size.width - 38, size.height * 0.28), 26);
      _drawCypressTree(canvas, Offset(size.width - 54, size.height * 0.34), 20);
      _drawStoneMilepost(canvas, Offset(size.width - 52, size.height * 0.72));
      _drawCypressTree(canvas, Offset(30, size.height * 0.80), 22);
      _drawBirds(canvas, Offset(size.width * 0.26, size.height * 0.14));
    } else if (zoneType == _ZoneType.riverAndCottage) {
      // Clear medieval brook with stone arched aqueduct bridge
      _drawStreamRibbon(canvas, size, const Color(0xFF5DADE2), 0.48);
      _drawStoneArchBridge(canvas, Offset(size.width * 0.50, size.height * 0.49));
      _drawMedievalHeraldicBanner(canvas, Offset(46, size.height * 0.28), const Color(0xFF1E382B));
      _drawCypressTree(canvas, Offset(size.width - 42, size.height * 0.24), 24);
      _drawCypressTree(canvas, Offset(32, size.height * 0.72), 24);
      _drawCypressTree(canvas, Offset(48, size.height * 0.78), 18);
      _drawStoneMilepost(canvas, Offset(size.width - 48, size.height * 0.76));
    } else {
      // Stone watchtower keep & rocky ridge
      _drawCastleKeep(canvas, Offset(size.width - 56, size.height * 0.36), const Color(0xFFC84B31));
      _drawMountainPeaks(canvas, Offset(42, size.height * 0.24), const Color(0xFFA69B8C), Colors.white);
      _drawMedievalHeraldicBanner(canvas, Offset(48, size.height * 0.68), const Color(0xFFD4A338));
      _drawCypressTree(canvas, Offset(size.width - 36, size.height * 0.72), 22);
    }
  }

  // ===========================================================================
  // BIOME 2: THE LA MANCHA — Crisp White-Cream Sunlit Savannah & Terracotta Mesa
  // ===========================================================================
  void _drawSavannahMesaBiome(Canvas canvas, Size size) {
    if (zoneType == _ZoneType.windmills) {
      _drawSavannahSun(canvas, Offset(size.width - 48, 46));
      _drawAcaciaTree(canvas, Offset(48, size.height * 0.38), 26);
      _drawTerracottaMesa(canvas, Offset(size.width - 56, size.height * 0.68), 34);
      _drawAcaciaTree(canvas, Offset(36, size.height * 0.80), 20);
      _drawSavannahGrassCluster(canvas, Offset(size.width - 38, size.height * 0.30));
      _drawSavannahGrassCluster(canvas, Offset(40, size.height * 0.60));
    } else if (zoneType == _ZoneType.riverAndCottage) {
      // Desert oasis watering hole with palms
      _drawOasisPool(canvas, Offset(size.width * 0.50, size.height * 0.50));
      _drawPalmTree(canvas, Offset(44, size.height * 0.32), 26);
      _drawPalmTree(canvas, Offset(size.width - 42, size.height * 0.26), 24);
      _drawAcaciaTree(canvas, Offset(size.width - 50, size.height * 0.74), 24);
      _drawSavannahGrassCluster(canvas, Offset(36, size.height * 0.76));
    } else {
      // Twin terracotta mesas & carved sun-stone obelisk
      _drawTerracottaMesa(canvas, Offset(52, size.height * 0.28), 38);
      _drawSunObelisk(canvas, Offset(size.width - 52, size.height * 0.40));
      _drawAcaciaTree(canvas, Offset(44, size.height * 0.74), 24);
      _drawTerracottaMesa(canvas, Offset(size.width - 48, size.height * 0.78), 28);
    }
  }

  // ===========================================================================
  // BIOME 3: MEDIEVAL CITADEL — Iron Fortress & Crimson Heraldry
  // ===========================================================================
  void _drawIronFortressBiome(Canvas canvas, Size size) {
    if (zoneType == _ZoneType.windmills) {
      _drawCastleKeep(canvas, Offset(50, size.height * 0.38), const Color(0xFF991B2D));
      _drawMedievalHeraldicBanner(canvas, Offset(size.width - 44, size.height * 0.26), const Color(0xFF991B2D));
      _drawTorchBrazier(canvas, Offset(size.width - 48, size.height * 0.68));
      _drawPineTree(canvas, Offset(32, size.height * 0.78), 20, const Color(0xFF5D2A33));
      _drawPineTree(canvas, Offset(48, size.height * 0.84), 16, const Color(0xFF7B3340));
    } else if (zoneType == _ZoneType.riverAndCottage) {
      // Stone moat & drawbridge
      _drawStreamRibbon(canvas, size, const Color(0xFF6E7F8D), 0.48);
      _drawStoneArchBridge(canvas, Offset(size.width * 0.50, size.height * 0.49));
      _drawTorchBrazier(canvas, Offset(46, size.height * 0.30));
      _drawTorchBrazier(canvas, Offset(size.width - 46, size.height * 0.72));
      _drawPineTree(canvas, Offset(size.width - 40, size.height * 0.26), 20, const Color(0xFF5D2A33));
      _drawHeraldicShield(canvas, Offset(46, size.height * 0.76));
    } else {
      _drawMountainPeaks(canvas, Offset(46, size.height * 0.24), const Color(0xFF7D6B6E), const Color(0xFFF3EBEB));
      _drawCastleKeep(canvas, Offset(size.width - 56, size.height * 0.36), const Color(0xFF991B2D));
      _drawHeraldicShield(canvas, Offset(48, size.height * 0.68));
      _drawTorchBrazier(canvas, Offset(size.width - 44, size.height * 0.74));
    }
  }

  // ===========================================================================
  // BIOME 4: BLACK PLAGUE GRIMOIRE — Gothic Midnight Forest & Moonlit Ruins
  // ===========================================================================
  void _drawGothicMidnightBiome(Canvas canvas, Size size) {
    // Animated drifting violet twilight fireflies across every zone
    _drawDriftingParticles(
      canvas,
      size,
      color: const Color(0xFFC77DFF),
      count: 10,
      isSnow: false,
      isPetal: false,
    );

    if (zoneType == _ZoneType.windmills) {
      _drawCrescentMoon(canvas, Offset(size.width - 48, 44));
      _drawGnarledDeadTree(canvas, Offset(48, size.height * 0.40), 28);
      _drawApothecaryLantern(canvas, Offset(size.width - 48, size.height * 0.68));
      _drawGnarledDeadTree(canvas, Offset(36, size.height * 0.80), 22);
      _drawBirds(canvas, Offset(size.width * 0.28, size.height * 0.16));
    } else if (zoneType == _ZoneType.riverAndCottage) {
      _drawStreamRibbon(canvas, size, const Color(0xFF4A356B), 0.48);
      _drawGothicSpireRuin(canvas, Offset(48, size.height * 0.30));
      _drawApothecaryLantern(canvas, Offset(size.width - 44, size.height * 0.28));
      _drawGnarledDeadTree(canvas, Offset(size.width - 46, size.height * 0.74), 26);
      _drawApothecaryLantern(canvas, Offset(42, size.height * 0.78));
    } else {
      _drawGothicSpireRuin(canvas, Offset(size.width - 52, size.height * 0.36));
      _drawMountainPeaks(canvas, Offset(44, size.height * 0.24), const Color(0xFF2D2542), const Color(0xFF6D5899));
      _drawGnarledDeadTree(canvas, Offset(46, size.height * 0.72), 26);
      _drawApothecaryLantern(canvas, Offset(size.width - 46, size.height * 0.76));
    }
  }

  // ===========================================================================
  // BIOME 5: COZY HEARTH & LIBRARY — Autumn Enchanted Forest
  // ===========================================================================
  void _drawAutumnForestBiome(Canvas canvas, Size size) {
    // Gently falling amber & cinnamon autumn leaves
    _drawDriftingParticles(
      canvas,
      size,
      color: const Color(0xFFD97236),
      count: 9,
      isSnow: false,
      isPetal: true,
    );

    if (zoneType == _ZoneType.windmills) {
      _drawAutumnMapleTree(canvas, Offset(48, size.height * 0.38), 22, const Color(0xFFC05822));
      _drawAutumnMapleTree(canvas, Offset(size.width - 44, size.height * 0.28), 20, const Color(0xFFE28442));
      _drawToadstoolCluster(canvas, Offset(size.width - 50, size.height * 0.70));
      _drawAutumnMapleTree(canvas, Offset(34, size.height * 0.78), 18, const Color(0xFF8B3A1A));
      _drawWoodlandLampPost(canvas, Offset(size.width - 40, size.height * 0.48));
    } else if (zoneType == _ZoneType.riverAndCottage) {
      _drawStreamRibbon(canvas, size, const Color(0xFF6CA6CD), 0.48);
      _drawTimberFootbridge(canvas, Offset(size.width * 0.50, size.height * 0.49));
      _drawToadstoolCluster(canvas, Offset(46, size.height * 0.30));
      _drawAutumnMapleTree(canvas, Offset(size.width - 44, size.height * 0.26), 22, const Color(0xFFC05822));
      _drawAutumnMapleTree(canvas, Offset(38, size.height * 0.74), 20, const Color(0xFFE28442));
      _drawWoodlandLampPost(canvas, Offset(size.width - 46, size.height * 0.74));
    } else {
      _drawCozyHearthCabin(canvas, Offset(size.width - 56, size.height * 0.38));
      _drawAutumnMapleTree(canvas, Offset(46, size.height * 0.26), 22, const Color(0xFF8B3A1A));
      _drawToadstoolCluster(canvas, Offset(48, size.height * 0.72));
      _drawWoodlandLampPost(canvas, Offset(size.width - 42, size.height * 0.74));
    }
  }

  // ===========================================================================
  // BIOME 6: ENCHANTED WINTER FROST — Nordic Snow Biome & Glacial Peaks
  // ===========================================================================
  void _drawWinterFrostBiome(Canvas canvas, Size size) {
    // Gently falling crystalline snowflakes
    _drawDriftingParticles(
      canvas,
      size,
      color: isDark ? Colors.white70 : const Color(0xFF6EAEDB),
      count: 14,
      isSnow: true,
      isPetal: false,
    );

    if (zoneType == _ZoneType.windmills) {
      _drawAuroraRibbon(canvas, size);
      _drawMountainPeaks(canvas, Offset(52, size.height * 0.36), const Color(0xFF5D93B8), Colors.white);
      _drawFrostedFirTree(canvas, Offset(size.width - 42, size.height * 0.28), 24);
      _drawIceCrystalCluster(canvas, Offset(size.width - 50, size.height * 0.70));
      _drawFrostedFirTree(canvas, Offset(34, size.height * 0.78), 22);
      _drawFrostedFirTree(canvas, Offset(52, size.height * 0.84), 17);
    } else if (zoneType == _ZoneType.riverAndCottage) {
      // Frozen glacier lake
      _drawFrozenLake(canvas, Offset(size.width * 0.50, size.height * 0.50));
      _drawFrostedFirTree(canvas, Offset(44, size.height * 0.30), 24);
      _drawIceCrystalCluster(canvas, Offset(size.width - 46, size.height * 0.28));
      _drawFrostedFirTree(canvas, Offset(size.width - 44, size.height * 0.74), 22);
      _drawIceCrystalCluster(canvas, Offset(42, size.height * 0.78));
    } else {
      _drawIceSpireArch(canvas, Offset(size.width - 54, size.height * 0.38));
      _drawMountainPeaks(canvas, Offset(46, size.height * 0.24), const Color(0xFF3E78A1), Colors.white);
      _drawFrostedFirTree(canvas, Offset(44, size.height * 0.70), 24);
      _drawIceCrystalCluster(canvas, Offset(size.width - 46, size.height * 0.76));
    }
  }

  // ===========================================================================
  // BIOME 7: FAIRYTALE ROSE BLOSSOM — Pink Sakura & Rose Garden Realm
  // ===========================================================================
  void _drawPinkBlossomBiome(Canvas canvas, Size size) {
    // Animated drifting pink sakura petals
    _drawDriftingParticles(
      canvas,
      size,
      color: const Color(0xFFE91E63),
      count: 12,
      isSnow: false,
      isPetal: true,
    );

    if (zoneType == _ZoneType.windmills) {
      _drawSakuraTree(canvas, Offset(50, size.height * 0.38), 24);
      _drawRoseGardenArch(canvas, Offset(size.width - 52, size.height * 0.68));
      _drawSakuraTree(canvas, Offset(size.width - 40, size.height * 0.26), 19);
      _drawFairyLantern(canvas, Offset(38, size.height * 0.78));
      _drawBlossomSparkles(canvas, Offset(size.width - 44, 44));
    } else if (zoneType == _ZoneType.riverAndCottage) {
      // Blushing rose-lily pond & pink garden bridge
      _drawPinkLilyPond(canvas, Offset(size.width * 0.50, size.height * 0.50));
      _drawSakuraTree(canvas, Offset(44, size.height * 0.30), 22);
      _drawFairyLantern(canvas, Offset(size.width - 44, size.height * 0.26));
      _drawRoseBush(canvas, Offset(38, size.height * 0.76));
      _drawSakuraTree(canvas, Offset(size.width - 48, size.height * 0.74), 20);
    } else {
      // Ornate pink fairytale pavilion / gazebo
      _drawPinkFairytaleGazebo(canvas, Offset(size.width - 56, size.height * 0.38));
      _drawRoseGardenArch(canvas, Offset(48, size.height * 0.28));
      _drawSakuraTree(canvas, Offset(46, size.height * 0.72), 22);
      _drawFairyLantern(canvas, Offset(size.width - 44, size.height * 0.76));
    }
  }

  // ===========================================================================
  // TRAIL RENDERER (THEME-MATCHED)
  // ===========================================================================
  void _drawBrokenDashedTrail(Canvas canvas, Size size, _ThemeBiome biome) {
    if (points.length < 2) return;

    final fullPath = Path();
    fullPath.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midY = (p0.dy + p1.dy) / 2;
      fullPath.cubicTo(p0.dx, midY, p1.dx, midY, p1.dx, p1.dy);
    }

    Color trailBed;
    Color dashColor;
    if (isDark && biome != _ThemeBiome.gothicMidnight) {
      trailBed = const Color(0xFF181818);
      dashColor = const Color(0xFFE5B842);
    } else {
      switch (biome) {
        case _ThemeBiome.classicMedieval:
          trailBed = const Color(0xFFE7E0D3);
          dashColor = const Color(0xFF7B6348);
          break;
        case _ThemeBiome.savannahMesa:
          trailBed = const Color(0xFFEBD9C7);
          dashColor = const Color(0xFFD95B30);
          break;
        case _ThemeBiome.ironFortress:
          trailBed = const Color(0xFFEADCDD);
          dashColor = const Color(0xFF991B2D);
          break;
        case _ThemeBiome.gothicMidnight:
          trailBed = const Color(0xFF231D36);
          dashColor = const Color(0xFFC77DFF);
          break;
        case _ThemeBiome.autumnForest:
          trailBed = const Color(0xFFEBDAC5);
          dashColor = const Color(0xFF8B3A1A);
          break;
        case _ThemeBiome.winterFrost:
          trailBed = const Color(0xFFD9EAF6);
          dashColor = const Color(0xFF1B4965);
          break;
        case _ThemeBiome.pinkBlossom:
          trailBed = const Color(0xFFFCDCE7);
          dashColor = const Color(0xFFC24168);
          break;
      }
    }

    final trailBedPaint = Paint()
      ..color = trailBed
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(fullPath, trailBedPaint);

    final dashPaint = Paint()
      ..color = dashColor.withValues(alpha: 0.85)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final metric in fullPath.computeMetrics()) {
      double distance = 0.0;
      const double dashLength = 8.0;
      const double gapLength = 6.0;
      while (distance < metric.length) {
        final extractLen = min(dashLength, metric.length - distance);
        canvas.drawPath(metric.extractPath(distance, distance + extractLen), dashPaint);
        distance += dashLength + gapLength;
      }
    }
  }

  // ===========================================================================
  // SHARED & BIOME-SPECIFIC ILLUSTRATED MOTIFS
  // ===========================================================================

  void _drawStreamRibbon(Canvas canvas, Size size, Color color, double yRatio) {
    final riverPaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.35 : 0.42)
      ..strokeWidth = 22
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final p = Path()
      ..moveTo(0, size.height * yRatio)
      ..cubicTo(
        size.width * 0.35,
        size.height * (yRatio - 0.08),
        size.width * 0.65,
        size.height * (yRatio + 0.08),
        size.width,
        size.height * (yRatio + 0.02),
      );
    canvas.drawPath(p, riverPaint);
  }

  void _drawStoneArchBridge(Canvas canvas, Offset pos) {
    final stonePaint = Paint()..color = isDark ? const Color(0xFF3E3E44) : const Color(0xFF9E968B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: pos, width: 34, height: 14), const Radius.circular(4)),
      stonePaint,
    );
    final parapet = Paint()
      ..color = isDark ? const Color(0xFF55555E) : const Color(0xFF7B7368)
      ..strokeWidth = 2.4;
    canvas.drawLine(Offset(pos.dx - 17, pos.dy - 7), Offset(pos.dx + 17, pos.dy - 7), parapet);
    canvas.drawLine(Offset(pos.dx - 17, pos.dy + 7), Offset(pos.dx + 17, pos.dy + 7), parapet);
  }

  void _drawTimberFootbridge(Canvas canvas, Offset pos) {
    final woodPaint = Paint()
      ..color = const Color(0xFF8D5B3A)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    for (int i = -3; i <= 3; i++) {
      canvas.drawLine(Offset(pos.dx + i * 5, pos.dy - 13), Offset(pos.dx + i * 5, pos.dy + 13), woodPaint);
    }
  }

  void _drawBirds(Canvas canvas, Offset pos) {
    final birdPaint = Paint()
      ..color = (isDark ? const Color(0xFF7A738C) : const Color(0xFF8C7D68)).withValues(alpha: 0.65)
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

  void _drawDriftingParticles(
    Canvas canvas,
    Size size, {
    required Color color,
    required int count,
    required bool isSnow,
    required bool isPetal,
  }) {
    final paint = Paint()..color = color.withValues(alpha: isSnow ? 0.65 : 0.45);
    for (int i = 0; i < count; i++) {
      final seedX = ((i * 73 + 19) % 90) / 100.0;
      final seedY = ((i * 41 + 11) % 100) / 100.0;
      final dx = size.width * (0.06 + seedX * 0.88) + sin(animValue * 2 * pi + i) * 7;
      final dy = (size.height * ((seedY + animValue * 0.5) % 1.0));
      if (isPetal) {
        canvas.save();
        canvas.translate(dx, dy);
        canvas.rotate(animValue * 2 * pi + i);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 6.5, height: 3.5), paint);
        canvas.restore();
      } else {
        canvas.drawCircle(Offset(dx, dy), isSnow ? 2.4 : 2.0, paint);
      }
    }
  }

  // --- Classic Medieval Motifs ---
  void _drawWindmill(Canvas canvas, Offset pos, double rotProgress) {
    final bodyPaint = Paint()..color = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFD9D1C5);
    final roofPaint = Paint()..color = const Color(0xFF8B2635);
    final sailPaint = Paint()
      ..color = isDark ? const Color(0xFFD4A338) : const Color(0xFF5D4037)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final towerPath = Path()
      ..moveTo(pos.dx - 14, pos.dy + 18)
      ..lineTo(pos.dx - 9, pos.dy - 12)
      ..lineTo(pos.dx + 9, pos.dy - 12)
      ..lineTo(pos.dx + 14, pos.dy + 18)
      ..close();
    canvas.drawPath(towerPath, bodyPaint);

    final roofPath = Path()
      ..moveTo(pos.dx - 12, pos.dy - 12)
      ..lineTo(pos.dx, pos.dy - 24)
      ..lineTo(pos.dx + 12, pos.dy - 12)
      ..close();
    canvas.drawPath(roofPath, roofPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(pos.dx, pos.dy + 12), width: 6, height: 10),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF3E2723),
    );

    canvas.save();
    canvas.translate(pos.dx, pos.dy - 12);
    canvas.rotate(rotProgress * 2 * pi);
    for (int i = 0; i < 4; i++) {
      canvas.save();
      canvas.rotate(i * pi / 2);
      canvas.drawLine(Offset.zero, const Offset(0, -25), sailPaint);
      canvas.drawRect(
        const Rect.fromLTWH(2, -23, 6, 17),
        Paint()..color = (isDark ? const Color(0xFFF0EBE1) : const Color(0xFFFFFFFF)).withValues(alpha: 0.8),
      );
      canvas.restore();
    }
    canvas.restore();
  }

  void _drawCypressTree(Canvas canvas, Offset pos, double height) {
    final trunk = Paint()
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 2.6;
    canvas.drawLine(Offset(pos.dx, pos.dy + 4), Offset(pos.dx, pos.dy + 12), trunk);
    final leaf = Paint()..color = (isDark ? const Color(0xFF284234) : const Color(0xFF3E6B4F)).withValues(alpha: 0.88);
    canvas.drawOval(Rect.fromCenter(center: Offset(pos.dx, pos.dy - height * 0.25), width: height * 0.46, height: height), leaf);
  }

  void _drawStoneMilepost(Canvas canvas, Offset pos) {
    final stone = Paint()..color = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFBFB5A4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: pos, width: 12, height: 18), const Radius.circular(5)),
      stone,
    );
    canvas.drawLine(
      Offset(pos.dx - 3, pos.dy - 2),
      Offset(pos.dx + 3, pos.dy - 2),
      Paint()
        ..color = AppColors.antiqueGold
        ..strokeWidth = 1.6,
    );
  }

  void _drawMedievalHeraldicBanner(Canvas canvas, Offset pos, Color bannerColor) {
    final pole = Paint()
      ..color = isDark ? Colors.white54 : const Color(0xFF5D4037)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(pos.dx, pos.dy + 16), Offset(pos.dx, pos.dy - 20), pole);
    final wave = sin(animValue * pi * 4) * 2.2;
    final flag = Path()
      ..moveTo(pos.dx, pos.dy - 19)
      ..lineTo(pos.dx + 18 + wave, pos.dy - 14)
      ..lineTo(pos.dx, pos.dy - 8)
      ..close();
    canvas.drawPath(flag, Paint()..color = bannerColor);
  }

  // --- Savannah & Terracotta Mesa Motifs ---
  void _drawSavannahSun(Canvas canvas, Offset pos) {
    final sunGlow = Paint()..color = const Color(0xFFD95B30).withValues(alpha: 0.14);
    canvas.drawCircle(pos, 22 + sin(animValue * 2 * pi) * 2, sunGlow);
    canvas.drawCircle(pos, 12, Paint()..color = const Color(0xFFE2725B).withValues(alpha: 0.78));
  }

  void _drawAcaciaTree(Canvas canvas, Offset pos, double width) {
    final trunk = Paint()
      ..color = const Color(0xFF5C3D2E)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(pos.dx, pos.dy + 14), Offset(pos.dx, pos.dy - 2), trunk);
    canvas.drawLine(Offset(pos.dx, pos.dy + 2), Offset(pos.dx - width * 0.3, pos.dy - 5), trunk);
    canvas.drawLine(Offset(pos.dx, pos.dy + 2), Offset(pos.dx + width * 0.3, pos.dy - 5), trunk);
    final canopy = Paint()..color = const Color(0xFF8C7A3B).withValues(alpha: 0.85);
    canvas.drawOval(Rect.fromCenter(center: Offset(pos.dx, pos.dy - 7), width: width * 1.35, height: 10), canopy);
    canvas.drawOval(Rect.fromCenter(center: Offset(pos.dx - width * 0.32, pos.dy - 5), width: width * 0.65, height: 7), canopy);
  }

  void _drawTerracottaMesa(Canvas canvas, Offset pos, double width) {
    final mesa = Path()
      ..moveTo(pos.dx - width * 0.6, pos.dy + 12)
      ..lineTo(pos.dx - width * 0.38, pos.dy - 12)
      ..lineTo(pos.dx + width * 0.38, pos.dy - 12)
      ..lineTo(pos.dx + width * 0.6, pos.dy + 12)
      ..close();
    canvas.drawPath(mesa, Paint()..color = const Color(0xFFD96B43).withValues(alpha: 0.72));
    // Sandstone strata stripe
    canvas.drawLine(
      Offset(pos.dx - width * 0.44, pos.dy - 2),
      Offset(pos.dx + width * 0.44, pos.dy - 2),
      Paint()
        ..color = const Color(0xFFF3D7C4).withValues(alpha: 0.7)
        ..strokeWidth = 2.0,
    );
  }

  void _drawOasisPool(Canvas canvas, Offset pos) {
    canvas.drawOval(
      Rect.fromCenter(center: pos, width: 78, height: 28),
      Paint()..color = const Color(0xFF4FB3BF).withValues(alpha: 0.38),
    );
    canvas.drawOval(
      Rect.fromCenter(center: pos, width: 52, height: 14),
      Paint()..color = const Color(0xFF80DEEA).withValues(alpha: 0.32),
    );
  }

  void _drawPalmTree(Canvas canvas, Offset pos, double h) {
    final trunk = Paint()
      ..color = const Color(0xFF7B5439)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final curve = Path()
      ..moveTo(pos.dx - 3, pos.dy + h * 0.5)
      ..quadraticBezierTo(pos.dx + 4, pos.dy, pos.dx, pos.dy - h * 0.45);
    canvas.drawPath(curve, trunk);
    final frondPaint = Paint()
      ..color = const Color(0xFF6E8B3D).withValues(alpha: 0.85)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    final top = Offset(pos.dx, pos.dy - h * 0.45);
    for (final dx in [-14.0, -8.0, 8.0, 14.0]) {
      final f = Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(top.dx + dx * 0.6, top.dy - 7, top.dx + dx, top.dy + 3);
      canvas.drawPath(f, frondPaint);
    }
  }

  void _drawSavannahGrassCluster(Canvas canvas, Offset pos) {
    final p = Paint()
      ..color = const Color(0xFFC88A4B).withValues(alpha: 0.75)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pos, Offset(pos.dx - 4, pos.dy - 8), p);
    canvas.drawLine(pos, Offset(pos.dx, pos.dy - 10), p);
    canvas.drawLine(pos, Offset(pos.dx + 4, pos.dy - 7), p);
  }

  void _drawSunObelisk(Canvas canvas, Offset pos) {
    final p = Path()
      ..moveTo(pos.dx - 7, pos.dy + 16)
      ..lineTo(pos.dx - 4, pos.dy - 14)
      ..lineTo(pos.dx, pos.dy - 22)
      ..lineTo(pos.dx + 4, pos.dy - 14)
      ..lineTo(pos.dx + 7, pos.dy + 16)
      ..close();
    canvas.drawPath(p, Paint()..color = const Color(0xFFB85D3B).withValues(alpha: 0.85));
    canvas.drawCircle(Offset(pos.dx, pos.dy - 4), 2.5, Paint()..color = const Color(0xFFFAF8F3));
  }

  // --- Iron Fortress Motifs ---
  void _drawCastleKeep(Canvas canvas, Offset pos, Color flagColor) {
    final stonePaint = Paint()..color = isDark ? const Color(0xFF2C2C30) : const Color(0xFFA89F9A);
    canvas.drawRect(Rect.fromLTWH(pos.dx - 16, pos.dy - 10, 32, 24), stonePaint);
    canvas.drawRect(Rect.fromLTWH(pos.dx - 22, pos.dy - 22, 10, 36), stonePaint);
    canvas.drawRect(Rect.fromLTWH(pos.dx - 22, pos.dy - 26, 3, 4), stonePaint);
    canvas.drawRect(Rect.fromLTWH(pos.dx - 15, pos.dy - 26, 3, 4), stonePaint);
    canvas.drawRect(Rect.fromLTWH(pos.dx + 12, pos.dy - 22, 10, 36), stonePaint);
    canvas.drawRect(Rect.fromLTWH(pos.dx + 12, pos.dy - 26, 3, 4), stonePaint);
    canvas.drawRect(Rect.fromLTWH(pos.dx + 19, pos.dy - 26, 3, 4), stonePaint);

    canvas.drawLine(
      Offset(pos.dx + 17, pos.dy - 26),
      Offset(pos.dx + 17, pos.dy - 38),
      Paint()
        ..color = Colors.black54
        ..strokeWidth = 1.5,
    );
    final flag = Path()
      ..moveTo(pos.dx + 17, pos.dy - 38)
      ..lineTo(pos.dx + 28 + sin(animValue * pi * 4) * 2, pos.dy - 34)
      ..lineTo(pos.dx + 17, pos.dy - 30)
      ..close();
    canvas.drawPath(flag, Paint()..color = flagColor);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(pos.dx, pos.dy + 6), width: 10, height: 12),
        const Radius.circular(5),
      ),
      Paint()..color = isDark ? const Color(0xFF141414) : const Color(0xFF2B2421),
    );
  }

  void _drawTorchBrazier(Canvas canvas, Offset pos) {
    final iron = Paint()..color = const Color(0xFF423A3C);
    canvas.drawRect(Rect.fromCenter(center: Offset(pos.dx, pos.dy + 8), width: 6, height: 14), iron);
    final bowl = Path()
      ..moveTo(pos.dx - 9, pos.dy)
      ..lineTo(pos.dx + 9, pos.dy)
      ..lineTo(pos.dx + 5, pos.dy + 6)
      ..lineTo(pos.dx - 5, pos.dy + 6)
      ..close();
    canvas.drawPath(bowl, iron);
    final flicker = sin(animValue * pi * 8) * 1.5;
    canvas.drawCircle(Offset(pos.dx, pos.dy - 4 + flicker * 0.4), 5, Paint()..color = const Color(0xFFFF8F00).withValues(alpha: 0.85));
    canvas.drawCircle(Offset(pos.dx, pos.dy - 3), 2.5, Paint()..color = const Color(0xFFFFE082));
  }

  void _drawHeraldicShield(Canvas canvas, Offset pos) {
    final shield = Path()
      ..moveTo(pos.dx - 10, pos.dy - 10)
      ..lineTo(pos.dx + 10, pos.dy - 10)
      ..lineTo(pos.dx + 10, pos.dy + 2)
      ..quadraticBezierTo(pos.dx, pos.dy + 14, pos.dx - 10, pos.dy + 2)
      ..close();
    canvas.drawPath(shield, Paint()..color = const Color(0xFF991B2D));
    canvas.drawPath(
      shield,
      Paint()
        ..color = AppColors.antiqueGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.drawLine(
      Offset(pos.dx, pos.dy - 9),
      Offset(pos.dx, pos.dy + 8),
      Paint()
        ..color = AppColors.antiqueGold
        ..strokeWidth = 1.6,
    );
  }

  void _drawPineTree(Canvas canvas, Offset pos, double h, Color color) {
    canvas.drawRect(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy + h * 0.4), width: 3.5, height: 8),
      Paint()..color = const Color(0xFF4A342E),
    );
    final p = Paint()..color = color.withValues(alpha: 0.85);
    for (int layer = 0; layer < 2; layer++) {
      final yTop = pos.dy - h * 0.55 + layer * 7;
      final w = 9.0 + layer * 4;
      final tri = Path()
        ..moveTo(pos.dx, yTop)
        ..lineTo(pos.dx - w, yTop + 12)
        ..lineTo(pos.dx + w, yTop + 12)
        ..close();
      canvas.drawPath(tri, p);
    }
  }

  // --- Gothic Midnight Motifs ---
  void _drawCrescentMoon(Canvas canvas, Offset pos) {
    canvas.drawCircle(pos, 15, Paint()..color = const Color(0xFFC77DFF).withValues(alpha: 0.15));
    canvas.drawCircle(pos, 10, Paint()..color = const Color(0xFFE9E2F8));
    canvas.drawCircle(Offset(pos.dx + 4, pos.dy - 2), 9, Paint()..color = const Color(0xFF110F18));
  }

  void _drawGnarledDeadTree(Canvas canvas, Offset pos, double h) {
    final p = Paint()
      ..color = const Color(0xFF473A6B)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(pos.dx, pos.dy + h * 0.45), Offset(pos.dx, pos.dy - h * 0.25), p);
    canvas.drawLine(Offset(pos.dx, pos.dy - 2), Offset(pos.dx - 11, pos.dy - 12), p);
    canvas.drawLine(Offset(pos.dx - 6, pos.dy - 7), Offset(pos.dx - 14, pos.dy - 5), p);
    canvas.drawLine(Offset(pos.dx, pos.dy - 4), Offset(pos.dx + 10, pos.dy - 14), p);
    canvas.drawLine(Offset(pos.dx + 5, pos.dy - 9), Offset(pos.dx + 13, pos.dy - 8), p);
  }

  void _drawApothecaryLantern(Canvas canvas, Offset pos) {
    final post = Paint()
      ..color = const Color(0xFF5D537A)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(pos.dx, pos.dy + 16), Offset(pos.dx, pos.dy - 10), post);
    canvas.drawLine(Offset(pos.dx, pos.dy - 10), Offset(pos.dx + 8, pos.dy - 10), post);
    canvas.drawCircle(Offset(pos.dx + 8, pos.dy - 6), 9, Paint()..color = const Color(0xFFC77DFF).withValues(alpha: 0.22));
    canvas.drawCircle(Offset(pos.dx + 8, pos.dy - 6), 3.5, Paint()..color = const Color(0xFFE0AAFF));
  }

  void _drawGothicSpireRuin(Canvas canvas, Offset pos) {
    final stone = Paint()..color = const Color(0xFF352C52);
    final spire = Path()
      ..moveTo(pos.dx - 14, pos.dy + 16)
      ..lineTo(pos.dx - 14, pos.dy - 8)
      ..lineTo(pos.dx - 8, pos.dy - 26)
      ..lineTo(pos.dx - 2, pos.dy - 8)
      ..lineTo(pos.dx + 4, pos.dy - 18)
      ..lineTo(pos.dx + 14, pos.dy - 4)
      ..lineTo(pos.dx + 14, pos.dy + 16)
      ..close();
    canvas.drawPath(spire, stone);
    // Glowing lancet window
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(pos.dx - 6, pos.dy + 2), width: 4, height: 10), const Radius.circular(2)),
      Paint()..color = const Color(0xFFC77DFF).withValues(alpha: 0.7),
    );
  }

  // --- Autumn Forest Motifs ---
  void _drawAutumnMapleTree(Canvas canvas, Offset pos, double r, Color leafColor) {
    canvas.drawLine(
      Offset(pos.dx, pos.dy + 4),
      Offset(pos.dx, pos.dy + r * 0.9),
      Paint()
        ..color = const Color(0xFF5D3A28)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
    final p = Paint()..color = leafColor.withValues(alpha: 0.85);
    canvas.drawCircle(pos, r * 0.68, p);
    canvas.drawCircle(Offset(pos.dx - r * 0.38, pos.dy + 2), r * 0.48, p);
    canvas.drawCircle(Offset(pos.dx + r * 0.38, pos.dy + 2), r * 0.48, p);
  }

  void _drawToadstoolCluster(Canvas canvas, Offset pos) {
    for (final offset in [Offset.zero, const Offset(10, 4)]) {
      final c = pos + offset;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(c.dx, c.dy + 5), width: 4, height: 8),
        Paint()..color = const Color(0xFFF5ECE0),
      );
      canvas.drawArc(
        Rect.fromCenter(center: Offset(c.dx, c.dy + 2), width: 14, height: 12),
        pi,
        pi,
        true,
        Paint()..color = const Color(0xFFC84B31),
      );
      canvas.drawCircle(Offset(c.dx - 2, c.dy - 1), 1.2, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(c.dx + 2.5, c.dy), 1.0, Paint()..color = Colors.white);
    }
  }

  void _drawWoodlandLampPost(Canvas canvas, Offset pos) {
    final wood = Paint()
      ..color = const Color(0xFF6B4226)
      ..strokeWidth = 2.2;
    canvas.drawLine(Offset(pos.dx, pos.dy + 14), Offset(pos.dx, pos.dy - 10), wood);
    canvas.drawCircle(Offset(pos.dx, pos.dy - 12), 8, Paint()..color = const Color(0xFFFFB74D).withValues(alpha: 0.25));
    canvas.drawCircle(Offset(pos.dx, pos.dy - 12), 3.5, Paint()..color = const Color(0xFFFFCC80));
  }

  void _drawCozyHearthCabin(Canvas canvas, Offset pos) {
    final brick = Paint()..color = const Color(0xFFA0522D);
    final timber = Paint()..color = const Color(0xFF6B3A1E);
    // Chimney + rising warm smoke
    canvas.drawRect(Rect.fromLTWH(pos.dx + 6, pos.dy - 18, 5, 11), brick);
    final smokeOffset = (animValue * 10) % 12;
    final smoke = Paint()..color = Colors.grey.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(pos.dx + 8, pos.dy - 22 - smokeOffset), 2.5, smoke);
    canvas.drawCircle(Offset(pos.dx + 10, pos.dy - 28 - smokeOffset), 3.5, smoke);
    // Cabin body & roof
    canvas.drawRect(Rect.fromLTWH(pos.dx - 14, pos.dy - 5, 28, 17), Paint()..color = const Color(0xFFE6C8A5));
    final roof = Path()
      ..moveTo(pos.dx - 18, pos.dy - 5)
      ..lineTo(pos.dx, pos.dy - 19)
      ..lineTo(pos.dx + 18, pos.dy - 5)
      ..close();
    canvas.drawPath(roof, timber);
    // Warm glowing hearth window
    canvas.drawRect(Rect.fromLTWH(pos.dx - 9, pos.dy, 6, 6), Paint()..color = const Color(0xFFFFB74D));
    canvas.drawRect(Rect.fromLTWH(pos.dx + 2, pos.dy + 1, 6, 11), timber);
  }

  // --- Winter Frost Motifs ---
  void _drawAuroraRibbon(Canvas canvas, Size size) {
    final aurora = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF00A8CC).withValues(alpha: 0.0),
          const Color(0xFF00A8CC).withValues(alpha: 0.18),
          const Color(0xFF5DADE2).withValues(alpha: 0.16),
          const Color(0xFF00A8CC).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 90))
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final wave = sin(animValue * 2 * pi) * 6;
    final path = Path()
      ..moveTo(16, 36 + wave)
      ..cubicTo(size.width * 0.35, 16 - wave, size.width * 0.65, 56 + wave, size.width - 16, 28 - wave);
    canvas.drawPath(path, aurora);
  }

  void _drawFrostedFirTree(Canvas canvas, Offset pos, double h) {
    canvas.drawRect(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy + h * 0.38), width: 3.5, height: 8),
      Paint()..color = const Color(0xFF5D6D7E),
    );
    final fir = Paint()..color = const Color(0xFF3E78A1).withValues(alpha: 0.85);
    final snow = Paint()..color = Colors.white.withValues(alpha: 0.9);
    for (int i = 0; i < 2; i++) {
      final topY = pos.dy - h * 0.5 + i * 8;
      final w = 9.0 + i * 4;
      final tri = Path()
        ..moveTo(pos.dx, topY)
        ..lineTo(pos.dx - w, topY + 12)
        ..lineTo(pos.dx + w, topY + 12)
        ..close();
      canvas.drawPath(tri, fir);
      final cap = Path()
        ..moveTo(pos.dx, topY)
        ..lineTo(pos.dx - w * 0.45, topY + 5)
        ..lineTo(pos.dx + w * 0.45, topY + 5)
        ..close();
      canvas.drawPath(cap, snow);
    }
  }

  void _drawIceCrystalCluster(Canvas canvas, Offset pos) {
    final crystal = Paint()..color = const Color(0xFF00A8CC).withValues(alpha: 0.65);
    final shine = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (final cfg in [
      (0.0, -14.0, 5.0),
      (-8.0, -9.0, 4.0),
      (8.0, -10.0, 4.0),
    ]) {
      final p = Path()
        ..moveTo(pos.dx + cfg.$1, pos.dy + cfg.$2)
        ..lineTo(pos.dx + cfg.$1 - cfg.$3, pos.dy + 6)
        ..lineTo(pos.dx + cfg.$1 + cfg.$3, pos.dy + 6)
        ..close();
      canvas.drawPath(p, crystal);
    }
    canvas.drawCircle(Offset(pos.dx, pos.dy - 6), 2.0, shine);
  }

  void _drawFrozenLake(Canvas canvas, Offset pos) {
    canvas.drawOval(
      Rect.fromCenter(center: pos, width: 88, height: 30),
      Paint()..color = const Color(0xFF8CC6E8).withValues(alpha: 0.45),
    );
    final glint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(pos.dx - 16, pos.dy - 3), Offset(pos.dx - 2, pos.dy - 6), glint);
    canvas.drawLine(Offset(pos.dx + 4, pos.dy + 4), Offset(pos.dx + 18, pos.dy + 1), glint);
  }

  void _drawIceSpireArch(Canvas canvas, Offset pos) {
    final ice = Paint()..color = const Color(0xFF5FA8D3).withValues(alpha: 0.78);
    final left = Path()
      ..moveTo(pos.dx - 16, pos.dy + 16)
      ..lineTo(pos.dx - 12, pos.dy - 20)
      ..lineTo(pos.dx - 5, pos.dy + 16)
      ..close();
    final right = Path()
      ..moveTo(pos.dx + 5, pos.dy + 16)
      ..lineTo(pos.dx + 12, pos.dy - 20)
      ..lineTo(pos.dx + 16, pos.dy + 16)
      ..close();
    canvas.drawPath(left, ice);
    canvas.drawPath(right, ice);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy - 4), width: 22, height: 18),
      pi,
      pi,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke,
    );
  }

  // --- Pink Blossom / Sakura Realm Motifs ---
  void _drawSakuraTree(Canvas canvas, Offset pos, double r) {
    canvas.drawLine(
      Offset(pos.dx, pos.dy + 3),
      Offset(pos.dx, pos.dy + r * 0.85),
      Paint()
        ..color = const Color(0xFF7A4553)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );
    final deepPink = Paint()..color = const Color(0xFFD85A82).withValues(alpha: 0.78);
    final softPink = Paint()..color = const Color(0xFFF8BBD0).withValues(alpha: 0.92);
    canvas.drawCircle(pos, r * 0.65, deepPink);
    canvas.drawCircle(Offset(pos.dx - r * 0.35, pos.dy - 2), r * 0.45, softPink);
    canvas.drawCircle(Offset(pos.dx + r * 0.35, pos.dy + 1), r * 0.42, softPink);
    canvas.drawCircle(Offset(pos.dx, pos.dy - r * 0.3), r * 0.34, softPink);
  }

  void _drawRoseGardenArch(Canvas canvas, Offset pos) {
    final archPaint = Paint()
      ..color = const Color(0xFFC24168)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(pos.dx - 13, pos.dy + 14), Offset(pos.dx - 13, pos.dy - 2), archPaint);
    canvas.drawLine(Offset(pos.dx + 13, pos.dy + 14), Offset(pos.dx + 13, pos.dy - 2), archPaint);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy - 2), width: 26, height: 22),
      pi,
      pi,
      false,
      archPaint,
    );
    // Blooming rosebuds along the arch
    final rose = Paint()..color = const Color(0xFFE91E63);
    for (final pt in [
      Offset(pos.dx - 12, pos.dy - 6),
      Offset(pos.dx, pos.dy - 13),
      Offset(pos.dx + 12, pos.dy - 6),
    ]) {
      canvas.drawCircle(pt, 3.2, rose);
    }
  }

  void _drawPinkLilyPond(Canvas canvas, Offset pos) {
    canvas.drawOval(
      Rect.fromCenter(center: pos, width: 84, height: 28),
      Paint()..color = const Color(0xFFF48FB1).withValues(alpha: 0.35),
    );
    // Curved blush footbridge
    canvas.drawArc(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy + 4), width: 38, height: 18),
      pi,
      pi,
      false,
      Paint()
        ..color = const Color(0xFFC24168)
        ..strokeWidth = 3.2
        ..style = PaintingStyle.stroke,
    );
    // Floating blossom lotus dots
    canvas.drawCircle(Offset(pos.dx - 24, pos.dy + 2), 3.0, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(pos.dx + 22, pos.dy - 3), 2.8, Paint()..color = const Color(0xFFE91E63));
  }

  void _drawRoseBush(Canvas canvas, Offset pos) {
    canvas.drawCircle(pos, 10, Paint()..color = const Color(0xFFF48FB1).withValues(alpha: 0.75));
    canvas.drawCircle(Offset(pos.dx + 8, pos.dy + 3), 8, Paint()..color = const Color(0xFFF8BBD0).withValues(alpha: 0.85));
    final bud = Paint()..color = const Color(0xFFC24168);
    canvas.drawCircle(Offset(pos.dx - 3, pos.dy - 2), 2.5, bud);
    canvas.drawCircle(Offset(pos.dx + 6, pos.dy + 1), 2.2, bud);
  }

  void _drawFairyLantern(Canvas canvas, Offset pos) {
    final stem = Paint()
      ..color = const Color(0xFFC24168)
      ..strokeWidth = 1.8;
    canvas.drawLine(Offset(pos.dx, pos.dy + 14), Offset(pos.dx, pos.dy - 10), stem);
    canvas.drawCircle(
      Offset(pos.dx, pos.dy - 12),
      9 + sin(animValue * 2 * pi) * 1.5,
      Paint()..color = const Color(0xFFE91E63).withValues(alpha: 0.18),
    );
    canvas.drawCircle(Offset(pos.dx, pos.dy - 12), 4.0, Paint()..color = const Color(0xFFFFD1E0));
  }

  void _drawPinkFairytaleGazebo(Canvas canvas, Offset pos) {
    final pillar = Paint()
      ..color = const Color(0xFFC24168)
      ..strokeWidth = 2.2;
    // Base deck
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(pos.dx, pos.dy + 12), width: 32, height: 6), const Radius.circular(3)),
      Paint()..color = const Color(0xFFF48FB1),
    );
    // Slender columns
    canvas.drawLine(Offset(pos.dx - 11, pos.dy + 9), Offset(pos.dx - 11, pos.dy - 6), pillar);
    canvas.drawLine(Offset(pos.dx + 11, pos.dy + 9), Offset(pos.dx + 11, pos.dy - 6), pillar);
    // Scalloped pink dome roof
    final dome = Path()
      ..moveTo(pos.dx - 17, pos.dy - 5)
      ..quadraticBezierTo(pos.dx, pos.dy - 25, pos.dx + 17, pos.dy - 5)
      ..close();
    canvas.drawPath(dome, Paint()..color = const Color(0xFFD85A82));
    // Finial star
    canvas.drawCircle(Offset(pos.dx, pos.dy - 18), 2.5, Paint()..color = const Color(0xFFFFF0F4));
  }

  void _drawBlossomSparkles(Canvas canvas, Offset pos) {
    final p = Paint()
      ..color = const Color(0xFFE91E63).withValues(alpha: 0.65)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(pos.dx, pos.dy - 7), Offset(pos.dx, pos.dy + 7), p);
    canvas.drawLine(Offset(pos.dx - 7, pos.dy), Offset(pos.dx + 7, pos.dy), p);
  }

  // --- Mountain Peaks & Compass Rose ---
  void _drawMountainPeaks(Canvas canvas, Offset pos, Color rockColor, Color capColor) {
    final mountainPaint = Paint()..color = rockColor.withValues(alpha: 0.85);
    final snowPaint = Paint()..color = capColor.withValues(alpha: 0.9);
    final m1 = Path()
      ..moveTo(pos.dx - 18, pos.dy + 14)
      ..lineTo(pos.dx, pos.dy - 16)
      ..lineTo(pos.dx + 18, pos.dy + 14)
      ..close();
    canvas.drawPath(m1, mountainPaint);
    final s1 = Path()
      ..moveTo(pos.dx - 6, pos.dy - 6)
      ..lineTo(pos.dx, pos.dy - 16)
      ..lineTo(pos.dx + 6, pos.dy - 6)
      ..close();
    canvas.drawPath(s1, snowPaint);
  }

  void _drawCompassRose(Canvas canvas, Offset pos) {
    final rosePaint = Paint()
      ..color = AppColors.antiqueGold.withValues(alpha: isDark ? 0.6 : 0.75)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(pos, 15, rosePaint);
    final north = Path()
      ..moveTo(pos.dx, pos.dy - 19)
      ..lineTo(pos.dx - 3, pos.dy)
      ..lineTo(pos.dx + 3, pos.dy)
      ..close();
    canvas.drawPath(north, Paint()..color = const Color(0xFFC0392B));
    final south = Path()
      ..moveTo(pos.dx, pos.dy + 19)
      ..lineTo(pos.dx - 3, pos.dy)
      ..lineTo(pos.dx + 3, pos.dy)
      ..close();
    canvas.drawPath(south, Paint()..color = isDark ? Colors.white60 : Colors.black54);
  }

  @override
  bool shouldRepaint(covariant _FantasyAdventureMapPainter oldDelegate) => true;
}
