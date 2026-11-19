import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_typography.dart';
import '../../models/quote_card.dart';
import 'share_card_sheet.dart';

class QuoteCardPalette {
  final String key;
  final String label;
  final List<Color> gradient;
  final Color textColor;
  final Color accentColor;
  final Color borderColor;

  const QuoteCardPalette({
    required this.key,
    required this.label,
    required this.gradient,
    required this.textColor,
    required this.accentColor,
    required this.borderColor,
  });

  static const List<QuoteCardPalette> all = [
    QuoteCardPalette(
      key: 'parchment',
      label: 'Cream',
      gradient: [Color(0xFFFAF8F4), Color(0xFFF1EAE0)],
      textColor: Color(0xFF1F2421),
      accentColor: Color(0xFFB8860B),
      borderColor: Color(0xFFD9C7A3),
    ),
    QuoteCardPalette(
      key: 'sakura',
      label: 'Sakura',
      gradient: [Color(0xFFFFF2F6), Color(0xFFFAD8E5)],
      textColor: Color(0xFF3B121E),
      accentColor: Color(0xFFC24168),
      borderColor: Color(0xFFF2A7C0),
    ),
    QuoteCardPalette(
      key: 'midnight',
      label: 'Midnight',
      gradient: [Color(0xFF171426), Color(0xFF281F44)],
      textColor: Color(0xFFF5F3FA),
      accentColor: Color(0xFFD8A4FF),
      borderColor: Color(0xFF5A438A),
    ),
    QuoteCardPalette(
      key: 'frost',
      label: 'Frost',
      gradient: [Color(0xFFF0F8FD), Color(0xFFD4E9F7)],
      textColor: Color(0xFF0B253A),
      accentColor: Color(0xFF1B6CA8),
      borderColor: Color(0xFF9ACAE6),
    ),
    QuoteCardPalette(
      key: 'savannah',
      label: 'Savannah',
      gradient: [Color(0xFFFAF6F0), Color(0xFFF2DFCE)],
      textColor: Color(0xFF2C1810),
      accentColor: Color(0xFFD95B30),
      borderColor: Color(0xFFE0A98A),
    ),
    QuoteCardPalette(
      key: 'emerald',
      label: 'Garden',
      gradient: [Color(0xFF163024), Color(0xFF234B38)],
      textColor: Color(0xFFF7FBF8),
      accentColor: Color(0xFFE5B842),
      borderColor: Color(0xFF4C7D64),
    ),
  ];

  static QuoteCardPalette byKey(String key) {
    return all.firstWhere((p) => p.key == key, orElse: () => all.first);
  }
}

/// Aesthetic literary Quote Card widget used in Reader preview and Notebook Quote Gallery.
class AestheticQuoteCard extends StatelessWidget {
  final QuoteCard card;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onChangeStyle;
  final bool showActions;

  const AestheticQuoteCard({
    super.key,
    required this.card,
    this.onDelete,
    this.onChangeStyle,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = QuoteCardPalette.byKey(card.styleKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.gradient,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: palette.accentColor.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.format_quote_rounded,
                size: 30,
                color: palette.accentColor.withValues(alpha: 0.78),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  card.chapterTitle,
                  style: AppTypography.labelSmall.copyWith(
                    color: palette.accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '“${card.quoteText}”',
            style: AppTypography.bodyLarge.copyWith(
              color: palette.textColor,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              height: 1.5,
              fontSize: 15.5,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            color: palette.borderColor.withValues(alpha: 0.65),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.literatureTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMedium.copyWith(
                        color: palette.textColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      card.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: palette.textColor.withValues(alpha: 0.72),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (showActions) ...[
                IconButton(
                  tooltip: 'Share Quote Card (PNG)',
                  icon: Icon(Icons.ios_share_rounded, size: 18, color: palette.accentColor),
                  onPressed: () => ShareCardSheet.showQuoteCard(context, card),
                ),
                IconButton(
                  tooltip: 'Copy Quote',
                  icon: Icon(Icons.copy_rounded, size: 18, color: palette.accentColor),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: '“${card.quoteText}” — ${card.author}, ${card.literatureTitle}',
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Quote copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                if (onChangeStyle != null)
                  PopupMenuButton<String>(
                    tooltip: 'Change Card Style',
                    icon: Icon(Icons.palette_outlined, size: 18, color: palette.accentColor),
                    onSelected: onChangeStyle,
                    itemBuilder: (_) => QuoteCardPalette.all
                        .map(
                          (p) => PopupMenuItem<String>(
                            value: p.key,
                            child: Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: p.accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(p.label),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Delete Quote Card',
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: palette.textColor.withValues(alpha: 0.6),
                    ),
                    onPressed: onDelete,
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
