import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/haptic_service.dart';
import '../../core/state/app_state.dart';
import '../../models/quote_card.dart';
import 'aesthetic_quote_card.dart';
import 'duo_button.dart';
import 'framed_mascot_avatar.dart';
import 'profile_banner_painter.dart';
import 'scholar_hierarchy_card.dart';

/// Shareable Milestone & Quote PNG Card Exporter Sheet.
/// Captures a high-resolution (3x) PNG snapshot via [RepaintBoundary] and opens
/// the native Share Sheet (Instagram, Messenger, WhatsApp, Files, etc.).
class ShareCardSheet extends StatefulWidget {
  final Widget Function(String styleKey) cardBuilder;
  final List<({String key, String label, Color dotColor})> styles;
  final String initialStyleKey;
  final String sheetTitle;
  final String shareText;
  final String filePrefix;

  const ShareCardSheet({
    super.key,
    required this.cardBuilder,
    required this.styles,
    required this.initialStyleKey,
    required this.sheetTitle,
    required this.shareText,
    required this.filePrefix,
  });

  /// Opens a Shareable Profile Milestone / Flex Card sheet.
  static Future<void> showProfileCard(BuildContext context) {
    final state = context.read<AppState>();
    final profile = state.profile;
    final xp = ScholarHierarchy.computeScholarXp(state);
    final tier = ScholarHierarchy.currentTierForXp(xp);
    final unlockedAch = state.achievements.where((a) => a.isUnlocked).length;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareCardSheet(
        sheetTitle: 'Share Profile Milestone Card',
        shareText:
            '${profile.name} is ${tier.title} (Tier ${tier.roman}) on Quixoria with a ${profile.streakDays}-day reading streak and $xp Scholar XP!',
        filePrefix: 'quixoria_profile_card',
        initialStyleKey: 'obsidian',
        styles: const [
          (key: 'obsidian', label: 'Obsidian Gold', dotColor: Color(0xFF1A1D24)),
          (key: 'parchment', label: 'Parchment', dotColor: Color(0xFFF5EFE2)),
          (key: 'emerald', label: 'Royal Forest', dotColor: Color(0xFF153226)),
        ],
        cardBuilder: (styleKey) {
          final isLight = styleKey == 'parchment';
          final bgColors = switch (styleKey) {
            'parchment' => const [Color(0xFFFAF6EE), Color(0xFFEFE6D4)],
            'emerald' => const [Color(0xFF163427), Color(0xFF0D2018)],
            _ => const [Color(0xFF1B1E26), Color(0xFF101218)],
          };
          final fg = isLight ? const Color(0xFF1A1C19) : Colors.white;
          final muted = isLight ? const Color(0xFF5A625C) : Colors.white70;
          final statBg = isLight
              ? Colors.black.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.07);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: bgColors,
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.antiqueGold, width: 2.2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    ProfileBannerBackground(
                      bannerId: profile.equippedBannerId,
                      height: 102,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 52),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: bgColors.first,
                          shape: BoxShape.circle,
                        ),
                        child: FramedMascotAvatar(
                          frame: state.equippedFrame,
                          size: 76,
                          showMascot: true,
                          avatarIconId: profile.equippedAvatarIconId,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                  child: Column(
                    children: [
                      Text(
                        profile.name,
                        textAlign: TextAlign.center,
                        style: AppTypography.titleLarge.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: tier.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: tier.color, width: 1.2),
                            ),
                            child: Text(
                              'Tier ${tier.roman} • ${tier.title}',
                              style: TextStyle(
                                color: tier.color,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: state.equippedTitle.badgeColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              state.equippedTitle.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _miniStat('🔥 ${profile.streakDays}', 'Streak', statBg, fg, muted),
                          const SizedBox(width: 8),
                          _miniStat('⚡ $xp', 'XP', statBg, fg, muted),
                          const SizedBox(width: 8),
                          _miniStat('📚 ${profile.booksCompleted}', 'Books', statBg, fg, muted),
                          const SizedBox(width: 8),
                          _miniStat('🏆 $unlockedAch', 'Medals', statBg, fg, muted),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_stories_rounded, size: 14, color: AppColors.antiqueGold),
                          const SizedBox(width: 6),
                          Text(
                            'QUIXORIA • Classic Literature Quest',
                            style: AppTypography.labelSmall.copyWith(
                              color: muted,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Opens a Shareable Literary Quote PNG Card sheet.
  static Future<void> showQuoteCard(BuildContext context, QuoteCard card) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareCardSheet(
        sheetTitle: 'Share Literary Quote Card',
        shareText: '“${card.quoteText}” — ${card.author}, ${card.literatureTitle} (via Quixoria)',
        filePrefix: 'quixoria_quote_card',
        initialStyleKey: card.styleKey,
        styles: QuoteCardPalette.all
            .map((p) => (key: p.key, label: p.label, dotColor: p.accentColor))
            .toList(),
        cardBuilder: (styleKey) {
          final palette = QuoteCardPalette.byKey(styleKey);
          return Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette.gradient,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: palette.borderColor, width: 2.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.format_quote_rounded, size: 32, color: palette.accentColor),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: palette.accentColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        card.chapterTitle,
                        style: TextStyle(
                          color: palette.accentColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '“${card.quoteText}”',
                  style: AppTypography.bodyLarge.copyWith(
                    color: palette.textColor,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                    height: 1.55,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: palette.borderColor.withValues(alpha: 0.65), height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.literatureTitle,
                            style: AppTypography.titleSmall.copyWith(
                              color: palette.textColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            card.author,
                            style: AppTypography.bodySmall.copyWith(
                              color: palette.textColor.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'QUIXORIA',
                      style: TextStyle(
                        color: palette.accentColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Opens a Shareable Quiz Conquest Milestone PNG Card sheet.
  static Future<void> showQuizMilestoneCard({
    required BuildContext context,
    required String bookTitle,
    required String levelTitle,
    required int percentage,
    required int correctCount,
    required int totalCount,
    required int bestCombo,
  }) {
    final state = context.read<AppState>();
    final profile = state.profile;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareCardSheet(
        sheetTitle: 'Share Quiz Milestone',
        shareText:
            'I scored $percentage% ($correctCount/$totalCount) on "$levelTitle" in $bookTitle on Quixoria!',
        filePrefix: 'quixoria_quiz_milestone',
        initialStyleKey: 'obsidian',
        styles: const [
          (key: 'obsidian', label: 'Obsidian Gold', dotColor: Color(0xFF1A1D24)),
          (key: 'parchment', label: 'Parchment', dotColor: Color(0xFFF5EFE2)),
          (key: 'emerald', label: 'Royal Forest', dotColor: Color(0xFF153226)),
        ],
        cardBuilder: (styleKey) {
          final isLight = styleKey == 'parchment';
          final bgColors = switch (styleKey) {
            'parchment' => const [Color(0xFFFAF6EE), Color(0xFFEFE6D4)],
            'emerald' => const [Color(0xFF163427), Color(0xFF0D2018)],
            _ => const [Color(0xFF1B1E26), Color(0xFF101218)],
          };
          final fg = isLight ? const Color(0xFF1A1C19) : Colors.white;
          final muted = isLight ? const Color(0xFF5A625C) : Colors.white70;
          final statBg = isLight
              ? Colors.black.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.08);

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: bgColors,
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.antiqueGold, width: 2.2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.military_tech_rounded, size: 46, color: AppColors.antiqueGold),
                const SizedBox(height: 6),
                Text(
                  percentage == 100 ? 'PRISTINE SCHOLARSHIP!' : 'CHAPTER CONQUERED!',
                  style: const TextStyle(
                    color: AppColors.antiqueGold,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  bookTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.titleLarge.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  levelTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(color: muted),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _miniStat('$percentage%', 'Score', statBg, fg, muted),
                    const SizedBox(width: 8),
                    _miniStat('$correctCount/$totalCount', 'Correct', statBg, fg, muted),
                    const SizedBox(width: 8),
                    _miniStat('${bestCombo}x', 'Combo', statBg, fg, muted),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '${profile.name} • QUIXORIA',
                  style: AppTypography.labelSmall.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _miniStat(
    String value,
    String label,
    Color bg,
    Color fg,
    Color muted,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  @override
  State<ShareCardSheet> createState() => _ShareCardSheetState();
}

class _ShareCardSheetState extends State<ShareCardSheet> {
  final GlobalKey _repaintKey = GlobalKey();
  late String _selectedStyle;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.initialStyleKey;
  }

  Future<void> _exportAndShare() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    HapticService.instance.light();

    try {
      if (kIsWeb) {
        await Clipboard.setData(ClipboardData(text: widget.shareText));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Share text copied to clipboard!'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
        return;
      }

      final boundary =
          _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/${widget.filePrefix}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes, flush: true);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: widget.shareText,
      );
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: widget.shareText));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied share caption to clipboard!'),
            backgroundColor: AppColors.antiqueGold,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF17191E) : const Color(0xFFFAF8F4);
    final border = theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.45);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1C19);
    final textMuted = isDark ? Colors.white70 : const Color(0xFF5A625C);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: border, width: 2.0),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.ios_share_rounded, color: AppColors.antiqueGold, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.sheetTitle,
                      style: AppTypography.titleLarge.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // High-resolution PNG Capture Target
              RepaintBoundary(
                key: _repaintKey,
                child: widget.cardBuilder(_selectedStyle),
              ),
              const SizedBox(height: 16),
              // Card Style Switcher
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.styles.map((s) {
                    final active = _selectedStyle == s.key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          HapticService.instance.light();
                          setState(() => _selectedStyle = s.key);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.antiqueGold.withValues(alpha: 0.2)
                                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: active ? AppColors.antiqueGold : border,
                              width: active ? 1.8 : 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: s.dotColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white54),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                s.label,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: active ? AppColors.antiqueGold : textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),
              DuoButton(
                text: _isExporting ? 'Preparing Image…' : 'Share Card Image (PNG)',
                icon: Icons.share_rounded,
                variant: DuoButtonVariant.gold,
                height: 50,
                isLoading: _isExporting,
                onPressed: _isExporting ? null : _exportAndShare,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
