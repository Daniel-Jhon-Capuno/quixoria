import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'quixote_3d_character.dart';

enum MascotPose {
  idle,         // 1. IDLE / WAITING: Relaxed pose, gentle breathing, blink, small friendly smile
  greeting,     // 2. GREETING / APP OPEN: Brightens, raises hand, friendly wave, head tilts
  walking,      // 3. WALKING: Short confident steps, arms swinging, cape bouncing
  celebration,  // 4. CORRECT ANSWER / CELEBRATION: Small jump, raises book triumphantly, happy grin
  encouraging,  // 5. INCORRECT ANSWER / ENCOURAGEMENT: Puzzled, scratches head, reassuring thumbs-up
  thinking,     // 6. THINKING / HINT: Looks upward, hand under chin, gentle nod
  reading,      // 7. READING: Sits or stands reading windmill-marked book, eyes scanning, nodding
  lessonComplete,// 8. LESSON COMPLETE: Lifts book overhead, eyes closed smile, cape settles
}

enum QuixoteExpression {
  idle,
  thinking,
  triumphant,
  encouraging,
  vigilant,
  sad,
}

/// An interactive, expressive 3D-styled animated Don Quixote companion.
/// Built directly from the official Don Quixote character turnaround and animation sheet:
/// - Floppy tan/brown hat
/// - Soft face, expressive dark eyes, large curled white mustache, short white beard
/// - Simple silver-grey medieval armor, brown gloves and boots, and burgundy cape
/// - Small brown book with windmill symbol & slim lance/spear
class QuixoteMascot extends StatefulWidget {
  final String activeBookTitle;
  final int streakDays;
  final QuixoteExpression expression;
  final MascotPose? poseOverride;
  final double size;
  final bool interactive;
  final bool showSpeechBubble;
  final String? customSpeech;
  final bool stationary;
  final bool showShadow;

  const QuixoteMascot({
    super.key,
    this.activeBookTitle = 'Quixoria',
    this.streakDays = 1,
    this.expression = QuixoteExpression.idle,
    this.poseOverride,
    this.size = 82,
    this.interactive = true,
    this.showSpeechBubble = true,
    this.customSpeech,
    this.stationary = false,
    this.showShadow = true,
  });

  @override
  State<QuixoteMascot> createState() => _QuixoteMascotState();
}

class _QuixoteMascotState extends State<QuixoteMascot> with TickerProviderStateMixin {
  late AnimationController _idleController;
  late AnimationController _blinkController;
  late AnimationController _tapBounceController;
  late AnimationController _bubbleController;

  double _dragYaw = 0.0;
  double _dragPitch = 0.0;
  bool _showBubble = true;
  int _quoteIndex = 0;

  MascotPose get currentPose {
    if (widget.poseOverride != null) return widget.poseOverride!;
    switch (widget.expression) {
      case QuixoteExpression.thinking:
        return MascotPose.thinking;
      case QuixoteExpression.triumphant:
        return MascotPose.celebration;
      case QuixoteExpression.encouraging:
        return MascotPose.encouraging;
      case QuixoteExpression.vigilant:
        return MascotPose.idle;
      case QuixoteExpression.sad:
        return MascotPose.idle;
      case QuixoteExpression.idle:
        return MascotPose.idle;
    }
  }

