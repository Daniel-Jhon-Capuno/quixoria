import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/narration_service.dart';
import '../../core/services/sound_service.dart';

class NarrationBar extends StatefulWidget {
  final VoidCallback onClose;
  final Function(int paragraphIndex)? onParagraphChanged;

  const NarrationBar({
    super.key,
    required this.onClose,
    this.onParagraphChanged,
  });

  @override
  State<NarrationBar> createState() => _NarrationBarState();
}

class _NarrationBarState extends State<NarrationBar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: NarrationService.instance,
      builder: (context, _) {
        final narration = NarrationService.instance;
        final current = narration.currentIndex + 1;
        final total = narration.totalParagraphs;
        final isPlaying = narration.isPlaying;
        final currentText = narration.paragraphs.isNotEmpty && narration.currentIndex < narration.paragraphs.length
            ? narration.paragraphs[narration.currentIndex]
            : '';

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1B24) : AppColors.parchmentWarm,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              if (isPlaying)
                BoxShadow(
                  color: AppColors.antiqueGold.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
            ],
            border: Border.all(
              color: isPlaying ? AppColors.antiqueGold : theme.dividerColor.withValues(alpha: 0.4),
              width: 1.4,
            ),
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOutCubic,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                HapticService.instance.selection();
                setState(() => _isExpanded = !_isExpanded);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Minimized Main Header Row
                    Row(
                      children: [
                        // Play / Pause Circle Button
                        IconButton.filled(
                          iconSize: 22,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.antiqueGold,
                            foregroundColor: isDark ? const Color(0xFF121212) : theme.colorScheme.primary,
                            padding: const EdgeInsets.all(8),
                          ),
                          icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                          onPressed: () {
                            HapticService.instance.light();
                            SoundService.instance.play(Sfx.tap);
                            if (isPlaying) {
                              narration.pause();
                            } else {
                              narration.play();
                              widget.onParagraphChanged?.call(narration.currentIndex);
                            }
                          },
                        ),
                        const SizedBox(width: 10),

                        // Title with text hierarchy and context
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (isPlaying) ...[
                                    const Icon(Icons.graphic_eq_rounded, size: 14, color: AppColors.antiqueGold),
                                    const SizedBox(width: 4),
                                  ],
                                  Expanded(
                                    child: Text(
                                      isPlaying ? 'Narrator Speaking' : (narration.isPaused ? 'Audio Paused' : 'Audio Narrator Ready'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.labelSmall.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: isPlaying ? AppColors.antiqueGold : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    total > 0 ? '$current / $total' : '',
                                    style: AppTypography.labelSmall.copyWith(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isExpanded
                                    ? 'Tap bar to minimize controls'
                                    : (currentText.isNotEmpty ? '${narration.persona.icon} ${narration.persona.name} • Tap for speed & models' : 'Tap for controls'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Expand/Collapse Chevron Indicator
                        Icon(
                          _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 2),

                        // Close button
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          onPressed: () {
                            HapticService.instance.light();
                            SoundService.instance.play(Sfx.tap);
                            narration.stop();
                            widget.onClose();
                          },
                        ),
                      ],
                    ),

                    // Slim Progress bar
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0,
                        minHeight: 3.5,
                        backgroundColor: theme.dividerColor.withValues(alpha: 0.25),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.antiqueGold),
                      ),
                    ),

                    // Detailed Controls (Visible ONLY when tapped)
                    if (_isExpanded) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 10),

                      // Paragraph Context Preview
                      if (currentText.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF14141B) : Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.antiqueGold.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CURRENT SPOKEN PASSAGE:',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.antiqueGold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '“$currentText”',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  height: 1.35,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Narrator Voice Model Selection Row
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.record_voice_over_rounded, size: 13, color: AppColors.antiqueGold),
                              const SizedBox(width: 6),
                              Text(
                                'NATURAL NARRATOR MODEL:',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.antiqueGold,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: NarratorPersona.values.map((persona) {
                              final isSelected = narration.persona == persona;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () {
                                      HapticService.instance.selection();
                                      SoundService.instance.play(Sfx.tap);
                                      narration.setPersona(persona);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.antiqueGold.withValues(alpha: isDark ? 0.22 : 0.16)
                                            : (isDark ? const Color(0xFF161620) : Colors.white.withValues(alpha: 0.7)),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.antiqueGold
                                              : (isDark ? Colors.white12 : theme.dividerColor.withValues(alpha: 0.4)),
                                          width: isSelected ? 1.6 : 1.0,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(persona.icon, style: const TextStyle(fontSize: 16)),
                                          const SizedBox(height: 3),
                                          Text(
                                            persona.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                              color: isSelected
                                                  ? AppColors.antiqueGold
                                                  : theme.colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            persona.subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 8.5,
                                              color: isSelected
                                                  ? AppColors.antiqueGold.withValues(alpha: 0.9)
                                                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Control Actions Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Skip Previous Paragraph
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            icon: const Icon(Icons.skip_previous_rounded, size: 18),
                            label: const Text('Previous', style: TextStyle(fontSize: 11)),
                            onPressed: narration.currentIndex > 0
                                ? () {
                                    HapticService.instance.light();
                                    SoundService.instance.play(Sfx.tap);
                                    narration.previousParagraph();
                                    widget.onParagraphChanged?.call(narration.currentIndex);
                                  }
                                : null,
                          ),

                          // Speed Cycling Pill
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              HapticService.instance.selection();
                              SoundService.instance.play(Sfx.tap);
                              narration.cycleSpeechRate();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF262633) : AppColors.parchmentDark.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.antiqueGold.withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.speed_rounded, size: 14, color: AppColors.antiqueGold),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Speed: ${narration.speechRate}x',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Skip Next Paragraph
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            icon: const Icon(Icons.skip_next_rounded, size: 18),
                            label: const Text('Next', style: TextStyle(fontSize: 11)),
                            onPressed: narration.currentIndex < total - 1
                                ? () {
                                    HapticService.instance.light();
                                    SoundService.instance.play(Sfx.tap);
                                    narration.nextParagraph();
                                    widget.onParagraphChanged?.call(narration.currentIndex);
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
