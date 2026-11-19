import 'package:flutter/material.dart';
import '../models/literature.dart';
import '../models/quest_level.dart';

enum CharacterArchetype {
  knight,      // Don Quixote, Musketeers, Iliad
  gardenGirl,  // Mary Lennox, Little Women, Jane Eyre
  detective,   // Sherlock Holmes, Jekyll & Hyde
  mariner,     // Captain Ahab, Treasure Island, Odyssey, Crusoe
  regencyLady, // Elizabeth Bennet, Great Gatsby, Dorian Gray
  gothicLord,  // Dracula, Frankenstein, Wuthering Heights
  woodland,    // Mole/Ratty, Jungle Book, Walden, Call of the Wild
  sage,        // Marcus Aurelius, Sun Tzu, Plato, Prophet, Poets
}

class ParleyChoice {
  final String label;
  final String traitTag;
  final Color traitColor;
  final String characterReaction;
  final String bonusInsight;
  final int bonusGems;

  const ParleyChoice({
    required this.label,
    required this.traitTag,
    required this.traitColor,
    required this.characterReaction,
    required this.bonusInsight,
    this.bonusGems = 35,
  });
}

class CampfireParleyScenario {
  final String characterName;
  final String characterRole;
  final CharacterArchetype archetype;
  final Color cloakColor;
  final Color accentColor;
  final String campfireSetting;
  final String openingLine;
  final String dilemmaQuestion;
  final List<ParleyChoice> choices;

  const CampfireParleyScenario({
    required this.characterName,
    required this.characterRole,
    required this.archetype,
    required this.cloakColor,
    required this.accentColor,
    required this.campfireSetting,
    required this.openingLine,
    required this.dilemmaQuestion,
    required this.choices,
  });
}

class LightningPrompt {
  final String statement;
  final bool isTrue;
  final String quickFact;

  const LightningPrompt({
    required this.statement,
    required this.isTrue,
    required this.quickFact,
  });
}

/// Supplies rich, book-accurate content for all 6 special map node types
/// across all 42 books and weaves them cleanly into every book's quest path.
class SpecialNodesData {
  /// Returns a copy of [lit] whose `questLevels` have been enriched with all
  /// 6 special interactive map nodes.
  static Literature enrichBook(Literature lit) {
    return Literature(
      id: lit.id,
      title: lit.title,
      author: lit.author,
      description: lit.description,
      type: lit.type,
      genres: lit.genres,
      gemCost: lit.gemCost,
      totalChapters: lit.totalChapters,
      chapters: lit.chapters,
      questLevels: enrichLevels(lit),
      recallQuizzes: lit.recallQuizzes,
      practiceQuizzes: lit.practiceQuizzes,
      finalExam: lit.finalExam,
      isOwned: lit.isOwned,
      currentLevelIndex: lit.currentLevelIndex,
      chaptersCompleted: lit.chaptersCompleted,
      gemsEarned: lit.gemsEarned,
    );
  }