  List<String> get _quotes {
    if (widget.customSpeech != null) {
      return [widget.customSpeech!];
    }
    switch (currentPose) {
      case MascotPose.thinking:
        return [
          '“Ponder the motives carefully, noble scholar.”',
          '“The memory of chapters past holds the secret key!”',
          '“Steady thy gaze; true wisdom demands reflection.”',
          '“Let not tricky phrasing confound thy knightly intellect!”',
        ];
      case MascotPose.celebration:
      case MascotPose.lessonComplete:
        return [
          '“Splendid! Thy knightly stroke strikes true!”',
          '“Honor and glory to thy sharp scholarship!”',
          '“A triumph worthy of the chronicles of chivalry!”',
          '“Even Dulcinea herself would marvel at thy erudition!”',
        ];
      case MascotPose.encouraging:
        return [
          '“Valiant effort, Sir Knight! A true warrior learns from every duel.”',
          '“Steady thy lance! We shall master this trial together.”',
          '“A stumbled step is not defeat; stand resolute and press on!”',
          '“Every master of letters was once a squire in training.”',
        ];
      case MascotPose.greeting:
        return [
          '“Greetings, noble traveler! Ready to explore today’s chronicles?”',
          '“Welcome back! The path of chivalry and wisdom awaits!”',
        ];
      case MascotPose.reading:
        return [
          '“Ah, the magic of the written page! Every word opens a new kingdom.”',
          '“Quietude and wonder... the greatest treasures of an errant reader.”',
        ];
      case MascotPose.walking:
        return [
          '“Step by step, chapter by chapter, we march toward greatness!”',
          '“Onward, brave companion! The road of adventure calls!”',
        ];
      case MascotPose.idle:
        return [
          '“He who reads much and walks much, goes far and knows much. Press forward!”',
          '“Dost thou sense giants on the horizon? Nay, only grand chapters in ${widget.activeBookTitle}!”',
          '“Thy ${widget.streakDays}-day campfire burns bright! Complete today\'s quest before midnight.”',
          '“Sancho would urge us to take a siesta, but honor and glory call us to read!”',
          '“Too much sanity is madness! Dare to dream with every passage turned.”',
          '“Keep thy lance steady, noble reader. Every quest conquered awards precious gems!”',
        ];
    }
  }

  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();

    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    if (!widget.stationary) {
      _idleController.repeat(reverse: true);
    }

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _tapBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: 1.0,
    );

    if (!widget.stationary) {
      _startPeriodicBlink();
    }
  }

  @override
  void didUpdateWidget(covariant QuixoteMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stationary) {
      if (_idleController.isAnimating) _idleController.stop();
      _blinkTimer?.cancel();
      _blinkController.reset();
      _tapBounceController.reset();
    } else if (oldWidget.stationary && !widget.stationary) {
      if (!_idleController.isAnimating) _idleController.repeat(reverse: true);
      _startPeriodicBlink();
    }
  }

  void _startPeriodicBlink() {
    final binding = WidgetsBinding.instance;
    final isTest = binding.runtimeType.toString().contains('TestWidgetsFlutterBinding') ||
        binding.runtimeType.toString().contains('AutomatedTestWidgetsFlutterBinding');
    if (isTest) return; // Do not schedule recurring pending timers in automated widget tests

    _blinkTimer = Timer(Duration(milliseconds: 2200 + Random().nextInt(3000)), () {
      if (mounted) {
        _blinkController.forward().then((_) {
          if (mounted) {
            _blinkController.reverse().then((_) => _startPeriodicBlink());
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _idleController.dispose();
    _blinkController.dispose();
    _tapBounceController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.interactive) return;
    HapticFeedback.lightImpact();

    _tapBounceController.forward(from: 0.0);

    setState(() {
      _quoteIndex = (_quoteIndex + 1) % _quotes.length;
      _showBubble = true;
      if (!_bubbleController.isAnimating) {
        _bubbleController.forward(from: 0.0);
      }
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!widget.interactive) return;
    setState(() {
      _dragYaw = (_dragYaw + details.delta.dx * 0.015).clamp(-0.35, 0.35);
      _dragPitch = (_dragPitch - details.delta.dy * 0.015).clamp(-0.25, 0.25);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!widget.interactive) return;
    setState(() {
      _dragYaw = 0.0;
      _dragPitch = 0.0;
    });
  }

  CharacterPose get _mapped3DPose {
    switch (currentPose) {
      case MascotPose.idle:
        return CharacterPose.idle;
      case MascotPose.greeting:
        return CharacterPose.greeting;
      case MascotPose.walking:
        return CharacterPose.walking;
      case MascotPose.celebration:
        return CharacterPose.celebration;
      case MascotPose.encouraging:
        return CharacterPose.encouraging;
      case MascotPose.thinking:
        return CharacterPose.thinking;
      case MascotPose.reading:
        return CharacterPose.reading;
      case MascotPose.lessonComplete:
        return CharacterPose.lessonComplete;
    }
  }

  CharacterEmotion get _mapped3DEmotion {
    switch (widget.expression) {
      case QuixoteExpression.idle:
        return CharacterEmotion.happy;
      case QuixoteExpression.thinking:
        return CharacterEmotion.thinking;
      case QuixoteExpression.triumphant:
        return CharacterEmotion.excited;
      case QuixoteExpression.encouraging:
        return CharacterEmotion.encouraging;
      case QuixoteExpression.vigilant:
        return CharacterEmotion.determined;
      case QuixoteExpression.sad:
        return CharacterEmotion.sad;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _idleController,
        _blinkController,
        _tapBounceController,
        _bubbleController,
      ]),
      builder: (context, _) {
        final idle = widget.stationary ? 0.0 : _idleController.value;
        final bounce = widget.stationary ? 0.0 : _tapBounceController.value;
        final blink = widget.stationary ? 0.0 : _blinkController.value;

        // Render Volumetric 3D Chibi Don Quixote Mascot Engine
        final mascotFigure = DonQuixote3DCharacter(
          size: widget.size,
          pose: _mapped3DPose,
          emotion: _mapped3DEmotion,
          idleValue: idle,
          bounceValue: bounce,
          blinkValue: blink,
          yaw: _dragYaw,
          pitch: _dragPitch,
          showShadow: widget.showShadow && !widget.stationary,
        );

        final interactiveMascot = widget.interactive
            ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _handleTap,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                child: mascotFigure,
              )
            : mascotFigure;

        if (!widget.showSpeechBubble) {
          return interactiveMascot;
        }

        // Mascot with connected chivalric speech bubble
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Speech Bubble
            if (_showBubble)
              FadeTransition(
                opacity: _bubbleController,
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _bubbleController,
                    curve: Curves.easeOutBack,
                  ),
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.antiqueGold.withValues(alpha: 0.8),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.antiqueGold.withValues(alpha: isDark ? 0.2 : 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.record_voice_over_rounded,
                                  size: 14,
                                  color: AppColors.antiqueGold,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'DON QUIXOTE SPEAKS',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.antiqueGold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _quotes[_quoteIndex % _quotes.length],
                              style: AppTypography.bodySmall.copyWith(
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.onSurface,
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap mascot to hear more counsel',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 9.5,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            onPressed: () {
                              setState(() {
                                _showBubble = false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Character figure
            interactiveMascot,
          ],
        );
      },
    );
  }
}
