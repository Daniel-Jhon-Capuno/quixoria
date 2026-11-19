import '../../shared/widgets/blur_dissolve_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/sound_service.dart';
import '../../core/state/app_state.dart';
import '../../shared/widgets/quixote_mascot.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/loading_dialog.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;

  // Selections
  String _selectedLanguage = 'English';
  String _selectedRank = 'Squire (Ages 13-17)';
  String _selectedReadingHabit = 'Regular Reader (1-2 books / month)';
  int _dailyGoalMinutes = 15;
  final Set<String> _selectedGenres = {'Adventure & Chivalry', 'Mystery & Sleuthing'};
  String _selectedDifficulty = 'Standard Explorer (Unabridged classics with vocabulary support)';

  String? _selectedStarterBookId;

  final List<Map<String, dynamic>> _languages = [
    {
      'code': 'English',
      'name': 'English',
      'native': 'The Queen’s English',
      'flag': '🇬🇧',
      'desc': 'Unabridged classic Anglo masterworks & commentary',
    },
    {
      'code': 'Español',
      'name': 'Spanish',
      'native': 'Español',
      'flag': '🇪🇸',
      'desc': 'Lengua de Cervantes, Don Quijote y Romancero',
    },
    {
      'code': 'Français',
      'name': 'French',
      'native': 'Français',
      'flag': '🇫🇷',
      'desc': 'Victor Hugo, Alexandre Dumas et Molière',
    },
    {
      'code': 'Deutsch',
      'name': 'German',
      'native': 'Deutsch',
      'flag': '🇩🇪',
      'desc': 'Goethe, Friedrich Schiller und Franz Kafka',
    },
    {
      'code': 'Italiano',
      'name': 'Italian',
      'native': 'Italiano',
      'flag': '🇮🇹',
      'desc': 'Dante Alighieri, Petrarca e Boccaccio',
    },
    {
      'code': 'Português',
      'name': 'Portuguese',
      'native': 'Português',
      'flag': '🇵🇹',
      'desc': 'Luís de Camões, Eça de Queirós e Pessoa',
    },
    {
      'code': '日本語',
      'name': 'Japanese',
      'native': '日本語',
      'flag': '🇯🇵',
      'desc': 'Murasaki Shikibu, Natsume Sōseki & Akutagawa',
    },
    {
      'code': 'Lingua Latina',
      'name': 'Latin',
      'native': 'Lingua Latina',
      'flag': '🏛️',
      'desc': 'Sermo classicus Vergilii, Ciceronis et Ovidii',
    },
  ];

  final List<Map<String, dynamic>> _readingHabits = [
    {
      'title': 'Starting Fresh',
      'subtitle': 'I rarely read books right now, but eager to build a habit!',
      'icon': Icons.eco_rounded,
      'badge': 'Gentle Pace',
    },
    {
      'title': 'Occasional Reader',
      'subtitle': 'A few books a year when time permits or during holidays.',
      'icon': Icons.menu_book_rounded,
      'badge': 'Steady Pace',
    },
    {
      'title': 'Regular Reader',
      'subtitle': '1 to 2 books a month, seeking great classics and adventure.',
      'icon': Icons.auto_stories_rounded,
      'badge': 'Classic Pace',
    },
    {
      'title': 'Voracious Bookworm',
      'subtitle': 'A book every week or more — constantly hungry for deep lore!',
      'icon': Icons.local_fire_department_rounded,
      'badge': 'Epic Pace',
    },
  ];

  final List<Map<String, dynamic>> _ranks = [
    {
      'title': 'Page (Ages 8-12)',
      'subtitle': 'Young adventurer; gentle prose, guided vocabulary, and playful quests.',
      'icon': Icons.menu_book_rounded,
    },
    {
      'title': 'Squire (Ages 13-17)',
      'subtitle': 'Eager apprentice; classic masterworks with steady chapter pacing.',
      'icon': Icons.shield_outlined,
    },
    {
      'title': 'Knight Errant (Ages 18-30)',
      'subtitle': 'Avid explorer; unabridged epics, deep literary context, and sharp quizzes.',
      'icon': Icons.explore_rounded,
    },
    {
      'title': 'Noble Sage (Ages 31+)',
      'subtitle': 'Distinguished scholar; advanced historical nuance, archaic poetry, and philosophical depth.',
      'icon': Icons.auto_stories_rounded,
    },
  ];

  final List<Map<String, dynamic>> _goals = [
    {
      'minutes': 5,
      'title': 'Casual Reader',
      'subtitle': '5 minutes / day — 1 quick chapter or recall drill to build the habit.',
      'icon': Icons.wb_twilight_rounded,
      'bounty': '+10 Daily Gems',
    },
    {
      'minutes': 15,
      'title': 'Knightly Regular',
      'subtitle': '15 minutes / day — Recommended! Conquer full adventures without fatigue.',
      'icon': Icons.local_fire_department_rounded,
      'bounty': '+25 Daily Gems',
    },
    {
      'minutes': 30,
      'title': 'Dedicated Scholar',
      'subtitle': '30 minutes / day — Rapid quest conquest, deep vocabulary immersion.',
      'icon': Icons.workspace_premium_rounded,
      'bounty': '+50 Daily Gems',
    },
    {
      'minutes': 60,
      'title': 'Grand Champion',
      'subtitle': '60+ minutes / day — Master complete classic volumes each week.',
      'icon': Icons.military_tech_rounded,
      'bounty': '+100 Daily Gems',
    },
  ];

  final List<Map<String, dynamic>> _genres = [
    {
      'id': 'Adventure & Chivalry',
      'name': 'Adventure & Chivalry',
      'desc': 'Valiant quests, wild journeys, and noble honor (e.g. Don Quixote).',
      'icon': Icons.shield_rounded,
    },
    {
      'id': 'Mystery & Sleuthing',
      'name': 'Mystery & Sleuthing',
      'desc': 'Enigmas, Victorian clues, and deductive science (e.g. Sherlock Holmes).',
      'icon': Icons.search_rounded,
    },
    {
      'id': 'Voyages & Sci-Fi',
      'name': 'Voyages & Sci-Fi',
      'desc': 'Globe-trotting races and technological frontiers (e.g. Jules Verne).',
      'icon': Icons.public_rounded,
    },
    {
      'id': 'Romance & Society',
      'name': 'Romance & Society',
      'desc': 'Witty satire, ballroom drama, and timeless love (e.g. Jane Austen).',
      'icon': Icons.favorite_rounded,
    },
    {
      'id': 'Philosophy & Fables',
      'name': 'Philosophy & Fables',
      'desc': 'Wisdom, allegories, and moral reflection through the ages.',
      'icon': Icons.psychology_rounded,
    },
    {
      'id': 'Poetry & Lyrical Verse',
      'name': 'Poetry & Lyrical Verse',
      'desc': 'Shakespearean sonnets and emotional meter.',
      'icon': Icons.format_quote_rounded,
    },
  ];

  final List<Map<String, dynamic>> _difficulties = [
    {
      'title': 'Gentle Stroll',
      'subtitle': 'Focus on enjoyment; generous hints and instant archaic definitions.',
      'icon': Icons.directions_walk_rounded,
    },
    {
      'title': 'Standard Explorer',
      'subtitle': 'Unabridged authentic text with optional vocabulary tap-to-define lookup.',
      'icon': Icons.explore_outlined,
    },
    {
      'title': 'Master Scholar',
      'subtitle': 'Rigorous trial: uncompromising questions and historical context analysis.',
      'icon': Icons.history_edu_rounded,
    },
  ];

  List<_RecommendedBookCandidate> _getRecommendedCandidates() {
    final List<_RecommendedBookCandidate> all = [
      const _RecommendedBookCandidate(
        id: 'lit_don_quixote',
        title: 'Don Quixote de La Mancha',
        author: 'Miguel de Cervantes',
        matchPercent: 98,
        genre: 'Adventure & Chivalry',
        desc: 'Ride across the sun-drenched plains of La Mancha with Don Quixote and Sancho Panza in search of honor, giants, and justice.',
        icon: Icons.castle_rounded,
        themeColor: AppColors.antiqueGold,
      ),
      const _RecommendedBookCandidate(
        id: 'lit_study_in_scarlet',
        title: 'A Study in Scarlet',
        author: 'Sir Arthur Conan Doyle',
        matchPercent: 96,
        genre: 'Mystery & Sleuthing',
        desc: 'Meet Dr. Watson and Sherlock Holmes at 221B Baker Street as they solve a baffling murder in Victorian London through forensic deduction.',
        icon: Icons.search_rounded,
        themeColor: Color(0xFF2C3E50),
      ),
      const _RecommendedBookCandidate(
        id: 'lit_around_the_world_80_days',
        title: 'Around the World in 80 Days',
        author: 'Jules Verne',
        matchPercent: 95,
        genre: 'Voyages & Sci-Fi',
        desc: 'Join the unflappable Phileas Fogg and Passepartout on a thrilling 20,000-pound race across steamships, railways, and continents.',
        icon: Icons.public_rounded,
        themeColor: Color(0xFF1E382B),
      ),
      const _RecommendedBookCandidate(
        id: 'lit_pride_and_prejudice',
        title: 'Pride and Prejudice',
        author: 'Jane Austen',
        matchPercent: 95,
        genre: 'Romance & Society',
        desc: 'Step into the witty parlors of 19th-century England with Elizabeth Bennet and the enigmatic, proud Mr. Darcy.',
        icon: Icons.favorite_rounded,
        themeColor: Color(0xFF5D3A58),
      ),
      const _RecommendedBookCandidate(
        id: 'lit_frankenstein',
        title: 'Frankenstein',
        author: 'Mary Shelley',
        matchPercent: 94,
        genre: 'Gothic & Sci-Fi',
        desc: 'Victor Frankenstein dares to unravel the spark of life, birthing a tragic creation across glacial peaks and moral dilemmas.',
        icon: Icons.psychology_rounded,
        themeColor: Color(0xFF3B261F),
      ),
    ];

    final selectedGenresLower = _selectedGenres.map((g) => g.toLowerCase()).toSet();
    final scored = all.map((b) {
      int score = 0;
      if (selectedGenresLower.any((g) => b.genre.toLowerCase().contains(g) || g.contains(b.genre.toLowerCase()))) {
        score += 50;
      }
      return (book: b, score: score);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    final top3 = scored.take(3).map((s) => s.book).toList();

    return [
      _RecommendedBookCandidate(
        id: top3[0].id,
        title: top3[0].title,
        author: top3[0].author,
        matchPercent: 98,
        genre: top3[0].genre,
        desc: top3[0].desc,
        icon: top3[0].icon,
        themeColor: top3[0].themeColor,
      ),
      _RecommendedBookCandidate(
        id: top3[1].id,
        title: top3[1].title,
        author: top3[1].author,
        matchPercent: 95,
        genre: top3[1].genre,
        desc: top3[1].desc,
        icon: top3[1].icon,
        themeColor: top3[1].themeColor,
      ),
      _RecommendedBookCandidate(
        id: top3[2].id,
        title: top3[2].title,
        author: top3[2].author,
        matchPercent: 92,
        genre: top3[2].genre,
        desc: top3[2].desc,
        icon: top3[2].icon,
        themeColor: top3[2].themeColor,
      ),
    ];
  }

  void _nextStep() {
    HapticFeedback.lightImpact();
    SoundService.instance.play(Sfx.tap);
    if (_step < 5) {
      setState(() => _step++);
    } else if (_step == 5) {
      // Step 5 -> Step 6: Consult the Library loader
      QuixoriaLoadingDialog.show(
        context,
        title: 'Consulting the Library...',
        message: 'Matching classical masterworks to thy tastes...',
        task: Future.delayed(const Duration(milliseconds: 200)),
      ).then((_) {
        if (mounted) setState(() => _step = 6);
      });
    } else {
      final candidates = _getRecommendedCandidates();
      final chosen = candidates.firstWhere(
        (c) => c.id == _selectedStarterBookId,
        orElse: () => candidates.first,
      );
      _showStarterConfirmationDialog(chosen);
    }
  }

  void _showStarterConfirmationDialog(_RecommendedBookCandidate chosen) {
    SoundService.instance.play(Sfx.levelComplete);
    HapticFeedback.heavyImpact();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? (isDark ? const Color(0xFF1B221E) : Colors.white),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.antiqueGold, width: 2.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.antiqueGold.withValues(alpha: 0.35),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const QuixoteMascot(
                size: 96,
                poseOverride: MascotPose.celebration,
                showSpeechBubble: false,
                interactive: false,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.antiqueGold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.antiqueGold, width: 1.2),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium_rounded, size: 16, color: AppColors.antiqueGold),
                    SizedBox(width: 6),
                    Text(
                      'STARTER MASTERWORK BESTOWED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.antiqueGold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Huzzah, Valiant Scholar!',
                textAlign: TextAlign.center,
                style: AppTypography.displayMedium.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thou hast chosen "${chosen.title}" by ${chosen.author} to inaugurate thy grand quest! Thy starting bounty of +100 Radiant Gems is bestowed upon thee.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 13,
                  height: 1.45,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 20),
              DuoButton(
                text: 'Enter Quixoria & Tour Realm',
                icon: Icons.explore_rounded,
                variant: DuoButtonVariant.gold,
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  final state = context.read<AppState>();
                  state.completeOnboarding(
                    genres: _selectedGenres.toList(),
                    ageRange: _selectedRank,
                    difficulty: _selectedDifficulty,
                    dailyGoalMinutes: _dailyGoalMinutes,
                    language: _selectedLanguage,
                    readingHabit: _selectedReadingHabit,
                    startingLiteratureId: chosen.id,
                    bonusGems: 100,
                  );
                  widget.onFinish();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_step > 0) {
          HapticFeedback.lightImpact();
          SoundService.instance.play(Sfx.tap);
          setState(() => _step--);
        }
      },
      child: Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  SoundService.instance.play(Sfx.tap);
                  setState(() => _step--);
                },
              )
            : null,
        title: Text(
          'Knighthood Initiation',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(82),
          child: _SkillPathProgressStepper(
            currentStep: _step,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: BlurDissolveSwitcher(
                  key: ValueKey<int>(_step),
                  child: KeyedSubtree(
                    key: ValueKey<int>(_step),
                    child: _buildStepContent(isDark),
                  ),
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.antiqueGold,
                    foregroundColor: isDark ? const Color(0xFF121212) : theme.colorScheme.primary,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _nextStep,
                  child: Text(
                    _step == 6
                        ? 'Confirm Starter Masterwork (+100 Gems)'
                        : 'Continue',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildStepContent(bool isDark) {
    switch (_step) {
      case 0:
        return _buildLanguageStep(isDark);
      case 1:
        return _buildRankStep(isDark);
      case 2:
        return _buildHabitStep(isDark);
      case 3:
        return _buildGenresStep(isDark);
      case 4:
        return _buildDifficultyStep(isDark);
      case 5:
        return _buildGoalStep(isDark);
      case 6:
      default:
        return _buildRecommendationStep(isDark);
    }
  }

  // STEP 0: Language
  Widget _buildLanguageStep(bool isDark) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: QuixoteMascot(
            size: 96,
            poseOverride: MascotPose.greeting,
            showSpeechBubble: true,
            customSpeech: '“Halt, noble scholar! In which tongue shalt thou venture through the great literary archives?”',
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'What is Thy Preferred Language?',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Tailors classic editions, annotations, and vocabulary commentary to thy tongue.',
          style: AppTypography.bodySmall.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        ..._languages.map((lang) {
          final isSelected = _selectedLanguage == lang['code'];
          return _buildSelectableTile(
            title: '${lang["flag"]}  ${lang["name"]} (${lang["native"]})',
            subtitle: lang['desc'] as String,
            icon: Icons.language_rounded,
            isSelected: isSelected,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedLanguage = lang['code'] as String);
            },
          );
        }),
      ],
    );
  }

  // STEP 2: Habits (How much they usually read)
  Widget _buildHabitStep(bool isDark) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: QuixoteMascot(
            size: 96,
            poseOverride: MascotPose.thinking,
            showSpeechBubble: true,
            customSpeech: '“Be honest, companion! How often doth thou open a tome in thy daily life?”',
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'How Much Dost Thou Usually Read?',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Calibrate thy quest so thy habit builds steadily without fatigue or strain.',
          style: AppTypography.bodySmall.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        ..._readingHabits.map((habit) {
          final isSelected = _selectedReadingHabit.startsWith(habit['title'] as String);
          return _buildSelectableTile(
            title: habit['title'] as String,
            subtitle: habit['subtitle'] as String,
            icon: habit['icon'] as IconData,
            trailingBadge: habit['badge'] as String,
            isSelected: isSelected,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedReadingHabit = '${habit["title"]} (${habit["badge"]})');
            },
          );
        }),
      ],
    );
  }

  // STEP 1: Reader Ranking (Age & Station)
  Widget _buildRankStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: QuixoteMascot(
            size: 90,
            poseOverride: MascotPose.thinking,
            showSpeechBubble: true,
            customSpeech: '“Every knight of letters began their training at an honorable station. What is thy scholar rank?”',
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'What is thy Reader Station?',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'This helps calibrate question phrasing and vocabulary definitions.',
          style: AppTypography.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 16),
        ..._ranks.map((rank) {
          final isSelected = _selectedRank == rank['title'];
          return _buildSelectableTile(
            title: rank['title'] as String,
            subtitle: rank['subtitle'] as String,
            icon: rank['icon'] as IconData,
            isSelected: isSelected,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedRank = rank['title'] as String);
            },
          );
        }),
      ],
    );
  }

  // STEP 2: Daily Commitment (Pacing)
  Widget _buildGoalStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: QuixoteMascot(
            size: 90,
            poseOverride: MascotPose.idle,
            showSpeechBubble: true,
            customSpeech: '“A campfire maintained daily never dies out! How many minutes canst thou pledge each day?”',
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Pledge Thy Daily Reading Commitment',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'You can change thy goal at any time in thy Scholar Profile.',
          style: AppTypography.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 16),
        ..._goals.map((goal) {
          final isSelected = _dailyGoalMinutes == goal['minutes'];
          return _buildSelectableTile(
            title: goal['title'] as String,
            subtitle: goal['subtitle'] as String,
            icon: goal['icon'] as IconData,
            trailingBadge: goal['bounty'] as String,
            isSelected: isSelected,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _dailyGoalMinutes = goal['minutes'] as int);
            },
          );
        }),
      ],
    );
  }

  // STEP 3: Genres & Realms
  Widget _buildGenresStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: QuixoteMascot(
            size: 90,
            poseOverride: MascotPose.reading,
            showSpeechBubble: true,
            customSpeech: '“From dusty battlefields to London cobblestones, which realms call to thy spirit? Select all that entice thee!”',
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Choose Thy Preferred Genres',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Select at least one genre to calibrate recommendations.',
          style: AppTypography.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 16),
        ..._genres.map((genre) {
          final id = genre['id'] as String;
          final isSelected = _selectedGenres.contains(id);
          return _buildSelectableTile(
            title: genre['name'] as String,
            subtitle: genre['desc'] as String,
            icon: genre['icon'] as IconData,
            isSelected: isSelected,
            isMultiSelect: true,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                if (isSelected) {
                  if (_selectedGenres.length > 1) {
                    _selectedGenres.remove(id);
                  }
                } else {
                  _selectedGenres.add(id);
                }
              });
            },
          );
        }),
      ],
    );
  }

  // STEP 4: Difficulty & Support
  Widget _buildDifficultyStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: QuixoteMascot(
            size: 90,
            poseOverride: MascotPose.encouraging,
            showSpeechBubble: true,
            customSpeech: '“Fear not archaic prose! I shall ride beside thee with wisdom and marginalia!”',
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'How Dost Thou Prefer to Read?',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Adjusts in-text guidance, hint visibility, and assessment depth.',
          style: AppTypography.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 16),
        ..._difficulties.map((diff) {
          final isSelected = _selectedDifficulty.startsWith(diff['title'] as String);
          return _buildSelectableTile(
            title: diff['title'] as String,
            subtitle: diff['subtitle'] as String,
            icon: diff['icon'] as IconData,
            isSelected: isSelected,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedDifficulty = '${diff['title']} (${diff['subtitle']})');
            },
          );
        }),
      ],
    );
  }

  // STEP 5: Personalized Recommendations (Choose 1 of at least 3 Starter Works)
  Widget _buildRecommendationStep(bool isDark) {
    final candidates = _getRecommendedCandidates();
    _selectedStarterBookId ??= candidates.first.id;

    return Column(
      children: [
        const SizedBox(height: 8),
        const QuixoteMascot(
          size: 100,
          poseOverride: MascotPose.greeting,
          showSpeechBubble: true,
          customSpeech: '“By the windmills of La Mancha, I have examined thy scholar preferences! Here are three distinguished masterworks tailored to thy mind. Choose one to inaugurate thy legend!”',
        ),
        const SizedBox(height: 20),
        Text(
          'Choose Thy Starter Masterwork',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Select which volume shall launch thy chivalric journey. Thou canst explore all other works in the library at any time!',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),

        // 3 Tailored Book Cards
        ...candidates.map((book) {
          final isSelected = _selectedStarterBookId == book.id;
          return _buildBookCandidateCard(book, isSelected, isDark);
        }),

        const SizedBox(height: 14),

        // Starting Bounty Container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.antiqueGold, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.antiqueGold,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.diamond_rounded, color: isDark ? const Color(0xFF121212) : Theme.of(context).colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INITIATION BOUNTY: +100 GEMS',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.antiqueGold,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bestowed upon thy choice to equip thy knighthood!',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildBookCandidateCard(
    _RecommendedBookCandidate book,
    bool isSelected,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedScale(
        scale: isSelected ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: InkWell(
          onTap: () {
            SoundService.instance.play(Sfx.tap);
            HapticFeedback.lightImpact();
            setState(() {
              _selectedStarterBookId = book.id;
            });
          },
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? const Color(0xFF262C24) : const Color(0xFFFAF3E0))
                  : (theme.cardTheme.color ?? theme.colorScheme.surface),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? AppColors.antiqueGold : theme.dividerColor.withValues(alpha: 0.4),
                width: isSelected ? 2.2 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.antiqueGold.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book Icon Plate
                    Container(
                      width: 50,
                      height: 68,
                      decoration: BoxDecoration(
                        color: book.themeColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.antiqueGold, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(book.icon, color: AppColors.parchmentCream, size: 26),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Match Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.antiqueGold.withValues(alpha: isSelected ? 0.25 : 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.antiqueGold, width: 0.8),
                            ),
                            child: Text(
                              '${book.matchPercent}% MATCH • ${book.genre.toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: AppColors.antiqueGold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),

                          // Title
                          Text(
                            book.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),

                          // Author
                          Text(
                            'by ${book.author}',
                            style: AppTypography.bodySmall.copyWith(
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Radio Selection Indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppColors.antiqueGold : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? AppColors.antiqueGold : theme.dividerColor,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Center(
                              child: Icon(Icons.check_rounded, size: 16, color: Color(0xFF121212)),
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Description
                Text(
                  book.desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11.5,
                    height: 1.35,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectableTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    String? trailingBadge,
    bool isMultiSelect = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedScale(
        scale: isSelected ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        child: InkWell(
          onTap: () {
            SoundService.instance.play(Sfx.tap);
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF262A24)
                      : const Color(0xFFFAF3E0))
                  : (theme.cardTheme.color ?? theme.colorScheme.surface),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.antiqueGold : theme.dividerColor.withValues(alpha: 0.35),
                width: isSelected ? 2.2 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.antiqueGold.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.antiqueGold.withValues(alpha: 0.2)
                        : theme.dividerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? AppColors.antiqueGold : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppColors.antiqueGold : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (trailingBadge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.antiqueGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                trailingBadge,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.antiqueGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    isMultiSelect
                        ? (isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded)
                        : (isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded),
                    key: ValueKey<bool>(isSelected),
                    color: isSelected ? AppColors.antiqueGold : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommendedBookCandidate {
  final String id;
  final String title;
  final String author;
  final int matchPercent;
  final String genre;
  final String desc;
  final IconData icon;
  final Color themeColor;

  const _RecommendedBookCandidate({
    required this.id,
    required this.title,
    required this.author,
    required this.matchPercent,
    required this.genre,
    required this.desc,
    required this.icon,
    required this.themeColor,
  });
}


class _SkillPathProgressStepper extends StatefulWidget {
  final int currentStep;

  const _SkillPathProgressStepper({required this.currentStep});

  @override
  State<_SkillPathProgressStepper> createState() => _SkillPathProgressStepperState();
}

class _SkillPathProgressStepperState extends State<_SkillPathProgressStepper>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  late AnimationController _transitionController;
  late Animation<double> _transitionAnimation;
  double _lastStep = 0.0;

  static const List<String> _labels = [
    'Language',
    'Age',
    'Habits',
    'Genre',
    'Difficulty',
    'Time',
    'Tome',
  ];

  @override
  void initState() {
    super.initState();
    _lastStep = widget.currentStep.toDouble();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOutSine),
    );

    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _transitionAnimation = Tween<double>(
      begin: _lastStep,
      end: _lastStep,
    ).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void didUpdateWidget(covariant _SkillPathProgressStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      _lastStep = oldWidget.currentStep.toDouble();
      _transitionAnimation = Tween<double>(
        begin: _lastStep,
        end: widget.currentStep.toDouble(),
      ).animate(
        CurvedAnimation(parent: _transitionController, curve: Curves.easeInOutCubic),
      );
      _transitionController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeIndex = widget.currentStep.clamp(0, _labels.length - 1);

    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final stepCount = _labels.length;
          final stepSpacing = totalWidth / stepCount;

          return AnimatedBuilder(
            animation: Listenable.merge([_bounceAnimation, _transitionController]),
            builder: (context, _) {
              final animatedStep = _transitionController.isAnimating
                  ? _transitionAnimation.value
                  : activeIndex.toDouble();

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Connecting Zigzag Path Trail
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ZigzagTrailPainter(
                        stepCount: stepCount,
                        totalWidth: totalWidth,
                        activeProgress: animatedStep,
                        primaryColor: theme.colorScheme.primary,
                        isDark: isDark,
                      ),
                    ),
                  ),

                  // Round Nodes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(stepCount, (i) {
                      final isCompleted = i < activeIndex;
                      final isActive = i == activeIndex;

                      // Zigzag alternating offset: even nodes lower (-5), odd nodes higher (+5)
                      final zigzagOffsetY = (i % 2 == 0) ? -5.0 : 5.0;
                      final bounceY = isActive ? _bounceAnimation.value : 0.0;

                      return SizedBox(
                        width: stepSpacing,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Round Node with continuous bouncing animation on active
                            Transform.translate(
                              offset: Offset(0, zigzagOffsetY + bounceY),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCompleted
                                      ? theme.colorScheme.primary
                                      : (isActive
                                          ? theme.colorScheme.surface
                                          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.4 : 0.7)),
                                  border: Border.all(
                                    color: isCompleted || isActive
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outline.withValues(alpha: 0.35),
                                    width: isActive ? 2.4 : (isCompleted ? 2.0 : 1.4),
                                  ),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: theme.colorScheme.primary.withValues(alpha: 0.45),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : (isCompleted
                                          ? [
                                              BoxShadow(
                                                color: theme.colorScheme.primary.withValues(alpha: 0.25),
                                                blurRadius: 6,
                                              ),
                                            ]
                                          : []),
                                ),
                                child: Center(
                                  child: isCompleted
                                      ? Icon(
                                          Icons.check_rounded,
                                          size: 16,
                                          color: theme.colorScheme.onPrimary,
                                        )
                                      : (isActive
                                          ? Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: theme.colorScheme.primary,
                                              ),
                                            )
                                          : Text(
                                              '${i + 1}',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                                              ),
                                            )),
                                ),
                              ),
                            ),

                            const SizedBox(height: 7),

                            // Single Word Label beneath node (not a pill, just a word)
                            Text(
                              _labels[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                letterSpacing: 0.2,
                                color: isActive
                                    ? theme.colorScheme.primary
                                    : (isCompleted
                                        ? theme.colorScheme.onSurface.withValues(alpha: 0.85)
                                        : theme.colorScheme.onSurface.withValues(alpha: 0.40)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ZigzagTrailPainter extends CustomPainter {
  final int stepCount;
  final double totalWidth;
  final double activeProgress;
  final Color primaryColor;
  final bool isDark;

  const _ZigzagTrailPainter({
    required this.stepCount,
    required this.totalWidth,
    required this.activeProgress,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (stepCount <= 1) return;
    final stepSpacing = totalWidth / stepCount;

    final paintCompleted = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final paintUpcoming = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.16)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < stepCount - 1; i++) {
      final x1 = stepSpacing * (i + 0.5);
      final y1 = 14.0 + ((i % 2 == 0) ? -5.0 : 5.0);

      final x2 = stepSpacing * (i + 1.5);
      final y2 = 14.0 + (((i + 1) % 2 == 0) ? -5.0 : 5.0);

      final isEdgeCompleted = (i + 1) <= activeProgress;
      final currentPaint = isEdgeCompleted ? paintCompleted : paintUpcoming;

      // Draw subtle dotted/dashed segment
      const double dashLength = 4.0;
      const double dashSpace = 3.0;
      final double distance = (Offset(x2, y2) - Offset(x1, y1)).distance;
      final double dx = (x2 - x1) / distance;
      final double dy = (y2 - y1) / distance;

      double currentDistance = 0.0;
      while (currentDistance < distance) {
        final start = Offset(x1 + dx * currentDistance, y1 + dy * currentDistance);
        final endDistance = (currentDistance + dashLength).clamp(0.0, distance);
        final end = Offset(x1 + dx * endDistance, y1 + dy * endDistance);
        canvas.drawLine(start, end, currentPaint);
        currentDistance += dashLength + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ZigzagTrailPainter oldDelegate) {
    return oldDelegate.activeProgress != activeProgress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.isDark != isDark;
  }
}
