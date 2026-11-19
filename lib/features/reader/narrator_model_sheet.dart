import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/narration_service.dart';
import '../../core/services/neural_tts_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/state/app_state.dart';

class NarratorModelSheet extends StatelessWidget {
  const NarratorModelSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NarratorModelSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E1E26) : AppColors.parchmentWarm;

    AppState? appState;
    try {
      appState = Provider.of<AppState>(context);
    } catch (_) {}

    final hasTtsKey = appState?.hasTtsKey ?? false;
    final effectiveKey = appState?.effectiveTtsKey ?? '';
    final ttsProvider = appState?.ttsProvider ?? 'google';

    return AnimatedBuilder(
      animation: NarrationService.instance,
      builder: (context, _) {
        final narration = NarrationService.instance;
        final currentPersona = narration.persona;
        final isPlayingSample = narration.isPlaying;

        // Keep narration service synced with app state settings
        narration.configure(
          apiKey: effectiveKey,
          provider: ttsProvider,
        );

            return Container(
              padding: const EdgeInsets.only(top: 12, bottom: 28, left: 20, right: 20),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Grab handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white30 : Colors.black26),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Title Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.laManchaTerracotta.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.record_voice_over_rounded,
                          color: AppColors.laManchaTerracotta,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Natural Voice Narrators',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFFFDFBF7) : const Color(0xFF1A1C19),
                              ),
                            ),
                            Text(
                              'Studio-grade human neural voices tuned for literary immersion',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? Colors.white70 : AppColors.inkMedium,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 22),
                        color: isDark ? Colors.white70 : Colors.black54,
                        onPressed: () {
                          if (isPlayingSample) narration.stop();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Provider / Studio Connection Status Banner
                  InkWell(
                    onTap: appState != null ? () => _showVoiceKeyDialog(context, appState!) : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: hasTtsKey
                            ? (isDark ? const Color(0xFF162E20) : const Color(0xFFE8F5E9))
                            : (isDark ? const Color(0xFF2E2614) : const Color(0xFFFFF8E1)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasTtsKey ? const Color(0xFF4CAF50) : AppColors.antiqueGold,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hasTtsKey ? Icons.check_circle_rounded : Icons.vpn_key_rounded,
                            size: 18,
                            color: hasTtsKey ? const Color(0xFF4CAF50) : AppColors.antiqueGold,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasTtsKey
                                      ? (ttsProvider == 'elevenlabs'
                                          ? 'ElevenLabs Theatrical AI Active'
                                          : 'Google Cloud Studio TTS Active (1M Chars/mo Free)')
                                      : 'Connect Studio Neural Voice (1M Free Chars/Mo)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: hasTtsKey
                                        ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
                                        : (isDark ? AppColors.antiqueGold : const Color(0xFF8D6E14)),
                                  ),
                                ),
                                Text(
                                  hasTtsKey
                                      ? 'Tap to adjust provider, voice model, or API key'
                                      : 'Tap to enter free Google Cloud or ElevenLabs key for lifelike speech',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.antiqueGold),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Voice cards
                  ...NarratorPersona.values.map((persona) {
                    final isSelected = currentPersona == persona;
                    return _buildPersonaCard(
                      context: context,
                      persona: persona,
                      isSelected: isSelected,
                      isPlayingSample: isPlayingSample && isSelected,
                      isDark: isDark,
                      onSelect: () {
                        HapticService.instance.light();
                        SoundService.instance.play(Sfx.tap);
                        narration.setPersona(persona);
                      },
                      onPreview: () {
                        HapticService.instance.medium();
                        SoundService.instance.play(Sfx.tap);
                        if (!hasTtsKey && appState != null) {
                          _showVoiceKeyDialog(context, appState);
                          return;
                        }
                        narration.playSample(
                          persona,
                          effectiveKey,
                          ttsProvider,
                        );
                      },
                    );
                  }),

                  const SizedBox(height: 10),

                  // Footer info banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.antiqueGold.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.antiqueGold,
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Powered by studio neural models (Journey/Neural2 & ElevenLabs) with automatic audio byte caching.',
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.3,
                              color: isDark ? Colors.white60 : AppColors.inkMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
  }

  Widget _buildPersonaCard({
    required BuildContext context,
    required NarratorPersona persona,
    required bool isSelected,
    required bool isPlayingSample,
    required bool isDark,
    required VoidCallback onSelect,
    required VoidCallback onPreview,
  }) {
    final activeBorderColor = AppColors.laManchaTerracotta;
    final inactiveBorderColor = isDark ? Colors.white12 : Colors.black12;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onSelect,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                      ? AppColors.laManchaTerracotta.withValues(alpha: 0.16)
                      : AppColors.laManchaTerracotta.withValues(alpha: 0.08))
                  : (isDark ? const Color(0xFF262630) : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? activeBorderColor : inactiveBorderColor,
                width: isSelected ? 1.8 : 1.0,
              ),
            ),
            child: Row(
              children: [
                // Icon avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.laManchaTerracotta.withValues(alpha: 0.2)
                        : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      persona.icon,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Text(
                            persona.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isDark ? const Color(0xFFFDFBF7) : const Color(0xFF1A1C19),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.laManchaTerracotta.withValues(alpha: 0.2)
                                  : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              persona.subtitle,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppColors.laManchaTerracotta : (isDark ? Colors.white70 : Colors.black54),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        persona.description,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.25,
                          color: isDark ? Colors.white70 : AppColors.inkMedium,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Preview Sample Button
                IconButton(
                  tooltip: isPlayingSample ? 'Stop Voice Sample' : 'Play Voice Sample',
                  icon: Icon(
                    isPlayingSample ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                    color: isSelected ? AppColors.laManchaTerracotta : AppColors.antiqueGold,
                    size: 28,
                  ),
                  onPressed: isPlayingSample
                      ? () {
                          HapticService.instance.light();
                          NarrationService.instance.stop();
                        }
                      : onPreview,
                ),

                // Selection checkmark
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.laManchaTerracotta,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVoiceKeyDialog(BuildContext context, AppState state) {
    final controller = TextEditingController(text: state.ttsApiKey.isNotEmpty ? state.ttsApiKey : state.geminiApiKey);
    String selectedProvider = state.ttsProvider;
    bool isTesting = false;
    String? testResult;
    bool? testSuccess;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final theme = Theme.of(dialogCtx);
            final isDark = theme.brightness == Brightness.dark;

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E26) : AppColors.parchmentWarm,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.record_voice_over_rounded, color: AppColors.antiqueGold, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Studio Voice Setup',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose thy neural audio provider for lifelike, human-grade storytelling without robotic synthesis:',
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Provider Selector
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setDialogState(() {
                                selectedProvider = 'google';
                                testResult = null;
                                testSuccess = null;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              decoration: BoxDecoration(
                                color: selectedProvider == 'google'
                                    ? AppColors.antiqueGold.withValues(alpha: 0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selectedProvider == 'google' ? AppColors.antiqueGold : Colors.grey.withValues(alpha: 0.3),
                                  width: selectedProvider == 'google' ? 1.8 : 1.0,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.cloud_done_rounded, size: 20, color: AppColors.antiqueGold),
                                  const SizedBox(height: 4),
                                  const Text('Google Cloud', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  Text('1M chars/mo free', style: TextStyle(fontSize: 9.5, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setDialogState(() {
                                selectedProvider = 'elevenlabs';
                                testResult = null;
                                testSuccess = null;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              decoration: BoxDecoration(
                                color: selectedProvider == 'elevenlabs'
                                    ? AppColors.antiqueGold.withValues(alpha: 0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selectedProvider == 'elevenlabs' ? AppColors.antiqueGold : Colors.grey.withValues(alpha: 0.3),
                                  width: selectedProvider == 'elevenlabs' ? 1.8 : 1.0,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.theater_comedy_rounded, size: 20, color: AppColors.antiqueGold),
                                  const SizedBox(height: 4),
                                  const Text('ElevenLabs', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  Text('10k chars/mo free', style: TextStyle(fontSize: 9.5, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: controller,
                      obscureText: true,
                      style: AppTypography.bodySmall,
                      decoration: InputDecoration(
                        labelText: selectedProvider == 'elevenlabs' ? 'ElevenLabs API Key' : 'Google Cloud / Gemini Key',
                        hintText: selectedProvider == 'elevenlabs' ? 'Enter xi-api-key...' : 'AIzaSy...',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF14141B) : Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.antiqueGold, width: 1.5),
                        ),
                      ),
                    ),

                    if (testResult != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            testSuccess == true ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                            color: testSuccess == true ? const Color(0xFF4CAF50) : const Color(0xFFE57373),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              testResult!,
                              style: TextStyle(
                                fontSize: 11,
                                color: testSuccess == true ? const Color(0xFF4CAF50) : const Color(0xFFE57373),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isTesting
                      ? null
                      : () async {
                          final key = controller.text.trim();
                          if (key.isEmpty) return;
                          setDialogState(() {
                            isTesting = true;
                            testResult = null;
                            testSuccess = null;
                          });
                          final valid = await NeuralTtsService.instance.validateApiKey(key, providerId: selectedProvider);
                          setDialogState(() {
                            isTesting = false;
                            testSuccess = valid;
                            testResult = valid
                                ? 'Connection verified! Studio voice is ready.'
                                : 'Could not verify key. Check key and connection.';
                          });
                        },
                  child: isTesting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.antiqueGold),
                        )
                      : const Text('Test Key', style: TextStyle(color: AppColors.antiqueGold)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.antiqueGold,
                    foregroundColor: isDark ? const Color(0xFF14141B) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final key = controller.text.trim();
                    state.setTtsSettings(key: key, provider: selectedProvider);
                    NarrationService.instance.configure(apiKey: key, provider: selectedProvider);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(key.isNotEmpty
                            ? 'Studio voice settings saved!'
                            : 'Voice key cleared.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Save Settings'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
