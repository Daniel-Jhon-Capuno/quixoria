import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../models/literature.dart';

class LiteratureCover extends StatelessWidget {
  final Literature literature;
  final double width;
  final double height;
  final bool showTypeBadge;

  const LiteratureCover({
    super.key,
    required this.literature,
    this.width = 110,
    this.height = 160,
    this.showTypeBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    // Generate distinct book hues based on title hash for rich variety
    final colorScheme = _getCoverTheme(literature.title);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.inkDark.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Spine crease effect on left
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: width * 0.08,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Embossed Antique Bookplate Frame
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colorScheme.accent.withValues(alpha: 0.6), width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Icon / Emblem
                      Icon(
                        _getTypeIcon(literature.type),
                        size: width * 0.18,
                        color: colorScheme.accent,
                      ),

                      // Title
                      Expanded(
                        child: Center(
                          child: Text(
                            literature.title,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleSmall.copyWith(
                              fontSize: width * 0.12,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.text,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ),

                      // Author
                      Text(
                        literature.author,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: width * 0.09,
                          fontStyle: FontStyle.italic,
                          color: colorScheme.text.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Literature Type Pill (Only show on larger book covers to prevent clipping)
            if (showTypeBadge && width >= 85)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  constraints: BoxConstraints(maxWidth: width * 0.5),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.parchmentCream,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: colorScheme.accent, width: 0.8),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      literature.type.label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: AppColors.inkDark,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(LiteratureType type) {
    switch (type) {
      case LiteratureType.novel:
        return Icons.auto_stories_rounded;
      case LiteratureType.shortStory:
        return Icons.menu_book_rounded;
      case LiteratureType.poem:
      case LiteratureType.sonnet:
        return Icons.history_edu_rounded;
      case LiteratureType.classic:
        return Icons.castle_rounded;
    }
  }

  _CoverTheme _getCoverTheme(String title) {
    final hash = title.hashCode.abs();
    final themes = [
      _CoverTheme(
        background: const Color(0xFF1E382B), // Forest
        accent: AppColors.antiqueGold,
        text: AppColors.parchmentCream,
      ),
      _CoverTheme(
        background: const Color(0xFF3B261F), // Leather Mahogany
        accent: const Color(0xFFE2C485),
        text: AppColors.parchmentCream,
      ),
      _CoverTheme(
        background: const Color(0xFF2C3E50), // Midnight Blue
        accent: const Color(0xFFF39C12),
        text: AppColors.parchmentCream,
      ),
      _CoverTheme(
        background: const Color(0xFF5D3A58), // Plum Velvet
        accent: const Color(0xFFF7D070),
        text: AppColors.parchmentCream,
      ),
      _CoverTheme(
        background: const Color(0xFF3E5045), // Sage Forest
        accent: const Color(0xFFFFD166),
        text: AppColors.parchmentCream,
      ),
    ];
    return themes[hash % themes.length];
  }
}

class _CoverTheme {
  final Color background;
  final Color accent;
  final Color text;

  _CoverTheme({
    required this.background,
    required this.accent,
    required this.text,
  });
}
