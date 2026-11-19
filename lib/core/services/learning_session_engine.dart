import 'dart:math';
import '../../models/literature.dart';
import '../../models/quest_level.dart';
import '../../models/quiz_question.dart';

/// Quixoria Adaptive Learning & Session Generation Engine
/// Inspired by cognitive pedagogy and personalized learning systems.
/// Fully offline, deterministic, and 100% local (no paid external AI APIs).
class LearningSessionEngine {
  static final LearningSessionEngine instance = LearningSessionEngine._();
  LearningSessionEngine._();

  /// Assembles a personalized, difficulty-tailored set of interactive questions
  /// for a specific literature work and quest level.
  List<QuizQuestion> assembleSession({
    required Literature work,
    required QuestLevel level,
    required String difficulty,
    List<String> missedWords = const [],
  }) {
    final prefix = '${work.id}_${level.id}';
    final ch = work.chapters.isNotEmpty && level.chapterIndex < work.chapters.length
        ? work.chapters[level.chapterIndex]
        : (work.chapters.isNotEmpty
            ? work.chapters.first
            : Chapter(
                id: '${prefix}_ch',
                chapterNumber: level.chapterIndex + 1,
                title: level.title,
                content: work.description,
              ));

    // Book isolation: every word bank, distractor, and fallback sentence for this
    // session is drawn ONLY from this book's own text, so no other book's
    // context (characters, vocabulary, quotes) can ever leak into its quizzes.
    _activeBookSentences = _collectBookSentences(work, ch);
    _activeWordPool = _collectBookWordPool(_activeBookSentences);

    final titleLower = level.title.toLowerCase();
    final isClozeLevel = titleLower.contains('blank') ||
        titleLower.contains('lexicon') ||
        titleLower.contains('cloze');
    final isReorderLevel = titleLower.contains('reconstruct') ||
        titleLower.contains('scramble') ||
        titleLower.contains('syntax') ||
        titleLower.contains('word order');
    final isMatchingLevel = titleLower.contains('match') ||
        titleLower.contains('connection') ||
        titleLower.contains('pair');

    // 1. Gather or synthesize questions tailored specifically to the level's pedagogical purpose
    List<QuizQuestion> questions = [];
    if (isClozeLevel) {
      questions = _generateMultipleClozeExercises(work, ch, level, prefix, 5);
    } else if (isReorderLevel) {
      questions = _generateMultipleReorderExercises(work, ch, level, prefix, 5);
    } else if (isMatchingLevel) {
      questions = _generateMultipleMatchingExercises(work, ch, level, prefix, 5);
    } else if (level.customQuestions != null && level.customQuestions!.isNotEmpty) {
      questions = List.from(level.customQuestions!);
    } else if (level.type == LevelType.recall) {
      final recallList = work.recallQuizzes[level.chapterIndex];
      questions = (recallList != null && recallList.isNotEmpty)
          ? List.from(recallList)
          : _generateRecallQuestions(work, ch, level, prefix, 5);
    } else if (level.type == LevelType.practice) {
      final practiceList = work.practiceQuizzes[level.chapterIndex];
      questions = (practiceList != null && practiceList.isNotEmpty)
          ? List.from(practiceList)
          : _generateMultipleClozeExercises(work, ch, level, prefix, 5);
    } else if (level.type == LevelType.finalTest) {
      questions = work.finalExam.isNotEmpty
          ? List.from(work.finalExam)
          : _generateFinalExamQuestions(work, ch, level, prefix, 6);
    } else {
      questions = _generateInteractiveBookExercises(work, ch, level, prefix);
    }

    // Interleave interactive exercises (Cloze, Reorder, Matching, Roleplay) if session is purely multiple choice
    if (!isClozeLevel && !isReorderLevel && !isMatchingLevel && questions.every((q) => q.type == QuizType.multipleChoice)) {
      final interactiveQuestions = _generateInteractiveBookExercises(work, ch, level, prefix);
      final merged = <QuizQuestion>[];
      int mcIdx = 0;
      int intIdx = 0;
      while (mcIdx < questions.length || intIdx < interactiveQuestions.length) {
        if (mcIdx < questions.length) {
          merged.add(questions[mcIdx++]);
        }
        if (intIdx < interactiveQuestions.length) {
          merged.add(interactiveQuestions[intIdx++]);
        }
      }
      questions = merged;
    }

    // 2. Ensure minimum question count (at least 5 questions per level)
    if (questions.length < 5) {
      final fillers = _generateInteractiveBookExercises(work, ch, level, prefix);
      for (final f in fillers) {
        if (!questions.any((q) => q.prompt == f.prompt) && questions.length < 5) {
          questions.add(f);
        }
      }
    }

    // 3. Spaced-Repetition Feedback (Duolingo Birdbrain model):
    // Prioritize words missed by player in past readings or Word Bank reviews into the session.
    // Only words that genuinely appear in THIS book's text are eligible, and the
    // cloze sentence is the book's own sentence containing that word.
    final srMatch = missedWords.isEmpty ? null : _findMissedWordInBook(missedWords);
    if (srMatch != null && !questions.any((q) => q.id.contains('_sr_'))) {
      final targetMissed = srMatch.word;
      final srQuestion = QuizQuestion(
        id: '${prefix}_sr_${targetMissed.hashCode}',
        type: QuizType.cloze,
        prompt: 'Spaced-Repetition Feedback: Fill in thy previously challenged vocabulary word in "${work.title}":',
        clozeSentence: srMatch.sentence.replaceFirst(
          RegExp('\\b${RegExp.escape(targetMissed)}\\b', caseSensitive: false),
          '________',
        ),
        targetWord: targetMissed,
        wordBank: [targetMissed, ..._generateDistractors(targetMissed)]..shuffle(Random(targetMissed.hashCode)),
        explanation: 'Reinforcing "$targetMissed": Words missed in past readings or Word Bank reviews are dynamically reinforced for long-term memory.',
        contextHint: difficulty.toLowerCase().contains('gentle') || difficulty.toLowerCase().contains('page')
            ? 'This word was recently due in thy personal Word Bank.'
            : null,
      );
      questions.insert(min(1, questions.length), srQuestion);
    }

    // 4. Adapt questions to the user's chosen difficulty
    return questions.map((q) => _adaptQuestionToDifficulty(q, difficulty, missedWords)).toList();
  }

