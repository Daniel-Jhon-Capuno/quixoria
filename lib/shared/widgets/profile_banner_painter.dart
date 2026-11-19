import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Motion style for animated scenic profile backgrounds.
enum BannerMotion {
  none,
  fireflies,
  fallingPages,
  starrySky,
  driftingInk,
  candleDust,
  windowRain,
  aurora,
  sakuraDrift,
  emberHearth,
  goldenWindmills,
}

class ProfileBannerItem {
  final String id;
  final String name;
  final String description;
  final int gemPrice;
  final List<Color> skyColors;
  final Color accentColor;
  final IconData icon;
  final BannerMotion motion;

  bool get isAnimated => motion != BannerMotion.none;

  const ProfileBannerItem({
    required this.id,
    required this.name,
    this.description = 'Scenic illustrated profile backdrop.',
    required this.gemPrice,
    required this.skyColors,
    required this.accentColor,
    required this.icon,
    this.motion = BannerMotion.none,
  });
}

class ProfileBannerCatalog {
  static const List<ProfileBannerItem> banners = [
    // === STATIC SCENIC BACKGROUNDS ===
    ProfileBannerItem(
      id: 'banner_classic',
      name: 'Sunlit Hills',
      description: 'Warm rolling hills of La Mancha under a golden morning sun.',
      gemPrice: 0,
      skyColors: [Color(0xFF2F5E48), Color(0xFF4C8B68), Color(0xFFD4A338)],
      accentColor: Color(0xFFD4A338),
      icon: Icons.wb_sunny_rounded,
    ),
    ProfileBannerItem(
      id: 'banner_winter',
      name: 'Winter Peaks',
      description: 'Crisp snow-capped alpine peaks beneath glacial skies.',
      gemPrice: 120,
      skyColors: [Color(0xFF0E294B), Color(0xFF1E5F9E), Color(0xFF7DD3FC)],
      accentColor: Color(0xFF38BDF8),
      icon: Icons.landscape_rounded,
    ),
    ProfileBannerItem(
      id: 'banner_sakura',
      name: 'Sakura Garden',
      description: 'Soft pink hills and pale blossoms under a spring moon.',
      gemPrice: 150,
      skyColors: [Color(0xFF6B2145), Color(0xFFC24168), Color(0xFFF9A8D4)],
      accentColor: Color(0xFFF472B6),
      icon: Icons.local_florist_rounded,
    ),
    ProfileBannerItem(
      id: 'banner_midnight',
      name: 'Starlit Cosmos',
      description: 'Quiet crescent moon above deep violet mountain silhouettes.',
      gemPrice: 180,
      skyColors: [Color(0xFF0B0E24), Color(0xFF241B4D), Color(0xFF5B3A9E)],
      accentColor: Color(0xFFC084FC),
      icon: Icons.nights_stay_rounded,
    ),
    ProfileBannerItem(
      id: 'banner_autumn',
      name: 'Autumn Forest',
      description: 'Layered pine silhouettes bathed in crisp amber sunlight.',
      gemPrice: 150,
      skyColors: [Color(0xFF4A1D12), Color(0xFFB45309), Color(0xFFF59E0B)],
      accentColor: Color(0xFFFB923C),
      icon: Icons.forest_rounded,
    ),
    ProfileBannerItem(
      id: 'banner_savannah',
      name: 'La Mancha Dusk',
      description: 'Warm sunset mesas crowned by an iconic windmill silhouette.',
      gemPrice: 200,
      skyColors: [Color(0xFF5C1E14), Color(0xFFC2410C), Color(0xFFFBBF24)],
      accentColor: Color(0xFFF59E0B),
      icon: Icons.cyclone_rounded,
    ),

    // === ANIMATED MAGICAL PROFILE BACKGROUNDS (5,000 GEMS EACH) ===
    ProfileBannerItem(
      id: 'banner_anim_fireflies',
      name: 'Firefly Glade',
      description: 'Golden fireflies gently blinking and drifting over a twilight forest.',
      gemPrice: 5000,
      skyColors: [Color(0xFF0B192C), Color(0xFF143A42), Color(0xFF1E5649)],
      accentColor: Color(0xFFFDE047),
      icon: Icons.flare_rounded,
      motion: BannerMotion.fireflies,
    ),
    ProfileBannerItem(
      id: 'banner_anim_falling_pages',
      name: 'Drifting Pages',
      description: 'Ivory manuscript pages and paper petals floating through sunlit air.',
      gemPrice: 5000,
      skyColors: [Color(0xFF3E2723), Color(0xFF795548), Color(0xFFD7A86E)],
      accentColor: Color(0xFFFFF8E1),
      icon: Icons.auto_stories_rounded,
      motion: BannerMotion.fallingPages,
    ),
    ProfileBannerItem(
      id: 'banner_anim_starry_sky',
      name: 'Velvet Starry Sky',
      description: 'Calmly twinkling constellations and a slow shooting star across midnight blue.',
      gemPrice: 5000,
      skyColors: [Color(0xFF060818), Color(0xFF161D4A), Color(0xFF2E2A70)],
      accentColor: Color(0xFFBAE6FD),
      icon: Icons.auto_awesome_rounded,
      motion: BannerMotion.starrySky,
    ),
    ProfileBannerItem(
      id: 'banner_anim_drifting_ink',
      name: 'Calligraphy Ink Mist',
      description: 'Flowing watercolor ribbons of twilight indigo and teal ink.',
      gemPrice: 5000,
      skyColors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF312E81)],
      accentColor: Color(0xFFC084FC),
      icon: Icons.brush_rounded,
      motion: BannerMotion.driftingInk,
    ),
    ProfileBannerItem(
      id: 'banner_anim_candle_dust',
      name: 'Candlelight Study',
      description: 'Warm golden dust motes floating lazily through a glowing study beam.',
      gemPrice: 5000,
      skyColors: [Color(0xFF23140D), Color(0xFF5C2E14), Color(0xFFB46927)],
      accentColor: Color(0xFFFFE082),
      icon: Icons.light_mode_rounded,
      motion: BannerMotion.candleDust,
    ),
    ProfileBannerItem(
      id: 'banner_anim_window_rain',
      name: 'Rainy Reading Window',
      description: 'Soft slanted raindrops gliding calmly down a twilight library pane.',
      gemPrice: 5000,
      skyColors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
      accentColor: Color(0xFF7DD3FC),
      icon: Icons.water_drop_rounded,
      motion: BannerMotion.windowRain,
    ),
    ProfileBannerItem(
      id: 'banner_anim_aurora',
      name: 'Boreal Aurora',
      description: 'Silky emerald, cyan, and violet northern lights waving above alpine peaks.',
      gemPrice: 5000,
      skyColors: [Color(0xFF071324), Color(0xFF0D2E47), Color(0xFF1A4B5C)],
      accentColor: Color(0xFF34D399),
      icon: Icons.waves_rounded,
      motion: BannerMotion.aurora,
    ),
    ProfileBannerItem(
      id: 'banner_anim_sakura_drift',
      name: 'Blossom Courtyard',
      description: 'Soft rose petals swaying gently across a moonlit spring garden.',
      gemPrice: 5000,
      skyColors: [Color(0xFF4A1230), Color(0xFF9D2E5E), Color(0xFFF48FB1)],
      accentColor: Color(0xFFFCE7F3),
      icon: Icons.local_florist_rounded,
      motion: BannerMotion.sakuraDrift,
    ),
    ProfileBannerItem(
      id: 'banner_anim_ember_hearth',
      name: 'Hearthside Embers',
      description: 'Cozy glowing sparks rising gently from a warm mahogany fireplace.',
      gemPrice: 5000,
      skyColors: [Color(0xFF1F0A07), Color(0xFF6B1E10), Color(0xFFD95B26)],
      accentColor: Color(0xFFFFB74D),
      icon: Icons.fireplace_rounded,
      motion: BannerMotion.emberHearth,
    ),
    ProfileBannerItem(
      id: 'banner_anim_golden_hour',
      name: 'La Mancha Windmills',
      description: 'Slowly turning windmill sails silhouetted against a glowing amber sunset.',
      gemPrice: 5000,
      skyColors: [Color(0xFF4A1812), Color(0xFFC2410C), Color(0xFFFCD34D)],
      accentColor: Color(0xFFFEF08A),
      icon: Icons.wind_power_rounded,
      motion: BannerMotion.goldenWindmills,
    ),
  ];

  static ProfileBannerItem byId(String id) {
    return banners.firstWhere((b) => b.id == id, orElse: () => banners.first);
  }
}

