import 'package:provider/provider.dart';
import '../../core/state/app_state.dart';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/ambience_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';

class AmbienceSoundscapeSheet extends StatelessWidget {
  const AmbienceSoundscapeSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AmbienceSoundscapeSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E1E26) : AppColors.parchmentWarm;

    return AnimatedBuilder(
      animation: AmbienceService.instance,
      builder: (context, _) {
        final ambience = AmbienceService.instance;
        final isPlaying = ambience.isPlaying;
        final currentTrack = ambience.currentTrack;
        final volume = ambience.volume;

        return Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
            border: Border.all(
              color: AppColors.antiqueGold.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag notch
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.antiqueGold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.spatial_audio_rounded,
                      color: AppColors.antiqueGold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reading Ambience & Music',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isPlaying
                              ? 'Now Playing: ${currentTrack.title}'
                              : 'Soothing acoustic atmospheres for thy journey',
                          style: AppTypography.bodySmall.copyWith(
                            color: isPlaying
                                ? AppColors.antiqueGold
                                : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                            fontSize: 11,
                            fontWeight: isPlaying ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Master Play/Pause Toggle Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF16161D) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isPlaying ? AppColors.antiqueGold : theme.dividerColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPlaying ? Icons.music_note_rounded : Icons.music_off_rounded,
                      color: isPlaying ? AppColors.antiqueGold : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isPlaying ? 'Ambience Active' : 'Ambience Muted',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isPlaying ? AppColors.antiqueGold : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Switch(
                      value: isPlaying,
                      activeThumbColor: AppColors.antiqueGold,
                      activeTrackColor: AppColors.antiqueGold.withValues(alpha: 0.35),
                      onChanged: (val) {
                        HapticService.instance.light();
                        SoundService.instance.play(Sfx.toggle);
                        if (val) {
                          ambience.resume();
                        } else {
                          ambience.pause();
                        }
                        try {
                          final state = Provider.of<AppState>(context, listen: false);
                          if (state.musicEnabled != val) {
                            state.toggleMusic(val);
                          }
                        } catch (_) {}
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Choose Thy Atmosphere:',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 10),

              // Soundscape track list
              for (final track in AmbienceTrack.values) ...[
                _buildTrackCard(
                  track: track,
                  isSelected: currentTrack == track,
                  isPlaying: isPlaying && currentTrack == track,
                  isDark: isDark,
                  theme: theme,
                  onTap: () {
                    HapticService.instance.selection();
                    SoundService.instance.play(Sfx.tap);
                    ambience.playTrack(track);
                    try {
                      final state = Provider.of<AppState>(context, listen: false);
                      if (!state.musicEnabled) {
                        state.toggleMusic(true);
                      }
                    } catch (_) {}
                  },
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 12),

              // Volume slider
              Row(
                children: [
                  Icon(
                    volume > 0.0 ? Icons.volume_down_rounded : Icons.volume_mute_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  Expanded(
                    child: Slider(
                      value: volume,
                      min: 0.0,
                      max: 1.0,
                      activeColor: AppColors.antiqueGold,
                      inactiveColor: theme.dividerColor.withValues(alpha: 0.25),
                      onChanged: (val) {
                        ambience.setVolume(val);
                      },
                      onChangeEnd: (val) {
                        HapticService.instance.selection();
                      },
                    ),
                  ),
                  Text(
                    '${(volume * 100).toInt()}%',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Smart narration hint
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 13, color: AppColors.antiqueGold),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Atmospheric volume automatically ducks when the Audio Narrator reads aloud.',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 10.5,
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrackCard({
    required AmbienceTrack track,
    required bool isSelected,
    required bool isPlaying,
    required bool isDark,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.antiqueGold.withValues(alpha: isDark ? 0.18 : 0.12)
              : (isDark ? const Color(0xFF16161D) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.antiqueGold : theme.dividerColor.withValues(alpha: 0.2),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.antiqueGold.withValues(alpha: 0.2)
                    : theme.dividerColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                track.icon,
                size: 18,
                color: isSelected ? AppColors.antiqueGold : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.antiqueGold : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    track.subtitle,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isPlaying) ...[
              const Icon(Icons.graphic_eq_rounded, size: 16, color: AppColors.antiqueGold),
              const SizedBox(width: 6),
            ],
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: isSelected ? AppColors.antiqueGold : theme.dividerColor,
            ),
          ],
        ),
      ),
    );
  }
}