  /// Tailors an individual exercise based on user's selected difficulty:
  /// - "Gentle Stroll": fewer distractors, generous hint provided
  /// - "Standard Explorer": authentic balanced options and standard hints
  /// - "Master Scholar": harder near-synonyms, nuanced subtext, no hint shortcuts
  QuizQuestion _adaptQuestionToDifficulty(QuizQuestion q, String difficulty, List<String> missedWords) {
    final isGentle = difficulty.toLowerCase().contains('gentle') || difficulty.toLowerCase().contains('page');
    final isScholar = difficulty.toLowerCase().contains('scholar') || difficulty.toLowerCase().contains('sage');

    if (q.type == QuizType.cloze) {
      var bank = List<String>.from(q.wordBank ?? []);
      if (isGentle && bank.length > 3) {
        // Keep correct word and reduce distractors to 2
        final correct = q.targetWord ?? bank.first;
        final others = bank.where((w) => w.toLowerCase() != correct.toLowerCase()).take(2).toList();
        bank = [correct, ...others]..shuffle(Random(q.id.hashCode));
      } else if (isScholar && bank.length < 5) {
        // In scholar mode, add advanced distractors
        final extraDistractors = _getScholarDistractors(q.targetWord ?? 'truth');
        bank = {...bank, ...extraDistractors}.toList();
      }

      return QuizQuestion(
        id: q.id,
        prompt: q.prompt,
        type: q.type,
        clozeSentence: q.clozeSentence,
        targetWord: q.targetWord,
        wordBank: bank,
        explanation: q.explanation,
        contextHint: isGentle ? (q.contextHint ?? 'Reflect on the emotional tone of the passage.') : null,
      );
    }

    if (q.type == QuizType.multipleChoice) {
      if (isGentle && q.options.length > 3) {
        // Provide 3 choices instead of 4 for gentle stroll
        final correct = q.options[q.correctAnswerIndex];
        final others = q.options.where((opt) => opt != correct).take(2).toList();
        final newOptions = [correct, ...others]..shuffle(Random(q.id.hashCode));
        final newCorrectIdx = newOptions.indexOf(correct);

        return QuizQuestion(
          id: q.id,
          prompt: q.prompt,
          options: newOptions,
          correctAnswerIndex: newCorrectIdx,
          explanation: q.explanation,
          type: q.type,
          contextHint: q.contextHint ?? 'Look for the most humane, authentic choice.',
        );
      }
    }

    return q;
  }

  /// Synthesizes book-specific interactive questions (Cloze, Reorder, Matching, Roleplay)
  List<QuizQuestion> _generateInteractiveBookExercises(
    Literature work,
    Chapter ch,
    QuestLevel level,
    String prefix,
  ) {
    final questions = <QuizQuestion>[];
    final quote = ch.quoteHighlight ??
        (_activeBookSentences.isNotEmpty ? _activeBookSentences.first : work.description);
    final cleanQuote = quote.replaceAll('"', '').trim();

    // 1. Fill-in-the-Blank (Cloze) Exercise
    final clozeData = _extractClozePassage(cleanQuote, ch.content, work.title);
    questions.add(
      QuizQuestion(
        id: '${prefix}_cloze',
        type: QuizType.cloze,
        prompt: 'Fill in the missing word from this passage in "${work.title}":',
        clozeSentence: clozeData.sentence,
        targetWord: clozeData.targetWord,
        wordBank: clozeData.wordBank,
        explanation: 'In "${work.title}", ${work.author} writes: "${clozeData.original}".',
        contextHint: 'The missing word reflects the core emotion or object in the scene.',
      ),
    );

    // 2. Quote Ordering (Sentence Scramble) Exercise
    final quoteTokens = _extractQuoteTokens(cleanQuote);
    if (quoteTokens.length >= 4 && quoteTokens.length <= 10) {
      final shuffled = List<String>.from(quoteTokens)..shuffle(Random(prefix.hashCode));
      questions.add(
        QuizQuestion(
          id: '${prefix}_reorder',
          type: QuizType.reorder,
          prompt: 'Assemble the words in order to reconstruct this passage from "${work.title}":',
          orderedTokens: quoteTokens,
          wordBank: shuffled,
          explanation: 'Passage reconstructed: "$cleanQuote" — ${work.author}',
          contextHint: 'Start with the capitalized beginning word.',
        ),
      );
    }

    // 3. Matching Pairs Exercise
    final matchingPairs = _buildBookMatchingPairs(work, ch);
    questions.add(
      QuizQuestion(
        id: '${prefix}_matching',
        type: QuizType.matching,
        prompt: 'Match each literary element from "${work.title}" with its true counterpart:',
        matchingPairs: matchingPairs,
        explanation: 'All elements correctly paired: each term represents an essential motif in ${work.title}.',
      ),
    );

    // 4. In-Character Roleplay / Dialogue Dilemma
    final roleplay = _buildBookRoleplayDilemma(work, ch);
    questions.add(
      QuizQuestion(
        id: '${prefix}_roleplay',
        type: QuizType.roleplay,
        characterSpeaker: roleplay.speaker,
        prompt: roleplay.prompt,
        options: roleplay.options,
        correctAnswerIndex: roleplay.correctIndex,
        explanation: roleplay.explanation,
        contextHint: 'Choose the response that honors chivalric wisdom and literary authenticity.',
      ),
    );

    return questions;
  }