  /// Injects all 6 special node types into a book's quest levels while preserving:
  /// - Every chapter starts with `LevelType.read`
  /// - The final level of every book remains `LevelType.finalTest`
  static List<QuestLevel> enrichLevels(Literature lit) {
    final base = List<QuestLevel>.from(lit.questLevels);
    if (base.length < 4) return base;

    // Avoid double-injecting if already enriched
    if (base.any((l) => l.isSpecialNode)) return base;

    final result = <QuestLevel>[];
    final lastIndex = base.length - 1;
    final hasFinal = base.last.type == LevelType.finalTest;
    final coreCount = hasFinal ? lastIndex : base.length;

    // Compute insertion checkpoints spread naturally across Zones I, II, and III
    final parleyPos = (coreCount * 0.22).round().clamp(1, coreCount - 1);
    final chest1Pos = (coreCount * 0.36).round().clamp(parleyPos, coreCount - 1);
    final duelPos = (coreCount * 0.50).round().clamp(chest1Pos, coreCount - 1);
    final shrinePos = (coreCount * 0.65).round().clamp(duelPos, coreCount - 1);
    final matchPos = (coreCount * 0.80).round().clamp(shrinePos, coreCount - 1);
    final gatePos = (coreCount * 0.92).round().clamp(matchPos, coreCount - 1);

    final parley = parleyForBook(lit);

    for (int i = 0; i < coreCount; i++) {
      final lvl = base[i];
      result.add(lvl);

      if (i == parleyPos) {
        result.add(QuestLevel(
          id: '${lit.id}_parley_1',
          literatureId: lit.id,
          levelNumber: 0,
          title: 'Campfire Parley: ${parley.characterName}',
          description: 'Meet ${parley.characterName} by the campfire and weigh a pivotal story choice.',
          type: LevelType.campfireParley,
          gemsReward: 35,
          energyCost: 0,
          chapterIndex: lvl.chapterIndex,
          estimatedMinutes: 2,
          isLocked: true,
        ));
      }
      if (i == chest1Pos) {
        result.add(QuestLevel(
          id: '${lit.id}_chest_1',
          literatureId: lit.id,
          levelNumber: 0,
          title: 'Milestone Provision Chest',
          description: 'A gleaming checkpoint chest! Tap to claim bonus Gems & Energy.',
          type: LevelType.treasureChest,
          gemsReward: 45,
          energyCost: 0,
          chapterIndex: lvl.chapterIndex,
          estimatedMinutes: 1,
          isLocked: true,
        ));
      }
      if (i == duelPos) {
        result.add(QuestLevel(
          id: '${lit.id}_duel_1',
          literatureId: lit.id,
          levelNumber: 0,
          title: 'Lightning Vocab Duel',
          description: '45-second rapid-fire literary sprint! Chain combos for Leaderboard XP.',
          type: LevelType.lightningDuel,
          gemsReward: 40,
          energyCost: 0,
          chapterIndex: lvl.chapterIndex,
          estimatedMinutes: 2,
          isLocked: true,
        ));
      }
      if (i == shrinePos) {
        result.add(QuestLevel(
          id: '${lit.id}_shrine_1',
          literatureId: lit.id,
          levelNumber: 0,
          title: 'Famous Quote Shrine',
          description: 'Restore an iconic quote from ${lit.title} to mint a collectible Quote Card.',
          type: LevelType.quoteShrine,
          gemsReward: 40,
          energyCost: 0,
          chapterIndex: lvl.chapterIndex,
          estimatedMinutes: 2,
          isLocked: true,
        ));
      }
      if (i == matchPos) {
        result.add(QuestLevel(
          id: '${lit.id}_match_1',
          literatureId: lit.id,
          levelNumber: 0,
          title: 'Word Match Blitz',
          description: 'Match 5 literary terms from ${lit.title} to their meanings in one fast board!',
          type: LevelType.wordMatchBlitz,
          gemsReward: 40,
          energyCost: 0,
          chapterIndex: lvl.chapterIndex,
          estimatedMinutes: 2,
          isLocked: true,
        ));
      }
      if (i == gatePos) {
        result.add(QuestLevel(
          id: '${lit.id}_gatekeeper_1',
          literatureId: lit.id,
          levelNumber: 0,
          title: 'Zone Gatekeeper Trial',
          description: 'Defeat the Zone Guardian in a 3-round literary trial for a Rare or Legendary Chest!',
          type: LevelType.zoneGatekeeper,
          gemsReward: 65,
          energyCost: 1,
          chapterIndex: lvl.chapterIndex,
          estimatedMinutes: 3,
          isLocked: true,
        ));
      }
    }

    if (hasFinal) {
      result.add(base.last);
    }

    // Re-number sequentially & ensure first level is unlocked
    return List<QuestLevel>.generate(result.length, (idx) {
      final old = result[idx];
      return QuestLevel(
        id: old.id,
        literatureId: old.literatureId,
        levelNumber: idx + 1,
        title: old.title,
        description: old.description,
        type: old.type,
        gemsReward: old.gemsReward,
        energyCost: old.energyCost,
        chapterIndex: old.chapterIndex,
        estimatedMinutes: old.estimatedMinutes,
        customQuestions: old.customQuestions,
        isCompleted: old.isCompleted,
        isLocked: idx == 0 ? false : old.isLocked,
      );
    });
  }