/// Renders an illustrated scenic landscape background for the Profile Hero Card
/// and Cosmetics previews. Static banners use zero animation ticks; animated
/// banners run a calm, smooth looping [AnimationController].
class ProfileBannerBackground extends StatefulWidget {
  final String bannerId;
  final double height;

  const ProfileBannerBackground({
    super.key,
    required this.bannerId,
    this.height = 112,
  });

  @override
  State<ProfileBannerBackground> createState() => _ProfileBannerBackgroundState();
}

class _ProfileBannerBackgroundState extends State<ProfileBannerBackground>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  bool get _isAnimated => ProfileBannerCatalog.byId(widget.bannerId).isAnimated;

  @override
  void initState() {
    super.initState();
    _syncController();
  }

  @override
  void didUpdateWidget(covariant ProfileBannerBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bannerId != widget.bannerId) {
      _syncController();
    }
  }

  void _syncController() {
    if (_isAnimated) {
      _controller ??= AnimationController(
        vsync: this,
        duration: const Duration(seconds: 12),
      )..repeat();
    } else {
      _controller?.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = ProfileBannerCatalog.byId(widget.bannerId);
    if (_controller == null) {
      return SizedBox(
        height: widget.height,
        width: double.infinity,
        child: CustomPaint(
          painter: _ScenicBannerPainter(banner: banner, progress: 0.0),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller!,
      builder: (_, _) => SizedBox(
        height: widget.height,
        width: double.infinity,
        child: CustomPaint(
          painter: _ScenicBannerPainter(
            banner: banner,
            progress: _controller!.value,
          ),
        ),
      ),
    );
  }
}

class _ScenicBannerPainter extends CustomPainter {
  final ProfileBannerItem banner;
  final double progress;

  const _ScenicBannerPainter({
    required this.banner,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = progress * 2 * math.pi;

    // 1. Multi-stop Sky Gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: banner.skyColors,
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2. Animated Magical Banners
    if (banner.isAnimated) {
      switch (banner.motion) {
        case BannerMotion.fireflies:
          _paintFireflyGlade(canvas, w, h, t);
          return;
        case BannerMotion.fallingPages:
          _paintDriftingPages(canvas, w, h, progress);
          return;
        case BannerMotion.starrySky:
          _paintVelvetStarrySky(canvas, w, h, progress, t);
          return;
        case BannerMotion.driftingInk:
          _paintDriftingInk(canvas, w, h, t);
          return;
        case BannerMotion.candleDust:
          _paintCandleDust(canvas, w, h, progress, t);
          return;
        case BannerMotion.windowRain:
          _paintWindowRain(canvas, w, h, progress);
          return;
        case BannerMotion.aurora:
          _paintBorealAurora(canvas, w, h, t);
          return;
        case BannerMotion.sakuraDrift:
          _paintBlossomCourtyard(canvas, w, h, progress, t);
          return;
        case BannerMotion.emberHearth:
          _paintHearthEmbers(canvas, w, h, progress, t);
          return;
        case BannerMotion.goldenWindmills:
          _paintGoldenWindmills(canvas, w, h, progress, t);
          return;
        case BannerMotion.none:
          break;
      }
    }

    // 3. Static Scenic Banners
    switch (banner.id) {
      case 'banner_winter':
        _paintWinterMountains(canvas, w, h);
        break;
      case 'banner_sakura':
        _paintSakuraGarden(canvas, w, h);
        break;
      case 'banner_midnight':
        _paintStarlitCosmos(canvas, w, h);
        break;
      case 'banner_autumn':
        _paintAutumnForest(canvas, w, h);
        break;
      case 'banner_savannah':
        _paintLaManchaDusk(canvas, w, h);
        break;
      default:
        _paintSunlitHills(canvas, w, h);
        break;
    }
  }

  // === ANIMATED PAINTERS ===

  void _paintFireflyGlade(Canvas canvas, double w, double h, double t) {
    // Soft twilight silhouettes
    final hill = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.30, h * 0.52, w * 0.65, h * 0.74)
      ..quadraticBezierTo(w * 0.85, h * 0.84, w, h * 0.64)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(hill, Paint()..color = const Color(0xFF07131A).withValues(alpha: 0.75));

    // Gently blinking drifting fireflies
    for (int i = 0; i < 16; i++) {
      final seed = i * 1.7;
      final baseX = ((i * 59.0 + 18) % w);
      final baseY = ((i * 29.0 + 12) % (h * 0.82));
      final dx = math.sin(t + seed) * 10.0;
      final dy = math.cos(t * 0.8 + seed * 1.3) * 6.0;
      final glow = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * 2.0 + seed * 2.1));
      final pos = Offset((baseX + dx) % w, (baseY + dy).clamp(6.0, h - 6.0));
      canvas.drawCircle(
        pos,
        6.5,
        Paint()
          ..color = const Color(0xFFFDE047).withValues(alpha: glow * 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        pos,
        2.1,
        Paint()..color = const Color(0xFFFEF9C3).withValues(alpha: glow),
      );
    }
  }

  void _paintDriftingPages(Canvas canvas, double w, double h, double p) {
    // Warm sunlit library glow
    canvas.drawCircle(
      Offset(w * 0.16, h * 0.25),
      46,
      Paint()
        ..color = const Color(0xFFFFF8E1).withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    // Floating ivory paper pages / petals
    final pagePaint = Paint()..color = const Color(0xFFFFFBEB).withValues(alpha: 0.78);
    final linePaint = Paint()
      ..color = const Color(0xFFA1887F).withValues(alpha: 0.45)
      ..strokeWidth = 0.8;
    for (int i = 0; i < 11; i++) {
      final prog = (p + i * 0.13) % 1.0;
      final x = ((i * 67.0 + prog * w * 0.55) % (w + 20)) - 10;
      final y = (prog * (h + 24)) - 12;
      final rot = math.sin(prog * 2 * math.pi + i) * 0.45;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      final rect = Rect.fromCenter(center: Offset.zero, width: 11, height: 14);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), pagePaint);
      canvas.drawLine(const Offset(-3.5, -3), const Offset(3.5, -3), linePaint);
      canvas.drawLine(const Offset(-3.5, 0), const Offset(2.5, 0), linePaint);
      canvas.restore();
    }
  }

  void _paintVelvetStarrySky(Canvas canvas, double w, double h, double p, double t) {
    // Twinkling constellations
    for (int i = 0; i < 28; i++) {
      final sx = (i * 43.0 + 11) % w;
      final sy = (i * 23.0 + 7) % (h * 0.84);
      final twinkle = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(t * 2.0 + i * 1.3));
      canvas.drawCircle(
        Offset(sx, sy),
        i % 4 == 0 ? 2.1 : 1.2,
        Paint()..color = Colors.white.withValues(alpha: twinkle),
      );
    }
    // Calm slow shooting star
    final starPhase = (p * 1.5) % 1.0;
    if (starPhase < 0.35) {
      final sp = starPhase / 0.35;
      final startX = w * 0.15 + sp * w * 0.55;
      final startY = h * 0.15 + sp * h * 0.35;
      final alpha = math.sin(sp * math.pi);
      canvas.drawLine(
        Offset(startX - 24, startY - 12),
        Offset(startX, startY),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0),
              const Color(0xFFBAE6FD).withValues(alpha: alpha * 0.9),
            ],
          ).createShader(Rect.fromPoints(Offset(startX - 24, startY - 12), Offset(startX, startY)))
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
    }
    // Quiet mountain ridge
    final ridge = Path()
      ..moveTo(0, h)
      ..lineTo(w * 0.25, h * 0.72)
      ..lineTo(w * 0.55, h * 0.85)
      ..lineTo(w * 0.82, h * 0.65)
      ..lineTo(w, h * 0.80)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(ridge, Paint()..color = const Color(0xFF040612).withValues(alpha: 0.85));
  }

  void _paintDriftingInk(Canvas canvas, double w, double h, double t) {
    final colors = [
      const Color(0xFF818CF8).withValues(alpha: 0.24),
      const Color(0xFFC084FC).withValues(alpha: 0.22),
      const Color(0xFF2DD4BF).withValues(alpha: 0.18),
    ];
    for (int r = 0; r < 3; r++) {
      final path = Path();
      final baseY = h * (0.28 + r * 0.22);
      path.moveTo(0, baseY);
      for (double x = 0; x <= w; x += w / 12) {
        final y = baseY + math.sin((x / w) * 2 * math.pi + t + r * 1.4) * 14.0;
        path.lineTo(x, y);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = colors[r]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
  }

  void _paintCandleDust(Canvas canvas, double w, double h, double p, double t) {
    // Diagonal warm candlelight sunbeam
    final beam = Path()
      ..moveTo(w * 0.08, 0)
      ..lineTo(w * 0.42, 0)
      ..lineTo(w * 0.76, h)
      ..lineTo(w * 0.30, h)
      ..close();
    canvas.drawPath(
      beam,
      Paint()
        ..color = const Color(0xFFFFE082).withValues(alpha: 0.12 + 0.04 * math.sin(t))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    // Floating warm dust motes
    for (int i = 0; i < 18; i++) {
      final prog = (p + i * 0.07) % 1.0;
      final x = ((i * 47.0 + math.sin(t + i) * 12) % w);
      final y = h - (prog * h);
      final alpha = math.sin(prog * math.pi) * 0.75;
      canvas.drawCircle(
        Offset(x, y),
        i % 3 == 0 ? 2.2 : 1.3,
        Paint()..color = const Color(0xFFFFF8E1).withValues(alpha: alpha),
      );
    }
  }

  void _paintWindowRain(Canvas canvas, double w, double h, double p) {
    final rainPaint = Paint()
      ..color = const Color(0xFFBAE6FD).withValues(alpha: 0.45)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 24; i++) {
      final prog = (p * 3.0 + i * 0.17) % 1.0;
      final startX = (i * 37.0 + 10) % (w + 30);
      final y = prog * (h + 20) - 10;
      final x = startX - prog * 18;
      canvas.drawLine(Offset(x, y), Offset(x - 4, y + 12), rainPaint);
    }
    // Subtle cozy window mullion lines
    final framePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(w * 0.5, 0), Offset(w * 0.5, h), framePaint);
  }

  void _paintBorealAurora(Canvas canvas, double w, double h, double t) {
    final ribbons = [
      (const Color(0xFF34D399), 0.24, 0.0),
      (const Color(0xFF38BDF8), 0.36, 1.8),
      (const Color(0xFFA78BFA), 0.28, 3.4),
    ];
    for (final (col, yFrac, phase) in ribbons) {
      final path = Path()..moveTo(0, h * yFrac);
      for (double x = 0; x <= w; x += w / 10) {
        final y = h * yFrac + math.sin((x / w) * 2.2 * math.pi + t + phase) * 12;
        path.lineTo(x, y);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = col.withValues(alpha: 0.32)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
    // Alpine silhouettes
    final peaks = Path()
      ..moveTo(0, h)
      ..lineTo(w * 0.18, h * 0.58)
      ..lineTo(w * 0.42, h * 0.80)
      ..lineTo(w * 0.68, h * 0.48)
      ..lineTo(w * 0.90, h * 0.72)
      ..lineTo(w, h * 0.62)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(peaks, Paint()..color = const Color(0xFF06111F).withValues(alpha: 0.88));
  }

  void _paintBlossomCourtyard(Canvas canvas, double w, double h, double p, double t) {
    // Pale glowing moon
    canvas.drawCircle(
      Offset(w * 0.18, h * 0.28),
      20,
      Paint()..color = const Color(0xFFFFF1F2).withValues(alpha: 0.82),
    );
    // Swaying cherry blossom petals
    final petalPaint = Paint()..color = const Color(0xFFFCE7F3).withValues(alpha: 0.82);
    for (int i = 0; i < 16; i++) {
      final prog = (p + i * 0.09) % 1.0;
      final x = ((i * 53.0 + prog * 45 + math.sin(t + i) * 10) % w);
      final y = (prog * (h + 16)) - 8;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 0.5 + i);
      canvas.drawOval(const Rect.fromLTWH(-4.5, -2.2, 9, 4.4), petalPaint);
      canvas.restore();
    }
  }

  void _paintHearthEmbers(Canvas canvas, double w, double h, double p, double t) {
    // Warm hearth bottom glow
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.55, w, h * 0.45),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFFFF6D00).withValues(alpha: 0.32 + 0.08 * math.sin(t * 2)),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, h * 0.55, w, h * 0.45)),
    );
    // Gently rising embers
    for (int i = 0; i < 16; i++) {
      final prog = (p * 1.4 + i * 0.11) % 1.0;
      final x = ((i * 57.0 + math.sin(t + i * 2) * 10) % w);
      final y = h - prog * h;
      final alpha = (1.0 - prog) * 0.9;
      canvas.drawCircle(
        Offset(x, y),
        i % 3 == 0 ? 2.4 : 1.5,
        Paint()..color = Color.lerp(const Color(0xFFFFD54F), const Color(0xFFFF5722), prog)!.withValues(alpha: alpha),
      );
    }
  }

  void _paintGoldenWindmills(Canvas canvas, double w, double h, double p, double t) {
    // Glowing golden sun
    canvas.drawCircle(
      Offset(w * 0.24, h * 0.46),
      28 + math.sin(t) * 2,
      Paint()..color = const Color(0xFFFEF08A).withValues(alpha: 0.65),
    );
    // Mesas
    final mesa = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.72)
      ..lineTo(w * 0.18, h * 0.64)
      ..lineTo(w * 0.36, h * 0.64)
      ..lineTo(w * 0.48, h * 0.78)
      ..lineTo(w * 0.72, h * 0.68)
      ..lineTo(w * 0.84, h * 0.58)
      ..lineTo(w, h * 0.58)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(mesa, Paint()..color = const Color(0xFF3D130B).withValues(alpha: 0.76));

    // Slowly turning windmill sails
    final wx = w * 0.86;
    final wy = h * 0.58;
    final millPaint = Paint()
      ..color = const Color(0xFF280B06)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawRect(Rect.fromLTWH(wx - 4.5, wy - 16, 9, 16), millPaint);
    for (int i = 0; i < 4; i++) {
      final a = (i * math.pi / 2) + t;
      canvas.drawLine(
        Offset(wx, wy - 14),
        Offset(wx + math.cos(a) * 14, wy - 14 + math.sin(a) * 14),
        millPaint,
      );
    }
  }

  // === STATIC PAINTERS ===

  void _paintWinterMountains(Canvas canvas, double w, double h) {
    final aurora = Path()
      ..moveTo(0, h * 0.25)
      ..quadraticBezierTo(w * 0.35, h * 0.05, w * 0.65, h * 0.28)
      ..quadraticBezierTo(w * 0.85, h * 0.42, w, h * 0.18);
    canvas.drawPath(
      aurora,
      Paint()
        ..color = const Color(0xFF67E8F9).withValues(alpha: 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    final backMt = Path()
      ..moveTo(0, h)
      ..lineTo(w * 0.16, h * 0.36)
      ..lineTo(w * 0.34, h * 0.68)
      ..lineTo(w * 0.56, h * 0.24)
      ..lineTo(w * 0.78, h * 0.62)
      ..lineTo(w * 0.92, h * 0.32)
      ..lineTo(w, h * 0.55)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(backMt, Paint()..color = const Color(0xFF1E3A5F).withValues(alpha: 0.85));
    final cap1 = Path()
      ..moveTo(w * 0.56, h * 0.24)
      ..lineTo(w * 0.49, h * 0.42)
      ..lineTo(w * 0.54, h * 0.38)
      ..lineTo(w * 0.58, h * 0.43)
      ..lineTo(w * 0.63, h * 0.40)
      ..close();
    final cap2 = Path()
      ..moveTo(w * 0.16, h * 0.36)
      ..lineTo(w * 0.11, h * 0.50)
      ..lineTo(w * 0.16, h * 0.46)
      ..lineTo(w * 0.21, h * 0.50)
      ..close();
    final snowPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawPath(cap1, snowPaint);
    canvas.drawPath(cap2, snowPaint);
    final frontRidge = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.76)
      ..quadraticBezierTo(w * 0.30, h * 0.58, w * 0.62, h * 0.78)
      ..quadraticBezierTo(w * 0.84, h * 0.90, w, h * 0.68)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(frontRidge, Paint()..color = const Color(0xFF0F2540).withValues(alpha: 0.8));
    final flakePaint = Paint()..color = Colors.white.withValues(alpha: 0.75);
    for (int i = 0; i < 16; i++) {
      final x = (i * 53.0 % w);
      final y = ((i * 29.0) % (h * 0.85)) + 6;
      canvas.drawCircle(Offset(x, y), i.isEven ? 2.2 : 1.4, flakePaint);
    }
  }

  void _paintSakuraGarden(Canvas canvas, double w, double h) {
    canvas.drawCircle(
      Offset(w * 0.20, h * 0.30),
      20,
      Paint()..color = const Color(0xFFFFF1F2).withValues(alpha: 0.85),
    );
    final hill = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.32, h * 0.52, w * 0.64, h * 0.74)
      ..quadraticBezierTo(w * 0.85, h * 0.84, w, h * 0.64)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(hill, Paint()..color = const Color(0xFF4C1230).withValues(alpha: 0.55));
    final petalPaint = Paint()..color = const Color(0xFFFCE7F3).withValues(alpha: 0.82);
    for (int i = 0; i < 14; i++) {
      final px = (i * 47.0 + 18) % w;
      final py = (i * 23.0 + 10) % (h * 0.82);
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(i * 0.5);
      canvas.drawOval(const Rect.fromLTWH(-4, -2, 8, 4), petalPaint);
      canvas.restore();
    }
  }

  void _paintStarlitCosmos(Canvas canvas, double w, double h) {
    canvas.drawCircle(
      Offset(w * 0.18, h * 0.32),
      18,
      Paint()..color = const Color(0xFFFEF08A).withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      Offset(w * 0.21, h * 0.28),
      16,
      Paint()..color = banner.skyColors[0],
    );
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (int i = 0; i < 22; i++) {
      final sx = (i * 41.0 + 12) % w;
      final sy = (i * 19.0 + 8) % (h * 0.82);
      canvas.drawCircle(Offset(sx, sy), i % 3 == 0 ? 2.2 : 1.2, starPaint);
    }
    final ridge = Path()
      ..moveTo(0, h)
      ..lineTo(w * 0.22, h * 0.68)
      ..lineTo(w * 0.48, h * 0.82)
      ..lineTo(w * 0.78, h * 0.60)
      ..lineTo(w, h * 0.78)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(ridge, Paint()..color = const Color(0xFF070918).withValues(alpha: 0.85));
  }

  void _paintAutumnForest(Canvas canvas, double w, double h) {
    canvas.drawCircle(
      Offset(w * 0.22, h * 0.36),
      26,
      Paint()..color = const Color(0xFFFDE68A).withValues(alpha: 0.45),
    );
    final treePaint = Paint()..color = const Color(0xFF3B150A).withValues(alpha: 0.78);
    for (int i = 0; i < 9; i++) {
      final tx = (i + 0.5) * (w / 9);
      final th = h * (0.32 + (i % 3) * 0.08);
      final tree = Path()
        ..moveTo(tx, h - th)
        ..lineTo(tx - 16, h)
        ..lineTo(tx + 16, h)
        ..close();
      canvas.drawPath(tree, treePaint);
    }
    final leafPaint = Paint()..color = const Color(0xFFFDE047).withValues(alpha: 0.78);
    for (int i = 0; i < 10; i++) {
      final lx = (i * 61.0 + 14) % w;
      final ly = (i * 25.0 + 10) % (h * 0.75);
      canvas.drawOval(Rect.fromCenter(center: Offset(lx, ly), width: 7, height: 3.5), leafPaint);
    }
  }

  void _paintLaManchaDusk(Canvas canvas, double w, double h) {
    canvas.drawCircle(
      Offset(w * 0.24, h * 0.48),
      28,
      Paint()..color = const Color(0xFFFEF08A).withValues(alpha: 0.65),
    );
    final mesa = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.72)
      ..lineTo(w * 0.14, h * 0.62)
      ..lineTo(w * 0.34, h * 0.62)
      ..lineTo(w * 0.44, h * 0.76)
      ..lineTo(w * 0.68, h * 0.72)
      ..lineTo(w * 0.82, h * 0.58)
      ..lineTo(w, h * 0.58)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(mesa, Paint()..color = const Color(0xFF3D130B).withValues(alpha: 0.72));
    final wx = w * 0.86;
    final wy = h * 0.58;
    final millPaint = Paint()
      ..color = const Color(0xFF280B06)
      ..strokeWidth = 2.0;
    canvas.drawRect(Rect.fromLTWH(wx - 4, wy - 14, 8, 14), millPaint);
    for (int i = 0; i < 4; i++) {
      final a = (i * math.pi / 2) + 0.4;
      canvas.drawLine(
        Offset(wx, wy - 12),
        Offset(wx + math.cos(a) * 11, wy - 12 + math.sin(a) * 11),
        millPaint,
      );
    }
  }

  void _paintSunlitHills(Canvas canvas, double w, double h) {
    canvas.drawCircle(
      Offset(w * 0.18, h * 0.30),
      26,
      Paint()..color = const Color(0xFFFFFBEB).withValues(alpha: 0.28),
    );
    final backHill = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.66)
      ..quadraticBezierTo(w * 0.28, h * 0.42, w * 0.58, h * 0.68)
      ..quadraticBezierTo(w * 0.82, h * 0.82, w, h * 0.58)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(backHill, Paint()..color = Colors.black.withValues(alpha: 0.18));
    final frontHill = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.82)
      ..quadraticBezierTo(w * 0.38, h * 0.64, w * 0.72, h * 0.82)
      ..quadraticBezierTo(w * 0.90, h * 0.88, w, h * 0.74)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(frontHill, Paint()..color = Colors.black.withValues(alpha: 0.24));
  }

  @override
  bool shouldRepaint(covariant _ScenicBannerPainter oldDelegate) =>
      oldDelegate.banner.id != banner.id || oldDelegate.progress != progress;
}