  /// Extracts a suitable sentence and blanks out a key literary word
  _ClozeResult _extractClozePassage(String quote, String content, String title) {
    String source = quote;
    if (source.split(' ').length < 5 && content.isNotEmpty) {
      // Pick first non-empty sentence from content
      final sentences = content.split(RegExp(r'(?<=[.!?])\s+'));
      if (sentences.isNotEmpty) source = sentences.first.trim();
    }

    final words = source.replaceAll(RegExp(r'[,.!?";:]'), '').split(' ');
    // Pick an impactful word (length >= 4) that isn't a common stopword
    const stopWords = {'the', 'and', 'that', 'with', 'from', 'this', 'were', 'have', 'been', 'there', 'what', 'when'};
    String chosen = 'madness';
    for (final w in words.reversed) {
      if (w.length >= 4 && !stopWords.contains(w.toLowerCase())) {
        chosen = w;
        break;
      }
    }

    final blanked = source.replaceFirst(chosen, '________');
    final distractors = _generateDistractors(chosen);
    final bank = [chosen, ...distractors]..shuffle(Random(title.hashCode));

    return _ClozeResult(
      sentence: blanked,
      targetWord: chosen,
      wordBank: bank,
      original: source,
    );
  }

  /// Splits a quote into word tokens suitable for reordering
  List<String> _extractQuoteTokens(String quote) {
    // Keep quotes up to 8 tokens for enjoyable mobile puzzle interaction
    final tokens = quote.replaceAll(RegExp(r'[,.!?"—;]'), '').split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.length > 8) {
      return tokens.sublist(0, 8);
    }
    return tokens;
  }

  /// Builds 4 matching pairs tailored to the book
  Map<String, String> _buildBookMatchingPairs(Literature work, Chapter ch) {
    final title = work.title.toLowerCase();
    if (title.contains('quixote')) {
      return {
        'Rocinante': 'The faithful, weary steed of La Mancha',
        'Sancho Panza': 'The pragmatic, loyal squire of proverbs',
        'Dulcinea': 'The idealized peerless lady of devotion',
        'Windmills': 'Perceived monstrous giants to be jousted',
      };
    }
    if (title.contains('prophet') || title.contains('gibran')) {
      return {
        'Almustafa': 'The chosen and beloved sage preparing to sail home',
        'Orphalese': 'The coastal city where the prophet dwelt for twelve years',
        'Almitra': 'The seeress who first steps forward to ask of love',
        'The Ship': 'The vessel arriving with mist to bear him across the sea',
      };
    }
    if (title.contains('secret garden')) {
      return {
        'Ayah': 'Traditional Indian nursemaid who cared for Mary',
        'Robin Redbreast': 'The friendly bird guide who unearths the key',
        'Misselthwaite': 'The gloomy, hundred-room Yorkshire manor',
        'The Brass Key': 'Ten-year buried relic opening the ivy door',
      };
    }
    if (title.contains('willows')) {
      return {
        'Mole': 'Gentle homebody who abandons spring cleaning',
        'Ratty': 'Water-loving poet and hospitable river dweller',
        'Toad': 'Impulsive, wealthy owner of Toad Hall obsessed with fads',
        'Wild Wood': 'Mysterious forest beyond the peaceful riverbank',
      };
    }
    if (title.contains('scarlet') || title.contains('holmes')) {
      return {
        '221B Baker St': 'Famous London rooms of Sherlock Holmes and Watson',
        'Deduction': 'Scientific observation of seemingly trivial details',
        'John Watson': 'Injured army surgeon chronicling the investigations',
        'Scotland Yard': 'Official London police seeking consulting advice',
      };
    }
    if (title.contains('frankenstein')) {
      return {
        'Victor': 'Obsessed Genevan student seeking secrets of vitality',
        'The Creature': 'Lonely, articulate creation rejected by mankind',
        'Ingolstadt': 'University city where the vital spark was ignited',
        'Arctic Ice': 'Desolate frozen expanse of the final chase',
      };
    }
    if (title.contains('pride and prejudice')) {
      return {
        'Elizabeth': 'Independent second sister quick in wit and discernment',
        'Mr. Darcy': 'Wealthy gentleman misunderstood for reserved pride',
        'Pemberley': 'The grand, elegant Derbyshire estate',
        'Longbourn': 'The noisy, modest Bennet family home',
      };
    }
    if (title.contains('80 days') || title.contains('fogg') || title.contains('around the world')) {
      return {
        'Phileas Fogg': 'Punctual gentleman wagering on global transit',
        'Passepartout': 'Loyal acrobatic valet accompanying the voyage',
        'Detective Fix': 'Persistent inspector trailing the traveler',
        'Reform Club': 'Stately London gentlemen\'s club of the wager',
      };
    }
    if (title.contains('time machine')) {
      return {
        'The Time Traveller': 'Victorian philosophical inventor of time transit',
        'Eloi': 'Fragile, peaceful daytime surface dwellers',
        'Morlocks': 'Subterranean ape-like machine tenders',
        'The White Sphinx': 'Hollow bronze monument concealing the machine',
      };
    }
    if (title.contains('alice') || title.contains('wonderland')) {
      return {
        'White Rabbit': 'Anxious herald with waistcoat and pocket watch',
        'Cheshire Cat': 'Grinning philosopher who vanishes at will',
        'Mad Hatter': 'Perpetual tea party host trapped at six o\'clock',
        'Queen of Hearts': 'Tyrannical monarch demanding swift beheadings',
      };
    }
    if (title.contains('dracula') || title.contains('stoker')) {
      return {
        'Jonathan Harker': 'Solicitor entrapped in the Transylvanian castle',
        'Count Dracula': 'Ancient nobleman commanding the night shadows',
        'Van Helsing': 'Philosopher-physician skilled in occult lore',
        'Mina Harker': 'Intellectual heroine whose diaries guide the hunt',
      };
    }
    if (title.contains('moby') || title.contains('melville')) {
      return {
        'Captain Ahab': 'Monomaniacal master of the Pequod',
        'Ishmael': 'Sole surviving narrator of the whale hunt',
        'Queequeg': 'Noble tattooed harpooneer and loyal friend',
        'Moby Dick': 'The legendary white albino leviathan',
      };
    }
    if (title.contains('monte cristo') || title.contains('dumas')) {
      return {
        'Edmond Dantès': 'Betrayed young sailor seeking restorative justice',
        'Abbé Faria': 'Wise Italian priest and mentor in the dungeon',
        'Château d\'If': 'Grim island fortress prison of despair',
        'Monte Cristo': 'Italian islet concealing unfathomable treasure',
      };
    }
    if (title.contains('odyssey') || title.contains('homer')) {
      return {
        'Odysseus': 'Cunning king enduring a ten-year voyage home',
        'Penelope': 'Faithful queen weaving and unweaving by night',
        'Telemachus': 'Dutiful son searching the seas for his father',
        'Polyphemus': 'One-eyed giant son of Poseidon',
      };
    }

    // Default book-derived pairs
    return {
      work.author: 'Master creator and author of this narrative',
      ch.title: 'Opening pivotal chapter introducing the world',
      work.genres.first: 'Primary literary classification of this journey',
      'The Conflict': 'The catalytic tension sparking the characters\' choices',
    };
  }

  /// Builds in-character roleplay dilemma
  _RoleplayResult _buildBookRoleplayDilemma(Literature work, Chapter ch) {
    final title = work.title.toLowerCase();
    if (title.contains('quixote')) {
      return _RoleplayResult(
        speaker: 'Don Quixote de la Mancha',
        prompt: 'Don Quixote points his lance toward the horizon: “Friend, see you those thirty or more monstrous giants? With them I intend to do battle!” How dost thou answer thy master?',
        options: [
          '“Look well, Señor! Those are not giants, but windmills whose arms are driven by the wind.”',
          '“Indeed, let us flee immediately back to the village!”',
          '“Charge them without looking, noble knight!”',
          '“Sell their arms in the marketplace for silver.”',
        ],
        correctIndex: 0,
        explanation: 'Sancho Panza pragmatically reminds the knight of physical reality, grounding the chivalric illusion in authentic humanity.',
      );
    }

    if (title.contains('prophet') || title.contains('gibran')) {
      return _RoleplayResult(
        speaker: 'Almustafa the Prophet',
        prompt: 'The people of Orphalese gather at the ship and plead: “Speak to us of Love.” How does the prophet counsel their hearts?',
        options: [
          '“When love beckons to you, follow him, though his ways are hard and steep; for love crowns you, even as he crucifies you.”',
          '“Avoid love at all costs, for it causes discomfort.”',
          '“Love is merely an illusion manufactured by merchants.”',
          '“Demand wealth before granting thy affection.”',
        ],
        correctIndex: 0,
        explanation: 'Kahlil Gibran portrays love as a profound spiritual fire that refines and matures the human spirit through sacrifice.',
      );
    }

    if (title.contains('secret garden')) {
      return _RoleplayResult(
        speaker: 'Mary Lennox',
        prompt: 'Mary stomps her foot at the unfamiliar servant: “Send my Ayah to me at once! Why did you dare come in her place?” As an onlooker in the compound, what dost thou discern?',
        options: [
          'Beneath her tyrannical pride lies a deeply neglected, lonely child bewildered by sudden abandonment.',
          'She is merely greedy and desires breakfast.',
          'She is a wicked tyrant beyond all redemption.',
          'She desires to study mathematics in the library.',
        ],
        correctIndex: 0,
        explanation: 'Burnett portrays Mary’s haughtiness not as innate malice, but as the defensive shell of an unloved child.',
      );
    }

    if (title.contains('scarlet') || title.contains('holmes')) {
      return _RoleplayResult(
        speaker: 'Sherlock Holmes',
        prompt: 'Holmes glances once at Watson and murmurs: “You have been in Afghanistan, I perceive.” How does Holmes justify this deduction?',
        options: [
          'By linking Watson\'s military air, sun-darkened face, pale wrists, and stiff left arm wounded in action.',
          'He read Watson\'s private diary while he was sleeping.',
          'A mutual acquaintance told him before Watson arrived.',
          'It was purely a wild, lucky guess with no evidence.',
        ],
        correctIndex: 0,
        explanation: 'Holmes applies forensic observation and logical elimination, demonstrating the core science of deduction.',
      );
    }

    if (title.contains('frankenstein')) {
      return _RoleplayResult(
        speaker: 'Victor Frankenstein',
        prompt: 'Victor beholds the yellow eye open on the creature: “Breathless horror and disgust filled my heart. I rushed out of the room.” What moral failing seals Victor\'s tragedy here?',
        options: [
          'Fleeing in terror and abandoning moral accountability for the newly created life.',
          'Using the wrong electric voltage during the experiment.',
          'Failing to invite the university faculty to witness the event.',
          'Selecting an overly tall anatomical structure.',
        ],
        correctIndex: 0,
        explanation: 'Shelley illustrates that the true monster is created when the creator repudiates parental and ethical responsibility.',
      );
    }

    if (title.contains('pride and prejudice')) {
      return _RoleplayResult(
        speaker: 'Elizabeth Bennet',
        prompt: 'Mr. Darcy observes Elizabeth at the assembly and mutters coldly: “She is tolerable, but not handsome enough to tempt me.” How does Elizabeth address this insult?',
        options: [
          'She laughs merrily and relates the story to her friends with humorous irony.',
          'She bursts into tears and leaves the ballroom immediately.',
          'She demands a duel of pistols from Mr. Bingley.',
          'She begs Mr. Darcy to reconsider her beauty.',
        ],
        correctIndex: 0,
        explanation: 'Elizabeth guards her dignity through spirited humor and independent self-respect, refusing to be demeaned.',
      );
    }

    if (title.contains('80 days') || title.contains('fogg') || title.contains('around the world')) {
      return _RoleplayResult(
        speaker: 'Phileas Fogg',
        prompt: 'At the Reform Club, the gentlemen argue that traveling the world in eighty days leaves zero margin for error. How does Fogg reply?',
        options: [
          '“A true Englishman doesn\'t joke when talking about a wager. The unforeseen does not exist when mathematically planned.”',
          '“I shall hire a balloon and fly above all clouds.”',
          '“If I miss a train, I will simply give up and return home.”',
          '“I will bribe the sea captains to double their speed.”',
        ],
        correctIndex: 0,
        explanation: 'Fogg exemplifies absolute calm, mathematical precision, and chivalric dedication to his given word.',
      );
    }

    if (title.contains('time machine')) {
      return _RoleplayResult(
        speaker: 'The Time Traveller',
        prompt: 'Observing the childlike, frail Eloi living peacefully above the sinister Morlocks, the Time Traveller concludes: “Strength is the outcome of need.” What societal truth is revealed?',
        options: [
          'An elite class that eliminates all struggle and labor inevitably decays into physical and intellectual helplessness.',
          'Machines will eventually learn to cook delicious fruit.',
          'Subterranean living is healthier than surface air.',
          'Humanity will evolve into giant aquatic lizards.',
        ],
        correctIndex: 0,
        explanation: 'Wells delivers a cautionary critique of social stratification and the consequences of unchallenged complacency.',
      );
    }

    if (title.contains('alice') || title.contains('wonderland')) {
      return _RoleplayResult(
        speaker: 'The Cheshire Cat',
        prompt: 'Alice asks the grinning Cat perched on a bough: “Would you tell me, please, which way I ought to go from here?” The Cat replies: “That depends a good deal on where you want to get to.” What is the philosophical core?',
        options: [
          'If you do not care where you are heading, any direction is as good as another.',
          'Every cat knows the shortest path through the forest.',
          'You must always turn left when lost in a labyrinth.',
          'Maps are completely useless without a pocket watch.',
        ],
        correctIndex: 0,
        explanation: 'Lewis Carroll uses paradoxical wit to teach that action without intention lacks all meaning.',
      );
    }

    if (title.contains('monte cristo') || title.contains('dumas')) {
      return _RoleplayResult(
        speaker: 'Edmond Dantès',
        prompt: 'Imprisoned in the Château d\'If, Abbé Faria counsels Edmond: “Learning does not make one learned: there are those who have knowledge and those who have understanding.” What virtue must Edmond foster?',
        options: [
          'Patience and moral understanding, so knowledge becomes wisdom rather than blind vengeance.',
          'Digging multiple escape tunnels simultaneously.',
          'Memorizing the guards\' meal schedule.',
          'Refusing food until a judge arrives.',
        ],
        correctIndex: 0,
        explanation: 'Faria transforms Edmond from a bitter prisoner into a master scholar of patience, ethics, and willpower.',
      );
    }

    // Default Universal Literary Dilemma
    final protagonist = work.author.isNotEmpty ? '${work.author}’s Protagonist' : 'The Literary Narrator';
    return _RoleplayResult(
      speaker: protagonist,
      prompt: 'In this pivotal passage of "${work.title}", the text contemplates: “${ch.quoteHighlight ?? 'To understand human nature, one must observe how character responds to adversity.'}” What chivalric truth is revealed?',
      options: [
        'Virtue and resilience in adversity define true nobility of character.',
        'Material wealth is the sole determinant of human happiness.',
        'Fate relieves mortals of all moral responsibility.',
        'Adversity should be avoided at all costs.',
      ],
      correctIndex: 0,
      explanation: 'Great classical literature explores the triumph of integrity and moral courage over circumstance.',
    );
  }

  // ---------------------------------------------------------------------------
  // Book-isolated content pools (rebuilt at the start of every session)
  // ---------------------------------------------------------------------------

  List<String> _activeBookSentences = const [];
  List<String> _activeWordPool = const [];

  static const Set<String> _poolStopWords = {
    'the', 'and', 'that', 'with', 'from', 'this', 'were', 'have', 'been', 'there',
    'what', 'when', 'which', 'their', 'could', 'would', 'should', 'about', 'these',
    'those', 'into', 'upon', 'than', 'then', 'them', 'they', 'your', 'yours', 'shall',
    'while', 'where', 'whom', 'whose', 'being', 'after', 'before', 'every', 'other',
    'such', 'some', 'very', 'only', 'also', 'even', 'though', 'through', 'because',
  };

  /// Sentences from the current chapter first, then the rest of the same book.
  List<String> _collectBookSentences(Literature work, Chapter ch) {
    final ordered = <String>[ch.content, ...work.chapters.where((c) => c.id != ch.id).map((c) => c.content), work.description];
    final seen = <String>{};
    final result = <String>[];
    for (final text in ordered) {
      for (final s in text.split(RegExp(r'(?<=[.!?])\s+'))) {
        final t = s.trim();
        if (t.length > 20 && t.split(' ').length >= 5 && seen.add(t)) result.add(t);
      }
    }
    return result;
  }

  /// Distinct, meaningful words that actually occur in this book.
  List<String> _collectBookWordPool(List<String> sentences) {
    final seen = <String>{};
    final pool = <String>[];
    for (final s in sentences) {
      for (final raw in s.split(RegExp(r'\s+'))) {
        final w = raw.replaceAll(RegExp(r"[^A-Za-z'\-]"), '');
        final lower = w.toLowerCase();
        if (w.length >= 5 && !_poolStopWords.contains(lower) && seen.add(lower)) pool.add(w);
      }
    }
    return pool;
  }

  /// Returns the first missed word that genuinely appears in this book, together
  /// with the book's own sentence containing it. Words from other books are ignored.
  ({String word, String sentence})? _findMissedWordInBook(List<String> missedWords) {
    for (final word in missedWords) {
      final trimmed = word.trim();
      if (trimmed.isEmpty) continue;
      final pattern = RegExp('\\b${RegExp.escape(trimmed)}\\b', caseSensitive: false);
      for (final s in _activeBookSentences) {
        if (pattern.hasMatch(s)) return (word: trimmed, sentence: s);
      }
    }
    return null;
  }

  /// Distractors drawn from the same book's vocabulary (similar length first),
  /// with neutral, book-agnostic words used only if the book text is too short.
  List<String> _generateDistractors(String target, {int count = 3}) {
    final t = target.toLowerCase();
    final candidates = _activeWordPool.where((w) => w.toLowerCase() != t).toList()
      ..sort((a, b) => (a.length - target.length).abs().compareTo((b.length - target.length).abs()));
    final picked = <String>[];
    // Rotate deterministically so different targets get different distractors.
    final window = candidates.take(12).toList()..shuffle(Random(t.hashCode));
    for (final w in window) {
      if (picked.length >= count) break;
      if (!picked.any((p) => p.toLowerCase() == w.toLowerCase())) picked.add(w);
    }
    const neutral = ['silence', 'morning', 'distance', 'promise', 'courage', 'reason', 'season'];
    for (final n in neutral) {
      if (picked.length >= count) break;
      if (n != t && !picked.contains(n)) picked.add(n);
    }
    return picked;
  }

  List<String> _getScholarDistractors(String target) {
    // Longer words from the same book act as harder, context-plausible distractors.
    final t = target.toLowerCase();
    final hard = _activeWordPool.where((w) => w.length >= 8 && w.toLowerCase() != t).toList()
      ..shuffle(Random(t.hashCode ^ 0x5eed));
    if (hard.length >= 2) return hard.take(2).toList();
    return ['veracity', 'transcendence'].where((w) => w != t).toList();
  }

  /// Synthesizes multiple distinct Fill-in-the-Blank exercises for a level
  List<QuizQuestion> _generateMultipleClozeExercises(
    Literature work,
    Chapter ch,
    QuestLevel level,
    String prefix,
    int count,
  ) {
    final passages = _extractMultipleClozePassages(ch.content, ch.quoteHighlight ?? '', work.title, count);
    final questions = <QuizQuestion>[];
    for (int i = 0; i < passages.length; i++) {
      final p = passages[i];
      questions.add(
        QuizQuestion(
          id: '${prefix}_cloze_$i',
          type: QuizType.cloze,
          prompt: 'Exercise ${i + 1} of ${passages.length}: Deduce the missing word from "${ch.title}":',
          clozeSentence: p.sentence,
          targetWord: p.targetWord,
          wordBank: p.wordBank,
          explanation: 'In "${work.title}" (${ch.title}), the passage reads: "${p.original}".',
          contextHint: 'Look at the sentence context and parts of speech surrounding the blank.',
        ),
      );
    }
    return questions;
  }

  /// Synthesizes multiple distinct Quote Reconstruction exercises for a level
  List<QuizQuestion> _generateMultipleReorderExercises(
    Literature work,
    Chapter ch,
    QuestLevel level,
    String prefix,
    int count,
  ) {
    final tokenSets = _extractMultipleReorderTokens(ch.content, ch.quoteHighlight ?? '', count);
    final questions = <QuizQuestion>[];
    for (int i = 0; i < tokenSets.length; i++) {
      final tokens = tokenSets[i];
      final shuffled = List<String>.from(tokens)..shuffle(Random('${prefix}_$i'.hashCode));
      final assembled = tokens.join(' ');
      questions.add(
        QuizQuestion(
          id: '${prefix}_reorder_$i',
          type: QuizType.reorder,
          prompt: 'Exercise ${i + 1} of ${tokenSets.length}: Assemble these words in syntactical order from "${ch.title}":',
          orderedTokens: tokens,
          wordBank: shuffled,
          explanation: 'Passage reconstructed: "$assembled" — ${work.author}',
          contextHint: 'Identify the subject and verb to anchor the sentence clause.',
        ),
      );
    }
    return questions;
  }

  /// Synthesizes matching pair exercises for a level
  List<QuizQuestion> _generateMultipleMatchingExercises(
    Literature work,
    Chapter ch,
    QuestLevel level,
    String prefix,
    int count,
  ) {
    final basePairs = _buildBookMatchingPairs(work, ch);
    final questions = <QuizQuestion>[];

    questions.add(
      QuizQuestion(
        id: '${prefix}_matching_1',
        type: QuizType.matching,
        prompt: 'Exercise 1: Match each central element from "${work.title}" with its true significance:',
        matchingPairs: basePairs,
        explanation: 'All elements correctly paired: each term represents an essential theme in ${work.title}.',
      ),
    );

    final vocabPairs = _buildChapterVocabPairs(work, ch);
    questions.add(
      QuizQuestion(
        id: '${prefix}_matching_2',
        type: QuizType.matching,
        prompt: 'Exercise 2: Match each literary term with its meaning in "${ch.title}":',
        matchingPairs: vocabPairs,
        explanation: 'Vocabulary mastered: understanding these classical terms unlocks the author\'s subtext.',
      ),
    );

    // If more questions needed to meet count, supplement with recall comprehension
    final recallFillers = _generateRecallQuestions(work, ch, level, prefix, count - questions.length);
    for (final rf in recallFillers) {
      if (questions.length < count) {
        questions.add(rf);
      }
    }

    return questions;
  }

  /// Extracts multiple distinct cloze sentences from text
  List<_ClozeResult> _extractMultipleClozePassages(String content, String quote, String title, int count) {
    final results = <_ClozeResult>[];
    final sentences = content
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where((s) => s.length > 20 && s.split(' ').length >= 5)
        .toList();
    if (quote.isNotEmpty && !sentences.contains(quote)) {
      sentences.insert(0, quote);
    }

    const stopWords = {
      'the', 'and', 'that', 'with', 'from', 'this', 'were', 'have', 'been', 'there',
      'what', 'when', 'which', 'their', 'could', 'would', 'should', 'about', 'these'
    };

    int sIdx = 0;
    while (results.length < count && sIdx < sentences.length) {
      final sentence = sentences[sIdx++];
      final words = sentence.replaceAll(RegExp(r'[,.!?";:]'), '').split(' ');
      String? chosen;
      for (final w in words.reversed) {
        if (w.length >= 4 && !stopWords.contains(w.toLowerCase())) {
          chosen = w;
          break;
        }
      }
      if (chosen != null && !results.any((r) => r.targetWord.toLowerCase() == chosen!.toLowerCase())) {
        final blanked = sentence.replaceFirst(chosen, '________');
        final distractors = _generateDistractors(chosen);
        final bank = [chosen, ...distractors]..shuffle(Random('$title$chosen'.hashCode));
        results.add(_ClozeResult(
          sentence: blanked,
          targetWord: chosen,
          wordBank: bank,
          original: sentence,
        ));
      }
    }

    // Top up from the rest of THIS book (other chapters) before anything generic.
    for (final sentence in _activeBookSentences) {
      if (results.length >= count) break;
      if (results.any((r) => r.original == sentence)) continue;
      final words = sentence.replaceAll(RegExp(r'[,.!?";:]'), '').split(' ');
      String? chosen;
      for (final w in words.reversed) {
        if (w.length >= 4 && !stopWords.contains(w.toLowerCase())) {
          chosen = w;
          break;
        }
      }
      if (chosen == null || results.any((r) => r.targetWord.toLowerCase() == chosen!.toLowerCase())) continue;
      results.add(_ClozeResult(
        sentence: sentence.replaceFirst(chosen, '________'),
        targetWord: chosen,
        wordBank: [chosen, ..._generateDistractors(chosen)]..shuffle(Random('$title$chosen'.hashCode)),
        original: sentence,
      ));
    }

    final fallbackVocab = ['honor', 'courage', 'journey', 'destiny', 'wisdom', 'virtue', 'solitude'];
    while (results.length < count) {
      final target = fallbackVocab[results.length % fallbackVocab.length];
      final sentence = 'The author reflects upon the timeless $target of human striving.';
      final blanked = sentence.replaceFirst(target, '________');
      results.add(_ClozeResult(
        sentence: blanked,
        targetWord: target,
        wordBank: [target, ..._generateDistractors(target)]..shuffle(),
        original: sentence,
      ));
    }
    return results;
  }

  /// Extracts multiple token sets for sentence reordering
  List<List<String>> _extractMultipleReorderTokens(String content, String quote, int count) {
    final results = <List<String>>[];
    final sentences = content
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where((s) => s.length > 15 && s.split(' ').length >= 4)
        .toList();
    if (quote.isNotEmpty) {
      sentences.insert(0, quote);
    }
    for (final s in sentences) {
      final tokens = s
          .replaceAll(RegExp(r'[,.!?"—;]'), '')
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .toList();
      if (tokens.length >= 4) {
        final capped = tokens.length > 8 ? tokens.sublist(0, 8) : tokens;
        results.add(capped);
        if (results.length >= count) break;
      }
    }
    // Top up from the rest of THIS book before anything generic.
    for (final s in _activeBookSentences) {
      if (results.length >= count) break;
      final tokens = s
          .replaceAll(RegExp(r'[,.!?"—;]'), '')
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .toList();
      if (tokens.length < 4) continue;
      final capped = tokens.length > 8 ? tokens.sublist(0, 8) : tokens;
      if (results.any((r) => r.join(' ') == capped.join(' '))) continue;
      results.add(capped);
    }
    final fallbackSentences = [
      ['Every', 'chapter', 'reveals', 'a', 'new', 'truth'],
      ['The', 'reader', 'follows', 'each', 'word', 'closely'],
      ['Great', 'stories', 'endure', 'beyond', 'their', 'age'],
      ['Wisdom', 'speaks', 'in', 'quiet', 'contemplation'],
      ['Every', 'noble', 'journey', 'begins', 'with', 'hope'],
    ];
    int fIdx = 0;
    while (results.length < count) {
      results.add(fallbackSentences[fIdx++ % fallbackSentences.length]);
    }
    return results;
  }

  /// Builds chapter vocabulary definitions for matching
  Map<String, String> _buildChapterVocabPairs(Literature work, Chapter ch) {
    final title = work.title.toLowerCase();
    if (title.contains('quixote')) {
      return {
        'Chivalry': 'The medieval knightly system of honour and courtly devotion',
        'Errant': 'Traveling in search of adventure or noble quests',
        'Knight-errantry': 'The profession or practice of wandering knights',
        'Lance': 'A long weapon used by mounted warriors for jousting',
      };
    }
    if (title.contains('prophet') || title.contains('gibran')) {
      return {
        'Seeress': 'A woman endowed with spiritual foresight or prophetic discernment',
        'Pilgrim': 'A traveler journeying in search of spiritual truth or home',
        'Threshold': 'A strip of wood or stone at a doorway, marking a passage or beginning',
        'Tidings': 'News, announcements, or significant reports brought from afar',
      };
    }
    if (title.contains('secret garden')) {
      return {
        'Disconsolate': 'Without comfort, unhappy and dejected',
        'Ayah': 'A native maidservant or nurse employed by Europeans in India',
        'Bungalow': 'A low house having only one story',
        'Moor': 'A tract of open uncultivated upland with heather',
      };
    }
    if (title.contains('frankenstein')) {
      return {
        'Galvanism': 'Electricity produced by chemical action, once believed vital',
        'Toil': 'Exhausting physical or mental labor sustained over time',
        'Catastrophe': 'An event causing great and sudden damage or suffering',
        'Dismal': 'Depressing and dreary, causing gloom and misery',
      };
    }
    return {
      'Diction': 'The distinctive choice and use of words and phrases',
      'Subtext': 'The implicit or underlying meaning beneath literal dialogue',
      'Motif': 'A recurring distinctive feature or dominant idea in an artistic work',
      'Protagonist': 'The leading character or one of the major figures in a narrative',
    };
  }

  /// Synthesizes 5 distinct multiple choice recall questions
  List<QuizQuestion> _generateRecallQuestions(
    Literature work,
    Chapter ch,
    QuestLevel level,
    String prefix,
    int count,
  ) {
    return [
      QuizQuestion(
        id: '${prefix}_rec_q1',
        prompt: 'In "${ch.title}", what initiating event or atmosphere is established by ${work.author}?',
        options: [
          'The introduction of the primary setting, character dilemma, and authentic dramatic tone',
          'A modern legal trial that instantaneously resolves all narrative stakes',
          'A comedic parody dismissing the entire premise of the world',
          'A royal banquet celebrating a conflict that has not yet occurred',
        ],
        correctAnswerIndex: 0,
        explanation: 'In "${ch.title}", ${work.author} carefully crafts the opening mood and conflict to immerse the reader.',
      ),
      QuizQuestion(
        id: '${prefix}_rec_q2',
        prompt: 'Which theme or human condition does "${ch.title}" invite the reader to examine?',
        options: [
          'The resilience of human purpose when confronted by isolation, duty, or truth',
          'A technical discourse on mercantile bookkeeping procedures',
          'An endorsement of reckless irresponsibility without moral consequence',
          'A celebration of superficial wealth over authentic human connection',
        ],
        correctAnswerIndex: 0,
        explanation: 'Classical masterworks like "${work.title}" center upon universal inquiries into human resilience and purpose.',
      ),
      QuizQuestion(
        id: '${prefix}_rec_q3',
        prompt: 'How does the protagonist in "${ch.title}" respond to their initial circumstance?',
        options: [
          'By exhibiting emotional depth, curiosity, and inner conflict that drives the story forward',
          'By refusing to participate in any action or reflection whatsoever',
          'By magically resolving all hardship without learning or growing',
          'By immediately forgetting their lifelong quest',
        ],
        correctAnswerIndex: 0,
        explanation: 'Compelling classical characters demonstrate believable vulnerability and psychological complexity.',
      ),
      QuizQuestion(
        id: '${prefix}_rec_q4',
        prompt: 'What authorial technique does ${work.author} employ most prominently in "${ch.title}"?',
        options: [
          'Evocative atmospheric description and psychological subtext',
          'Sensationalized nonsense disconnected from the narrative arc',
          'Monotonous repetition of unrelated historical dates',
          'Completely dialogue-free legal disclaimers',
        ],
        correctAnswerIndex: 0,
        explanation: '${work.author} uses rich sensory diction and subtext to reveal the protagonist\'s unspoken longing.',
      ),
      QuizQuestion(
        id: '${prefix}_rec_q5',
        prompt: 'Reflecting on "${ch.title}", what foundational lesson does the reader take away?',
        options: [
          'Careful reading unlocks layered meanings, emotional resonance, and timeless human wisdom',
          'Skimming past descriptions is sufficient to understand literary genius',
          'Classic novels were written with no symbolic or philosophical intent',
          'Characters should never change or experience moral trials',
        ],
        correctAnswerIndex: 0,
        explanation: 'Close reading rewards the scholar with deeper empathy, moral clarity, and literary appreciation.',
      ),
    ];
  }

  /// Synthesizes grand apex exam questions for the culminating book assessment
  List<QuizQuestion> _generateFinalExamQuestions(
    Literature work,
    Chapter ch,
    QuestLevel level,
    String prefix,
    int count,
  ) {
    final roleplay = _buildBookRoleplayDilemma(work, ch);
    return [
      QuizQuestion(
        id: '${prefix}_fin_q1',
        prompt: 'What ultimate philosophical inquiry does "${work.title}" fundamentally resolve?',
        options: [
          'The reconciliation of personal conscience, moral truth, and societal expectation',
          'A manual on medieval heraldic heraldry and horse-breeding',
          'An argument asserting human decisions carry no moral consequence',
          'A mathematical theorem on mercantile cargo capacity',
        ],
        correctAnswerIndex: 0,
        explanation: '"${work.title}" endures because its moral compass illuminates universal human experience.',
      ),
      QuizQuestion(
        id: '${prefix}_fin_q2',
        prompt: 'How does the central imagery developed throughout the chapters operate as a unifying symbol?',
        options: [
          'It distills the abstract ideals of transformation, suffering, and redemption into resonant form',
          'It is purely decorative background scenery with no thematic meaning',
          'It served solely to satisfy publisher length quotas in the 19th century',
          'It hides an encrypted code unrelated to the storyline',
        ],
        correctAnswerIndex: 0,
        explanation: 'Literary symbols unite plot and philosophy, grounding abstract ideals in memorable imagery.',
      ),
      QuizQuestion(
        id: '${prefix}_fin_q3',
        prompt: 'Across the entire arc of "${work.title}", what defines the protagonist\'s ultimate transformation?',
        options: [
          'Moving from naive perception or internal crisis toward self-knowledge and moral maturity',
          'Remaining entirely static and refusing any psychological growth',
          'Abandoning their convictions at the first sign of societal opposition',
          'Accumulating material wealth while losing all empathy',
        ],
        correctAnswerIndex: 0,
        explanation: 'Great classic arcs trace the difficult path from illusion or sorrow to profound moral awakening.',
      ),
      QuizQuestion(
        id: '${prefix}_fin_q4',
        prompt: 'Why does ${work.author}\'s masterwork continue to speak powerfully to readers today?',
        options: [
          'Its emotional honesty and deep understanding of human vulnerability transcend time and geography',
          'It contains no complex vocabulary or difficult emotional themes',
          'It was commissioned as an official government propaganda document',
          'It avoids any exploration of difficult moral dilemmas',
        ],
        correctAnswerIndex: 0,
        explanation: 'Enduring literature lives on because human emotions, grief, love, and courage never grow obsolete.',
      ),
      QuizQuestion(
        id: '${prefix}_fin_q5',
        prompt: 'How should a scholar evaluate the climax of "${work.title}"?',
        options: [
          'As a cathartic synthesis where characters confront the true costs of their beliefs and actions',
          'As a random conclusion assembled without regard to earlier chapters',
          'As an abrupt stop designed to frustrate reader expectations',
          'As an unearned magical escape without emotional consequence',
        ],
        correctAnswerIndex: 0,
        explanation: 'A great climax achieves catharsis by testing the characters\' convictions against reality.',
      ),
      QuizQuestion(
        id: '${prefix}_fin_roleplay',
        type: QuizType.roleplay,
        characterSpeaker: roleplay.speaker,
        prompt: roleplay.prompt,
        options: roleplay.options,
        correctAnswerIndex: roleplay.correctIndex,
        explanation: roleplay.explanation,
        contextHint: 'Choose the response that honors chivalric wisdom and literary authenticity.',
      ),
    ];
  }
}

class _ClozeResult {
  final String sentence;
  final String targetWord;
  final List<String> wordBank;
  final String original;

  _ClozeResult({
    required this.sentence,
    required this.targetWord,
    required this.wordBank,
    required this.original,
  });
}

class _RoleplayResult {
  final String speaker;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  _RoleplayResult({
    required this.speaker,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}