  /// Authentic, book-tailored Campfire Parley character & moral dilemma.
  static CampfireParleyScenario parleyForBook(Literature lit) {
    switch (lit.id) {
      case 'lit_secret_garden':
        return const CampfireParleyScenario(
          characterName: 'Mary Lennox',
          characterRole: 'Seeker of the Walled Garden',
          archetype: CharacterArchetype.gardenGirl,
          cloakColor: Color(0xFF2E6B4E),
          accentColor: Color(0xFFE5B842),
          campfireSetting: 'Edge of the Yorkshire Moor at Dusk',
          openingLine: '“Look what the robin just led me to — a rusted iron key half-buried in the ivy. Uncle Craven forbade anyone to ever speak of that locked door.”',
          dilemmaQuestion: 'The garden has slept for ten years. What do you counsel Mary to do?',
          choices: [
            ParleyChoice(
              label: 'Unlock the gate quietly and tend the sleeping roses back to life.',
              traitTag: 'Courage',
              traitColor: Color(0xFF27AE60),
              characterReaction: '“Yes! Even if the branches look grey, I can feel green shoots waiting beneath the bark. Come — let’s wake it up together.”',
              bonusInsight: 'Burnett shows that quiet acts of care heal both the garden and the lonely hearts who tend it.',
              bonusGems: 40,
            ),
            ParleyChoice(
              label: 'Ask Dickon for seeds and secret gardening wisdom first.',
              traitTag: 'Wisdom',
              traitColor: Color(0xFF2980B9),
              characterReaction: '“Clever thought! Dickon knows every moorland creature and every living root. With a true friend, nothing stays wintry for long.”',
              bonusInsight: 'Friendship and humility transform Mary from a solitary child into a compassionate leader.',
              bonusGems: 40,
            ),
            ParleyChoice(
              label: 'Bring Colin into the sunlight so he can witness the magic too.',
              traitTag: 'Empathy',
              traitColor: Color(0xFFC24168),
              characterReaction: '“You’re right — keeping wonder all to myself would make it smaller. Sunlight was meant to be shared!”',
              bonusInsight: 'Shared hope breaks the cycle of fear and isolation inside Misselthwaite Manor.',
              bonusGems: 45,
            ),
          ],
        );

      case 'lit_wind_in_willows':
        return const CampfireParleyScenario(
          characterName: 'Water Rat (Ratty)',
          characterRole: 'Poet of the River Bank',
          archetype: CharacterArchetype.woodland,
          cloakColor: Color(0xFF3A6B5C),
          accentColor: Color(0xFFD4A338),
          campfireSetting: 'Lantern-Lit Willow Bank',
          openingLine: '“Believe me, my young friend, there is nothing half so much worth doing as simply messing about in boats — yet Toad is off chasing another roaring motorcar!”',
          dilemmaQuestion: 'Toad’s recklessness threatens Toad Hall. How should the riverbank friends respond?',
          choices: [
            ParleyChoice(
              label: 'Stand beside Badger and stage a firm, loyal intervention.',
              traitTag: 'Loyalty',
              traitColor: Color(0xFF2E86C1),
              characterReaction: '“Spoken like a true river comrade! Sometimes friendship means holding the rudder steady when someone steers for the rocks.”',
              bonusInsight: 'Grahame contrasts impulsive thrill-seeking with steady, enduring loyalty.',
              bonusGems: 40,
            ),
            ParleyChoice(
              label: 'Invite Toad to a quiet evening picnic by the water to remind him of home.',
              traitTag: 'Warmth',
              traitColor: Color(0xFFE67E22),
              characterReaction: '“Ah, cold chicken, ginger beer, and the whisper of reeds — no motorcar horn can rival the music of the river!”',
              bonusInsight: 'The river represents peace, belonging, and the joy of simple pleasures.',
              bonusGems: 40,
            ),
            ParleyChoice(
              label: 'Let Toad face one humbling lesson, then help him reclaim his home.',
              traitTag: 'Wisdom',
              traitColor: Color(0xFF8E44AD),
              characterReaction: '“A wise head on your shoulders! A bit of humility will make the banquet at Toad Hall twice as sweet.”',
              bonusInsight: 'True growth arrives when pride gives way to gratitude for one’s friends.',
              bonusGems: 45,
            ),
          ],
        );

      case 'lit_don_quixote':
        return const CampfireParleyScenario(
          characterName: 'Don Quixote',
          characterRole: 'Knight of the Sorrowful Countenance',
          archetype: CharacterArchetype.knight,
          cloakColor: Color(0xFF991B2D),
          accentColor: Color(0xFFD4A338),
          campfireSetting: 'Starlit Plains of La Mancha',
          openingLine: '“Behold on yonder ridge, good squire! Thirty monstrous giants wave their league-long arms against the night sky — though Sancho swears they are merely windmills.”',
          dilemmaQuestion: 'When the world mocks an impossible ideal, how do you counsel the Knight?',
          choices: [
            ParleyChoice(
              label: '“Look closely before charging, Sir Knight — courage shines brightest with clear eyes.”',
              traitTag: 'Wisdom',
              traitColor: Color(0xFF2980B9),
              characterReaction: '“Hmm… Sancho speaks much the same! Yet even if they be mills of stone, a noble heart must stay ever ready to defend the weak.”',
              bonusInsight: 'Cervantes balances Don Quixote’s soaring idealism against Sancho’s grounded common sense.',
              bonusGems: 45,
            ),
            ParleyChoice(
              label: '“Ride on! Better to dream grandly and fall than never to dare at all.”',
              traitTag: 'Chivalry',
              traitColor: Color(0xFFD95B30),
              characterReaction: '“Ha! Spoken with the fire of Amadis himself! Raise thy banner, friend — honor outlives every bruise!”',
              bonusInsight: 'Quixote’s enduring charm lies in his refusal to surrender imagination to cynicism.',
              bonusGems: 40,
            ),
            ParleyChoice(
              label: '“Let us share bread by the fire first — even heroes need rest.”',
              traitTag: 'Kindness',
              traitColor: Color(0xFF27AE60),
              characterReaction: '“A gracious counsel! Sancho will gladly unpack the cheese and onions while we trade tales beneath the stars.”',
              bonusInsight: 'Companionship between knight and squire is the true heart of the novel.',
              bonusGems: 40,
            ),
          ],
        );

      case 'lit_study_in_scarlet':
        return const CampfireParleyScenario(
          characterName: 'Sherlock Holmes',
          characterRole: 'Consulting Detective of 221B',
          archetype: CharacterArchetype.detective,
          cloakColor: Color(0xFF2C3E50),
          accentColor: Color(0xFFD4A338),
          campfireSetting: 'Gaslit Hearth at 221B Baker Street',
          openingLine: '“Look at the ash on the floorboards and the word RACHE scrawled in crimson. Scotland Yard already jumped to a hasty conclusion — what catches your eye?”',
          dilemmaQuestion: 'How do you approach a mystery when the obvious clue feels like a trap?',
          choices: [
            ParleyChoice(
              label: 'Observe the tiniest overlooked detail before forming any theory.',
              traitTag: 'Deduction',
              traitColor: Color(0xFF2980B9),
              characterReaction: '“Capital! It is a capital mistake to theorize before one has data. You have the makings of a Baker Street mind.”',
              bonusInsight: 'Holmes’s scientific method relies on eliminating the impossible until only truth remains.',
              bonusGems: 45,
            ),
            ParleyChoice(
              label: 'Question who gains from leaving such a theatrical clue behind.',
              traitTag: 'Insight',
              traitColor: Color(0xFF8E44AD),
              characterReaction: '“Precisely! A red herring designed to mislead the police. You see past the stagecraft!”',
              bonusInsight: 'Understanding human motive is just as vital to detection as physical evidence.',
              bonusGems: 40,
            ),
            ParleyChoice(
              label: 'Collaborate openly with Watson to test every hypothesis aloud.',
              traitTag: 'Teamwork',
              traitColor: Color(0xFF27AE60),
              characterReaction: '“Quite right — nothing clears a case so well as stating it to a trusted chronicler.”',
              bonusInsight: 'Watson’s steady humanity grounds Holmes’s brilliant analytical intellect.',
              bonusGems: 40,
            ),
          ],
        );

      case 'lit_pride_and_prejudice':
        return const CampfireParleyScenario(
          characterName: 'Elizabeth Bennet',
          characterRole: 'Quick-Witted Daughter of Longbourn',
          archetype: CharacterArchetype.regencyLady,
          cloakColor: Color(0xFFC24168),
          accentColor: Color(0xFFF3D58D),
          campfireSetting: 'Lantern-Lit Terrace near Pemberley',
          openingLine: '“First impressions are so tempting to trust, aren’t they? I was certain of Mr. Darcy’s pride — and equally certain of Mr. Wickham’s charm — until one letter overturned everything.”',
          dilemmaQuestion: 'When new truth challenges your proudest judgment, what do you do?',
          choices: [
            ParleyChoice(
              label: 'Admit the blind spot honestly and judge people by their actions, not charm.',
              traitTag: 'Humility',
              traitColor: Color(0xFFC24168),
              characterReaction: '“Well said! Till that moment, I never truly knew myself. Honest reflection is the finest mirror.”',
              bonusInsight: 'Austen’s masterpiece is built on both Elizabeth and Darcy outgrowing their own blind spots.',
              bonusGems: 45,
            ),
            ParleyChoice(
              label: 'Keep your wit sharp, but give quiet decency a second hearing.',
              traitTag: 'Grace',
              traitColor: Color(0xFF8E44AD),
              characterReaction: '“A delightful balance! Laughter should illuminate folly, never harden the heart.”',
              bonusInsight: 'Elizabeth’s lively spirit combined with moral clarity makes her timeless.',
              bonusGems: 40,
            ),
            ParleyChoice(
              label: 'Refuse to marry for wealth alone — hold out for true mutual respect.',
              traitTag: 'Integrity',
              traitColor: Color(0xFFD4A338),
              characterReaction: '“Hear, hear! Only the deepest respect and affection could ever induce me to give my hand.”',
              bonusInsight: 'Austen champions partnership built on intellectual and moral equality.',
              bonusGems: 40,
            ),
          ],
        );

      case 'lit_moby_dick':
      case 'lit_treasure_island':
      case 'lit_odyssey':
      case 'lit_robinson_crusoe':
        return CampfireParleyScenario(
          characterName: lit.id == 'lit_odyssey'
              ? 'Odysseus of Ithaca'
              : lit.id == 'lit_treasure_island'
                  ? 'Jim Hawkins'
                  : lit.id == 'lit_robinson_crusoe'
                      ? 'Robinson Crusoe'
                      : 'Ishmael of the Pequod',
          characterRole: 'Voyager of Uncharted Seas',
          archetype: CharacterArchetype.mariner,
          cloakColor: const Color(0xFF1B4965),
          accentColor: const Color(0xFFE5B842),
          campfireSetting: 'Driftwood Fire on a Starlit Shore',
          openingLine: '“The tide turns at midnight, and the horizon hides both wonder and peril. Every sailor must decide what compass guides them through the storm.”',
          dilemmaQuestion: 'When ambition and survival collide at sea, what guides your helm?',
          choices: const [
            ParleyChoice(
              label: 'Protect the crew first — no prize is worth losing our humanity.',
              traitTag: 'Honor',
              traitColor: Color(0xFF2980B9),
              characterReaction: '“Aye, well spoken! A true mariner values living comrades above gold or vengeance.”',
              bonusInsight: 'Classic sea voyages test whether obsession or fellowship wins the soul.',
              bonusGems: 45,
            ),
            ParleyChoice(
              label: 'Outwit the storm with patience, observation, and clever strategy.',
              traitTag: 'Cunning',
              traitColor: Color(0xFFD4A338),
              characterReaction: '“Sharp as a brass astrolabe! Brains have weathered more tempests than brute strength ever could.”',
              bonusInsight: 'Resourcefulness turns impossible odds into legend.',
              bonusGems: 40,
            ),
            ParleyChoice(
              label: 'Record the journey honestly so future voyagers learn from our wake.',
              traitTag: 'Chronicle',
              traitColor: Color(0xFF27AE60),
              characterReaction: '“Then let our tale outlive the waves! Every great voyage lives on in the telling.”',
              bonusInsight: 'Storytelling preserves wisdom long after the voyage ends.',
              bonusGems: 40,
            ),
          ],
        );

      case 'lit_frankenstein':
      case 'lit_dracula':
      case 'lit_jekyll_hyde':
      case 'lit_wuthering_heights':
        return CampfireParleyScenario(
          characterName: lit.id == 'lit_dracula'
              ? 'Abraham Van Helsing'
              : lit.id == 'lit_frankenstein'
                  ? 'Victor Frankenstein'
                  : lit.id == 'lit_jekyll_hyde'
                      ? 'Mr. Gabriel Utterson'
                      : 'Nelly Dean',
          characterRole: 'Watcher in the Gothic Mist',
          archetype: CharacterArchetype.gothicLord,
          cloakColor: const Color(0xFF3C1642),
          accentColor: const Color(0xFFC77DFF),
          campfireSetting: 'Lantern-Lit Stone Courtyard at Midnight',
          openingLine: '“Shadows lengthen when curiosity outruns conscience. Tell me, traveler — when we uncover a dark secret in ${lit.title}, how must we face it?”',
          dilemmaQuestion: 'What is the truest safeguard against hubris and shadow?',
          choices: const [
            ParleyChoice(
              label: 'Take full responsibility for what we create instead of fleeing it.',
              traitTag: 'Accountability',
              traitColor: Color(0xFF9D4EDD),
              characterReaction: '“A sobering truth… had we faced our creations with compassion rather than dread, tragedy might have been spared.”',
              bonusInsight: 'Gothic literature warns that abandonment and secrecy breed far darker monsters than science.',
              bonusGems: 45,
            ),
            ParleyChoice(
              label: 'Bring hidden truths into the daylight with trusted allies.',
              traitTag: 'Courage',
              traitColor: Color(0xFFD4A338),
              characterReaction: '“Yes! Darkness only rules what stays unspoken. Together, even the longest night breaks into dawn.”',
              bonusInsight: 'Solidarity and transparency defeat isolation in classic gothic tales.',
              bonusGems: 40,
            ),
            ParleyChoice(
              label: 'Show empathy for the outcast while standing firm against harm.',
              traitTag: 'Compassion',
              traitColor: Color(0xFFC24168),
              characterReaction: '“Wise and merciful. Understanding the wound does not excuse the harm, yet mercy keeps us human.”',
              bonusInsight: 'The deepest gothic stories ask where monstrosity truly resides.',
              bonusGems: 40,
            ),
          ],
        );

      default:
        // Smart book-tailored Campfire Parley for every remaining classic in the 42-book library
        return CampfireParleyScenario(
          characterName: lit.author,
          characterRole: 'Chronicler of ${lit.title}',
          archetype: CharacterArchetype.sage,
          cloakColor: const Color(0xFF1E382B),
          accentColor: const Color(0xFFD4A338),
          campfireSetting: 'Starlit Literary Campfire',
          openingLine: '“Pull up a stool by the embers, traveler. Every page of ${lit.title} holds a mirror up to human nature — what truth have you discovered so far?”',
          dilemmaQuestion: 'What lesson from ${lit.title} will you carry forward on your quest?',
          choices: [
            ParleyChoice(
              label: 'Question assumptions and look beneath the surface of every character.',
              traitTag: 'Insight',
              traitColor: const Color(0xFF2980B9),
              characterReaction: '“Splendid! The finest readers never settle for the first impression — they listen for the subtext.”',
              bonusInsight: 'Close reading reveals the layered themes that make ${lit.title} endure across generations.',
              bonusGems: 40,
            ),
            ParleyChoice(
              label: 'Stand boldly for principle, even when the crowd takes the easy road.',
              traitTag: 'Courage',
              traitColor: const Color(0xFFD95B30),
              characterReaction: '“Spoken with conviction! Every classic endures because someone dared to choose integrity.”',
              bonusInsight: 'Moral courage is the beating heart of timeless storytelling.',
              bonusGems: 45,
            ),
            ParleyChoice(
              label: 'Share stories and empathy with those whose voices are seldom heard.',
              traitTag: 'Empathy',
              traitColor: const Color(0xFFC24168),
              characterReaction: '“A generous spirit! Literature widens our world one empathetic heart at a time.”',
              bonusInsight: 'Reading builds bridges across centuries, cultures, and perspectives.',
              bonusGems: 40,
            ),
          ],
        );
    }
  }

  /// Iconic short quote (6–10 words) for the Famous Quote Shrine scramble game.
  static String iconicQuoteForBook(Literature lit) {
    const map = <String, String>{
      'lit_secret_garden': 'Where you tend a rose a thistle cannot grow',
      'lit_wind_in_willows': 'Nothing is half so worth doing as messing in boats',
      'lit_hope_feathers': 'Hope is the thing with feathers that perches in soul',
      'lit_sonnet_18': 'Shall I compare thee to a bright summers day',
      'lit_don_quixote': 'To dream the impossible dream and tilt at giants',
      'lit_study_in_scarlet': 'When you eliminate the impossible whatever remains is truth',
      'lit_around_the_world_80_days': 'Anything one man can imagine other men make real',
      'lit_pride_and_prejudice': 'It is a truth universally acknowledged across every parlor',
      'lit_frankenstein': 'Beware for I am fearless and therefore truly powerful',
      'lit_dracula': 'Listen to the children of the night what music',
      'lit_moby_dick': 'Call me Ishmael when the damp November fills soul',
      'lit_great_gatsby': 'So we beat on boats against the ceaseless current',
      'lit_treasure_island': 'Fifteen men on the dead mans chest and compass',
      'lit_odyssey': 'Tell me Muse of that man of many ways',
      'lit_meditations': 'You have power over your mind not outside events',
      'lit_art_of_war': 'Supreme excellence consists of breaking resistance without ever fighting',
      'lit_walden': 'I went to the woods to live truly deliberately',
    };
    if (map.containsKey(lit.id)) return map[lit.id]!;
    if (lit.chapters.isNotEmpty &&
        lit.chapters.first.quoteHighlight != null &&
        lit.chapters.first.quoteHighlight!.trim().split(RegExp(r'\s+')).length >= 5) {
      final words = lit.chapters.first.quoteHighlight!
          .replaceAll(RegExp(r'[^a-zA-Z0-9\s’\x27]'), '')
          .trim()
          .split(RegExp(r'\s+'))
          .take(9)
          .toList();
      if (words.length >= 5) return words.join(' ');
    }
    return 'A great book is a lantern through the dark';
  }

  /// 5 tactile word-meaning pairs for the Word Match Blitz node.
  static Map<String, String> wordPairsForBook(Literature lit) {
    switch (lit.id) {
      case 'lit_secret_garden':
        return const {
          'Moor': 'Wild open windswept highland',
          'Wicket': 'Small hidden garden gate',
          'Tend': 'Care for and nurture growth',
          'Hearth': 'Warm stone fireplace floor',
          'Bower': 'Shady leafy garden shelter',
        };
      case 'lit_don_quixote':
        return const {
          'Hidalgo': 'Spanish country gentleman',
          'Chivalry': 'Noble code of knightly honor',
          'Squire': 'Loyal attendant to a knight',
          'Valorous': 'Showing great courage in battle',
          'Quixotic': 'Exceedingly idealistic and bold',
        };
      case 'lit_study_in_scarlet':
        return const {
          'Deduction': 'Reasoning from clues to truth',
          'Monograph': 'Detailed scholarly study',
          'Cipher': 'Secret coded message',
          'Hansom': 'Two-wheeled Victorian cab',
          'Astute': 'Sharp and quick to notice',
        };
      case 'lit_wind_in_willows':
        return const {
          'Eddy': 'Gentle swirling river current',
          'Weir': 'Low dam across a stream',
          'Scull': 'Oar used to row a small boat',
          'Thicket': 'Dense tangled woodland grove',
          'Convivial': 'Warm, friendly, and lively',
        };
      default:
        return const {
          'Prologue': 'Opening that sets the stage',
          'Motif': 'Recurring symbol or theme',
          'Subtext': 'Unspoken meaning beneath lines',
          'Epiphany': 'Sudden flash of realization',
          'Resolve': 'Firm determination of spirit',
        };
    }
  }

  /// Rapid-fire True/False statements for the 45-second Lightning Duel mini-game.
  static List<LightningPrompt> lightningPromptsForBook(Literature lit) {
    final title = lit.title;
    final author = lit.author;
    final ch1 = lit.chapters.isNotEmpty ? lit.chapters.first.title : 'Chapter 1';
    return [
      LightningPrompt(
        statement: '$title was written by $author.',
        isTrue: true,
        quickFact: '$author is indeed the acclaimed author of $title!',
      ),
      LightningPrompt(
        statement: 'A "motif" in literature is a recurring symbol or idea that reinforces a theme.',
        isTrue: true,
        quickFact: 'Correct! Motifs weave deeper unity throughout a classic work.',
      ),
      LightningPrompt(
        statement: '"Subtext" means the literal dictionary definition printed on the cover.',
        isTrue: false,
        quickFact: 'False! Subtext is the unspoken meaning beneath dialogue and action.',
      ),
      LightningPrompt(
        statement: '"$ch1" is the opening chapter of $title.',
        isTrue: true,
        quickFact: 'Spot on! Every journey begins with its opening chapter.',
      ),
      LightningPrompt(
        statement: 'An "epiphany" in a story is a sudden moment of deep insight or realization.',
        isTrue: true,
        quickFact: 'Yes! Characters often transform after a pivotal epiphany.',
      ),
      LightningPrompt(
        statement: 'Reading a classic slowly and reflecting on quotes reduces comprehension.',
        isTrue: false,
        quickFact: 'False! Active reflection and quote highlighting boost retention.',
      ),
      LightningPrompt(
        statement: 'Foreshadowing gives readers subtle hints about events to come later.',
        isTrue: true,
        quickFact: 'Exactly! Master storytellers plant early clues for attentive readers.',
      ),
      LightningPrompt(
        statement: 'A "protagonist" is always the villain who opposes the main character.',
        isTrue: false,
        quickFact: 'False! The protagonist is the central character; the antagonist opposes them.',
      ),
    ];
  }
}
