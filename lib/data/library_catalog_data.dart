import '../models/literature.dart';
import '../models/quest_level.dart';
import '../models/quiz_question.dart';

class ChapterBlueprint {
  final String title;
  final String quoteHighlight;
  final String quoteContext;
  final String content;

  const ChapterBlueprint({
    required this.title,
    required this.quoteHighlight,
    required this.quoteContext,
    required this.content,
  });
}

class LibraryCatalogData {
  static List<Literature> getExpandedBooks() {
    return _rawExpandedBooks.map((book) => _enrichBookWithDynamicChapterLevels(book)).toList();
  }

  static int _getTargetChapterCount(String id) {
    if (['lit_moby_dick', 'lit_les_miserables', 'lit_odyssey', 'lit_monte_cristo', 'lit_crime_punishment'].contains(id)) {
      return 6;
    }
    if (['lit_frankenstein', 'lit_dracula', 'lit_iliad', 'lit_war_of_worlds', 'lit_jane_eyre'].contains(id)) {
      return 5;
    }
    if ([
      'lit_dorian_gray',
      'lit_treasure_island',
      'lit_three_musketeers',
      'lit_wuthering_heights',
      'lit_two_cities',
      'lit_great_expectations',
      'lit_little_women',
      'lit_gulliver',
      'lit_robinson_crusoe'
    ].contains(id)) {
      return 4;
    }
    if (['lit_the_prophet', 'lit_metamorphosis'].contains(id)) {
      return 2;
    }
    return 3;
  }

  static Literature _enrichBookWithDynamicChapterLevels(Literature book) {
    final prefix = book.id.replaceAll('lit_', '');
    final targetChapterCount = _getTargetChapterCount(book.id);
    final allChapters = _buildAllChapters(book, targetChapterCount);

    final levels = <QuestLevel>[];
    int currentLevelNumber = 1;

    for (int i = 0; i < allChapters.length; i++) {
      final ch = allChapters[i];
      final isFirstOverallLevel = (currentLevelNumber == 1);

      // Level A: Read (Reading Session)
      levels.add(
        QuestLevel(
          id: '${prefix}_lvl_$currentLevelNumber',
          literatureId: book.id,
          levelNumber: currentLevelNumber++,
          title: 'Chapter ${ch.chapterNumber}: ${ch.title}',
          description: 'Read and immerse in the authentic classical prose of ${ch.title}.',
          type: LevelType.read,
          isCompleted: false,
          isLocked: !isFirstOverallLevel,
          gemsReward: 30,
          chapterIndex: i,
          estimatedMinutes: ch.estimatedMinutes,
        ),
      );

      // Level B: Recall (Comprehension & Chronology)
      levels.add(
        QuestLevel(
          id: '${prefix}_lvl_$currentLevelNumber',
          literatureId: book.id,
          levelNumber: currentLevelNumber++,
          title: 'Chapter ${ch.chapterNumber} Comprehension: Chronology & Facts',
          description: 'Assess explicit details, setting, and chronological sequence in ${ch.title}.',
          type: LevelType.recall,
          isCompleted: false,
          isLocked: true,
          gemsReward: 35,
          energyCost: 1,
          chapterIndex: i,
        ),
      );

      // Level C: Practice (Fill in the Blanks: Lexicon Drill)
      levels.add(
        QuestLevel(
          id: '${prefix}_lvl_$currentLevelNumber',
          literatureId: book.id,
          levelNumber: currentLevelNumber++,
          title: 'Chapter ${ch.chapterNumber} Fill in the Blanks: Lexicon Drill',
          description: 'Interactive Word Bank: Deduce missing elevated words from context in ${ch.title}.',
          type: LevelType.practice,
          isCompleted: false,
          isLocked: true,
          gemsReward: 35,
          energyCost: 0,
          chapterIndex: i,
        ),
      );

      // Level D: Analysis (Reconstruct Passage: Syntax & Word Order)
      levels.add(
        QuestLevel(
          id: '${prefix}_lvl_$currentLevelNumber',
          literatureId: book.id,
          levelNumber: currentLevelNumber++,
          title: 'Chapter ${ch.chapterNumber} Reconstruct Passage: Syntax & Word Order',
          description: 'Interactive Reordering: Assemble classical sentence cadence from ${ch.title}.',
          type: LevelType.analysis,
          isCompleted: false,
          isLocked: true,
          gemsReward: 45,
          energyCost: 1,
          chapterIndex: i,
        ),
      );

      // Level E: Practice (Literary Connections: Matching Pairs)
      levels.add(
        QuestLevel(
          id: '${prefix}_lvl_$currentLevelNumber',
          literatureId: book.id,
          levelNumber: currentLevelNumber++,
          title: 'Chapter ${ch.chapterNumber} Literary Connections: Matching Pairs',
          description: 'Interactive Matching: Link motifs, characters, and vocabulary in ${ch.title}.',
          type: LevelType.practice,
          isCompleted: false,
          isLocked: true,
          gemsReward: 40,
          energyCost: 0,
          chapterIndex: i,
        ),
      );
    }

    // Grand Apex Assessment Level (End of book)
    levels.add(
      QuestLevel(
        id: '${prefix}_lvl_$currentLevelNumber',
        literatureId: book.id,
        levelNumber: currentLevelNumber,
        title: 'Masterwork Grand Apex Exam',
        description: 'Comprehensive thematic synthesis and moral evaluation across ${book.title}.',
        type: LevelType.finalTest,
        isCompleted: false,
        isLocked: true,
        gemsReward: 100,
        energyCost: 2,
        chapterIndex: allChapters.length - 1,
      ),
    );

    return Literature(
      id: book.id,
      title: book.title,
      author: book.author,
      description: book.description,
      type: book.type,
      genres: book.genres,
      gemCost: book.gemCost,
      totalChapters: allChapters.length,
      chapters: allChapters,
      questLevels: levels,
      recallQuizzes: const {},
      practiceQuizzes: const {},
      finalExam: const [],
      isOwned: book.isOwned,
      currentLevelIndex: book.currentLevelIndex,
      chaptersCompleted: book.chaptersCompleted,
      gemsEarned: book.gemsEarned,
    );
  }

  static List<Chapter> _buildAllChapters(Literature book, int targetCount) {
    final prefix = book.id.replaceAll('lit_', '');
    final chapters = <Chapter>[];
    if (book.chapters.isNotEmpty) {
      chapters.add(book.chapters.first);
    } else {
      chapters.add(Chapter(
        id: '${prefix}_ch1',
        chapterNumber: 1,
        title: 'Opening Chapter',
        content: book.description,
        estimatedMinutes: 5,
        quoteHighlight: 'The opening journey begins.',
        quoteContext: 'The opening scene',
      ));
    }

    final blueprints = _curatedChapterBlueprints[book.id] ?? [];
    for (int i = 1; i < targetCount; i++) {
      final chNum = i + 1;
      if (i - 1 < blueprints.length) {
        final bp = blueprints[i - 1];
        chapters.add(Chapter(
          id: '${prefix}_ch$chNum',
          chapterNumber: chNum,
          title: bp.title,
          estimatedMinutes: 5,
          quoteHighlight: bp.quoteHighlight,
          quoteContext: bp.quoteContext,
          content: bp.content,
        ));
      } else {
        final fallbackTitles = [
          'The Unfolding Trial',
          'The Crucible of Conscience',
          'The Perilous Encounter',
          'The Threshold of Revelation',
          'The Triumph of the Spirit',
        ];
        final title = fallbackTitles[(i - 1) % fallbackTitles.length];
        chapters.add(Chapter(
          id: '${prefix}_ch$chNum',
          chapterNumber: chNum,
          title: title,
          estimatedMinutes: 5,
          quoteHighlight: 'The human spirit confronts its greatest trial in search of truth.',
          quoteContext: 'Dramatic development in ${book.title}',
          content: '''
In Chapter $chNum of ${book.title}, ${book.author} deepens the narrative arc as the consequences of earlier choices reverberate.

"To strive, to seek, to find, and not to yield—this remains the enduring creed of our quest," reflects the narrative voice.

Amidst mounting tension and philosophical reckoning, the characters must navigate moral ambiguity, testing their convictions against harsh reality and forging their true destiny.
''',
        ));
      }
    }
    return chapters;
  }

  static const Map<String, List<ChapterBlueprint>> _curatedChapterBlueprints = {
    'lit_frankenstein': [
      ChapterBlueprint(
        title: 'The Monster Awakes',
        quoteHighlight: 'I had desired it with an ardour that far exceeded moderation; but now that I had finished, the beauty of the dream vanished, and breathless horror and disgust filled my heart.',
        quoteContext: 'The morning after the awakening',
        content: '''
Unable to endure the aspect of the being I had created, I rushed out of the room and continued a long time traversing my bed-chamber, unable to compose my mind to sleep. At length lassitude succeeded to the tumult I had before endured, and I threw myself on the bed in my clothes, endeavouring to seek a few moments of forgetfulness. But it was in vain; I slept, indeed, but I was disturbed by the wildest dreams.
''',
      ),
      ChapterBlueprint(
        title: 'The Creature\'s Solitude',
        quoteHighlight: 'I was a poor, helpless, miserable wretch; I knew, and could distinguish, nothing; but feeling pain invade me on all sides, I sat down and wept.',
        quoteContext: 'The creature awakening to sensations in the forest',
        content: '''
A strange multiplicity of sensations seized me, and I saw, felt, heard, and smelt at the same time; and it was, indeed, a long time before I learned to distinguish between the operations of my various senses. By degrees, I remember, a stronger light pressed upon my nerves, so that I was obliged to shut my eyes. Darkness then came over me and troubled me; but hardly had I felt this when, by opening my eyes, as I now suppose, the light poured in upon me again.
''',
      ),
      ChapterBlueprint(
        title: 'The De Lacey Cottage',
        quoteHighlight: 'I admired virtue and good feelings and loved the gentle manners and amiable qualities of my cottagers.',
        quoteContext: 'Secretly learning language and empathy from peasants',
        content: '''
The gentle manners of these people won my affection; for they were in so high a degree superior to what I had expected of mankind. The more I saw of them, the greater became my desire to claim their protection and friendship; my heart yearned to be known and loved by these amiable creatures; to see their sweet looks directed towards me with affection was the utmost limit of my ambition.
''',
      ),
      ChapterBlueprint(
        title: 'The Arctic Chase',
        quoteHighlight: 'Farewell, Frankenstein! If thou wert yet alive, and yet cherishedst a desire of revenge, it would be better satiated in my life than in my destruction.',
        quoteContext: 'The creature lamenting over Victor\'s frozen bier',
        content: '''
I shall die. I shall no longer feel the agonies which now consume me, or be the prey of feelings unsatisfied, yet unquenched. He is dead who called me into being; and when I shall be no more, the very remembrance of us both will speedily vanish. I shall ascend my funeral pile triumphantly and exult in the agony of the torturing flames.
''',
      ),
    ],
    'lit_dracula': [
      ChapterBlueprint(
        title: 'Castle Dracula',
        quoteHighlight: 'There are darknesses in life and there are lights, and you are one of the lights, the light of all lights.',
        quoteContext: 'Jonathan realizing he is imprisoned in the castle',
        content: '''
The castle is on the very edge of a terrible precipice. A stone falling from the window would fall a thousand feet without touching anything! As far as the eye can reach is a sea of green tree tops, with occasionally a deep rift where there is a chasm. Here and there are silver threads where the rivers wind in deep gorges through the forests. But I am not in heart to describe beauty, for when I had seen the view I explored further; doors, doors, doors everywhere, and all locked and bolted.
''',
      ),
      ChapterBlueprint(
        title: 'The Demeter Log',
        quoteHighlight: 'No one on board. Strange things happened on voyage. Second mate jumped overboard.',
        quoteContext: 'The ghost ship grounding in Whitby harbour',
        content: '''
The storm broke with a fury that seemed to shake the very foundations of the cliff. The coastguard on duty saw a strange schooner with all sails set running before the wind. When she struck the gravel beach, a huge black dog sprang up on deck, leaped from the bow to the sand, and rushed straight up the steep cliff towards the churchyard. The only man aboard was the captain, lashed dead to the helm.
''',
      ),
      ChapterBlueprint(
        title: 'Lucy\'s Transfusion',
        quoteHighlight: 'There is a reason in nature why we should fear the dead, but why should we fear those who sleep?',
        quoteContext: 'Dr. Van Helsing preparing the garlic wards',
        content: '''
Van Helsing stood by the bed, his face grim and stern. 'We are in the midst of a battle,' he whispered, 'and our weapon is our vigilance.' He hung wreaths of white garlic flowers around the room and placed a crucifix upon her breast, warning all that not a single window must be opened during the dark hours of the night.
''',
      ),
      ChapterBlueprint(
        title: 'The Final Pursuit',
        quoteHighlight: 'We go to seek him in his very lair, where the shadows grow thick and long.',
        quoteContext: 'The overland chase into Transylvania',
        content: '''
The snow fell thick and white over the mountain passes as we urged our horses forward against the approaching dusk. In the distance rose the jagged teeth of the Borgo Pass. The gypsies drove the great cart containing the wooden box, their whips cracking in the frozen air. The sun dipped below the crest of the mountains, throwing long purple shadows across the crags.
''',
      ),
    ],
    'lit_moby_dick': [
      ChapterBlueprint(
        title: 'The Spouter-Inn',
        quoteHighlight: 'Better sleep with a sober cannibal than a drunken Christian.',
        quoteContext: 'Ishmael arriving in New Bedford',
        content: '''
Entering that gable-ended Spouter-Inn, you found yourself in a wide, low, straggling entry with old-fashioned wainscots, reminding one of the bulwarks of some condemned old craft. On one side hung a very large oil painting so thoroughly besmoked, and every way defaced, that in the unequal cross-lights by which you viewed it, it was only by diligent study that you could arrive at an understanding of its purpose.
''',
      ),
      ChapterBlueprint(
        title: 'Queequeg',
        quoteHighlight: 'I began to be sensible of strange feelings. I felt a melting in me. No more my splintered heart and maddened hand were turned against the wolfish world.',
        quoteContext: 'Sharing the pipe and harpoon with Queequeg',
        content: '''
He seemed to be saying: 'Call me heathen, call me savage, but my heart beats with the fidelity of a brother.' We were sitting by the dying embers of the hearth, sharing the pipe of peace, two lonely souls drawn together from opposite hemispheres beneath the cold Nantucket night.
''',
      ),
      ChapterBlueprint(
        title: 'Enter Ahab',
        quoteHighlight: 'Captain Ahab stood upon his quarter-deck. There seemed no sign of common bodily illness about him, nor of the recovery from any. He looked like a man cut away from the stake.',
        quoteContext: 'First sighting of the scarred captain',
        content: '''
His whole high, broad form seemed made of solid bronze, and shaped in an unalterable mould, like Cellini's cast Perseus. Threading its way out from among his grey hairs, and continuing right down one side of his tawny scorched face and neck, till it disappeared in his clothing, you saw a slender rod-like mark, lividly whitish.
''',
      ),
      ChapterBlueprint(
        title: 'The Quarter-Deck',
        quoteHighlight: 'Whosoever of ye raises me that same white whale, he shall have this gold ounce, boys!',
        quoteContext: 'Ahab nailing the doubloon to the mast',
        content: '''
'Aye, aye!' was the cried answer from the crew. Ahab looked upon them with an eye of fire. 'Send everybody aft,' he shouted to Starbuck. 'D'ye see this Spanish ounce of gold?'—holding up a broad bright coin to the sun—'it is a sixteen dollar piece, men. Mr. Starbuck, hand me yon top-maul.'
''',
      ),
      ChapterBlueprint(
        title: 'The Chase — Third Day',
        quoteHighlight: 'Towards thee I roll, thou all-destroying but unconquering whale; to the last I grapple with thee; from hell\'s heart I stab at thee; for hate\'s sake I spit my last breath at thee.',
        quoteContext: 'The final confrontation with Moby Dick',
        content: '''
The ship! The hearse! The second hearse! cried Ahab from the boat; its wood could only be American! Diving beneath the settling ship, the great whale struck with the fury of a tempest. The waters closed around the Pequod, and the great shroud of the sea rolled on as it rolled five thousand years ago.
''',
      ),
    ],
    'lit_les_miserables': [
      ChapterBlueprint(
        title: 'The Fall of Valjean',
        quoteHighlight: 'He had entered the galleys sobbing and trembling; he emerged hardened and grim.',
        quoteContext: 'Jean Valjean reaching Digne after 19 years of hard labor',
        content: '''
The passport was yellow, the color of infamy and danger. He wandered from door to door, but every latch was dropped against him. An outcast from mankind, exhausted, starving, and covered in road dust, he knocked at the modest door of the Bishop of Digne, expecting another curse and finding instead an open table.
''',
      ),
      ChapterBlueprint(
        title: 'The Bishop\'s Candlesticks',
        quoteHighlight: 'Jean Valjean, my brother: you belong no longer to evil, but to good. It is your soul that I am buying for you.',
        quoteContext: 'Monseigneur Bienvenu pardoning the theft of silver',
        content: '''
The gendarmes brought him back in chains. The bishop looked upon him with radiant eyes: 'You forgot that I gave you the silver candlesticks as well; why did you not take them along with your plates?' In that instant of unconditional grace, the hardened soul of Jean Valjean cracked, and the light of divine conscience was born.
''',
      ),
      ChapterBlueprint(
        title: 'Fantine',
        quoteHighlight: 'What is the history of Fantine? It is a society buying a slave from misery, from hunger, from cold, from loneliness.',
        quoteContext: 'The struggle of a devoted mother in Montreuil-sur-Mer',
        content: '''
She gave her hair, she gave her teeth, she gave everything for her little Cosette far away in Montfermeil. Even in the depths of sorrow, her maternal love burned like an inextinguishable star, calling upon the mysterious Monsieur Madeleine to protect her innocent child.
''',
      ),
      ChapterBlueprint(
        title: 'Javert\'s Pursuit',
        quoteHighlight: 'Inspector Javert was the personification of the law, devoid of mercy as the stone.',
        quoteContext: 'The unrelenting agent of justice shadowing Valjean',
        content: '''
To Javert, an infraction was an abyss. He knew neither compromise nor doubt; he was rectitude turned to iron. A human being who had once committed a crime could never again be innocent in his eyes, and he hunted Jean Valjean across decades with the patient cruelty of a bloodhound.
''',
      ),
      ChapterBlueprint(
        title: 'The Barricade',
        quoteHighlight: 'To die for what one loves is a great thing; to live for it is greater still.',
        quoteContext: 'The citizens and students rise in Paris in 1832',
        content: '''
The red flag flapped in the wind above the paving stones of the Rue de la Chanvrerie as the morning bugles blew. Enjolras stood upon the timber redoubt, calling the people to freedom, while Jean Valjean descended into the dark labyrinth of the sewers to carry the wounded Marius to safety.
''',
      ),
    ],
    'lit_odyssey': [
      ChapterBlueprint(
        title: 'The Council of Ithaca',
        quoteHighlight: 'Telemachus spoke, tears welling in his eyes: "My father\'s house is plundered and destroyed."',
        quoteContext: 'The prince confronting the arrogant suitors in assembly',
        content: '''
The old lords sat in silence, moved by the young prince\'s grief and righteous fury, while high in the cloudless sky two eagles wheeled and plunged, a sign sent by Zeus that vengeance was drawing near across the wine-dark sea.
''',
      ),
      ChapterBlueprint(
        title: 'The Cyclops Cave',
        quoteHighlight: 'My name is Nobody; my father, my mother, and all my friends call me Nobody.',
        quoteContext: 'Outwitting the monstrous Polyphemus with cunning',
        content: '''
When the monster fell into a heavy slumber, Odysseus and his comrades heated the sharpened olive wood stake in the embers. With a great surge of strength, they thrust the fiery point into the single eye of the giant, escaping under the fleecy bellies of his great rams when the dawn arrived.
''',
      ),
      ChapterBlueprint(
        title: 'Circe and the Underworld',
        quoteHighlight: 'There is no greater sorrow on earth than to hear the spirits of those who fell before us.',
        quoteContext: 'Summoning the shades of Achilles and Agamemnon',
        content: '''
The spirits rose like mist from the dark trench of libation, whispering of the glory and tragic vanity of mortal warfare. 'Better to be a hireling on earth,' cried Achilles, 'than to reign over all the dead in the kingdom of Hades.'
''',
      ),
      ChapterBlueprint(
        title: 'Scylla and Charybdis',
        quoteHighlight: 'Between the whirlpool and the cliff of six heads, courage alone could steer the helm.',
        quoteContext: 'Navigating the strait of terror',
        content: '''
The oarsmen wept as the beast struck from above, snatching six brave comrades from the rowing benches. Odysseus kept his blade drawn, fixing his eyes on the open sea, choosing the sacrifice of a few rather than the total destruction of his ship in the roaring maw of Charybdis.
''',
      ),
      ChapterBlueprint(
        title: 'The Great Bow',
        quoteHighlight: 'Like a musician stringing a lyre with ease, Odysseus bent the seasoned wood and let fly the arrow through the twelve axe-heads.',
        quoteContext: 'The return of the king in beggar\'s disguise',
        content: '''
The suitors froze in terror as the seasoned wood bent without effort and the bowstring sang sweet and high like a swallow. Tearing off his beggar's rags, Odysseus leaped onto the broad threshold, his quiver emptying at his feet: 'Dogs! You thought I would never return home from Troy!'
''',
      ),
    ],
    'lit_monte_cristo': [
      ChapterBlueprint(
        title: 'The Betrayal',
        quoteHighlight: 'Edmond Dantès was taken from the feast, suspecting no treason in the hearts of his comrades.',
        quoteContext: 'The false denunciation on his wedding day in Marseilles',
        content: '''
Danglars and Fernand watched in silence as the armed guard escorted the young captain away from his beloved Mercédès into the shadow. Villefort tore the compromising letter that mentioned his own father, and with a stroke of the pen condemned the innocent sailor to living death.
''',
      ),
      ChapterBlueprint(
        title: 'The Château d\'If',
        quoteHighlight: 'In the darkest dungeon, hope is the only torch that never burns out.',
        quoteContext: 'Fourteen years of imprisonment with Abbé Faria',
        content: '''
Through the subterranean tunnel scraped between stones, the aged Italian scholar passed on the heritage of centuries: languages, mathematics, philosophy, and the secret map to the buried millions of the Spada family on the deserted island of Monte Cristo.
''',
      ),
      ChapterBlueprint(
        title: 'The Treasure Island',
        quoteHighlight: 'Monte Cristo! The granite cave glittered with rubies, diamonds, and ancient gold.',
        quoteContext: 'Dantès claiming his vast fortune',
        content: '''
He raised his hands to heaven amidst the subterranean glow of emeralds and gold ingots: 'God has granted me this treasure to reward the good and punish the wicked!' Rising from the tomb of the sea, Edmond Dantès was born anew as the Count of Monte Cristo.
''',
      ),
      ChapterBlueprint(
        title: 'Parisian Society',
        quoteHighlight: 'The Count was a figure of marble, possessing all secrets and bending destiny to his will.',
        quoteContext: 'Infiltrating the high salons of his corrupt enemies',
        content: '''
Neither Danglars, now a wealthy banker, nor Fernand, now a decorated peer of France, recognized in the mysterious, pale nobleman with eyes of ice the innocent boy they had buried alive in the dungeons of Marseilles twenty-four years before.
''',
      ),
      ChapterBlueprint(
        title: 'Wait and Hope',
        quoteHighlight: 'All human wisdom is contained in these two words: Wait and Hope.',
        quoteContext: 'The Count\'s departure across the Mediterranean',
        content: '''
He had learned through suffering and remorse that absolute vengeance belongs to heaven alone, and that mercy restores peace to the human heart. As the white sails of his yacht disappeared into the golden horizon, he left his blessing to Maximilien and Valentine.
''',
      ),
    ],
  };

  static List<Literature> get _rawExpandedBooks => [
      // 9. Frankenstein (Mary Shelley)
      Literature(
        id: 'lit_frankenstein',
        title: 'Frankenstein',
        author: 'Mary Shelley',
        description: 'The pioneering gothic masterpiece. A brilliant young scientist infuses life into an assembled creature, only to be horrified by the moral and psychological consequences of his ambition.',
        type: LiteratureType.novel,
        genres: ['Gothic & Horror', 'Classics', 'Sci-Fi'],
        gemCost: 900,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'frk_ch1',
            chapterNumber: 1,
            title: 'The Spark of Being',
            estimatedMinutes: 5,
            quoteHighlight: 'It was on a dreary night of November that I beheld the accomplishment of my toils.',
            quoteContext: 'Victor infusing life into the creature',
            content: '''
It was on a dreary night of November that I beheld the accomplishment of my toils. With an anxiety that almost amounted to agony, I collected the instruments of life around me, that I might infuse a spark of being into the lifeless thing that lay at my feet. It was already one in the morning; the rain pattered dismally against the panes, and my candle was nearly burnt out, when, by the glimmer of the half-extinguished light, I saw the dull yellow eye of the creature open; it breathed hard, and a convulsive motion agitated its limbs.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'frk_lvl_1',
            literatureId: 'lit_frankenstein',
            levelNumber: 1,
            title: 'Chapter 1: The Spark of Being',
            description: 'Witness Victor Frankenstein breathing life into the creature.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
          QuestLevel(
            id: 'frk_lvl_2',
            literatureId: 'lit_frankenstein',
            levelNumber: 2,
            title: 'Recall: The Dreary November Night',
            description: 'Test your understanding of Shelley\'s gothic opening.',
            type: LevelType.recall,
            isCompleted: false,
            isLocked: true,
            gemsReward: 35,
            energyCost: 1,
            chapterIndex: 0,
            customQuestions: [
              const QuizQuestion(
                id: 'frk_q1',
                prompt: 'What physical sign first indicated that the creature had awakened?',
                options: ['Its dull yellow eye opened', 'A sudden loud cry', 'A glowing green aura', 'Its heart stopped'],
                correctAnswerIndex: 0,
                explanation: 'Shelley wrote that by the candle\'s glimmer, Victor saw the dull yellow eye of the creature open.',
              ),
            ],
          ),
        ],
      ),

      // 10. Dracula (Bram Stoker)
      Literature(
        id: 'lit_dracula',
        title: 'Dracula',
        author: 'Bram Stoker',
        description: 'The definitive vampire epic. Solicitor Jonathan Harker travels into the Carpathian mountains of Transylvania to finalize an estate purchase for the mysterious Count Dracula.',
        type: LiteratureType.novel,
        genres: ['Gothic & Horror', 'Mystery', 'Classics'],
        gemCost: 900,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'dra_ch1',
            chapterNumber: 1,
            title: 'Jonathan Harker’s Journal',
            estimatedMinutes: 5,
            quoteHighlight: 'Welcome to my house! Enter freely and of your own will!',
            quoteContext: 'Meeting the Count at the castle gates',
            content: '''
Left Munich at 8:35 P. M., on 1st May, arriving at Vienna early next morning. Budapest seems a wonderful place. The impression I had was that we were leaving the West and entering the East; the most western of splendid bridges over the Danube was leading us among the traditions of Turkish rule. The Count had directed me to go to the Golden Krone Hotel, which I found, to my great delight, to be thoroughly old-fashioned.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'dra_lvl_1',
            literatureId: 'lit_dracula',
            levelNumber: 1,
            title: 'Chapter 1: The Carpathian Road',
            description: 'Travel into Transylvania with Jonathan Harker.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 11. The Picture of Dorian Gray (Oscar Wilde)
      Literature(
        id: 'lit_dorian_gray',
        title: 'The Picture of Dorian Gray',
        author: 'Oscar Wilde',
        description: 'A philosophical gothic tale of vanity, art, and moral corruption. A handsome young man remains eternally youthful while his portrait bears the ugly marks of his sinful decay.',
        type: LiteratureType.novel,
        genres: ['Classics', 'Philosophy & Fables', 'Gothic & Horror'],
        gemCost: 850,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'dg_ch1',
            chapterNumber: 1,
            title: 'The Studio of Basil Hallward',
            estimatedMinutes: 5,
            quoteHighlight: 'There is only one thing in the world worse than being talked about, and that is not being talked about.',
            quoteContext: 'Lord Henry Wotton’s conversation with Basil',
            content: '''
The studio was filled with the rich odour of roses, and when the light summer wind stirred amidst the trees of the garden, there came through the open door the heavy scent of the lilac, or the more delicate perfume of the pink-flowering thorn. In the centre of the room, clamped to an upright easel, stood the full-length portrait of a young man of extraordinary personal beauty.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'dg_lvl_1',
            literatureId: 'lit_dorian_gray',
            levelNumber: 1,
            title: 'Chapter 1: The Portrait on the Easel',
            description: 'Admire Basil Hallward’s portrait before Lord Henry arrives.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 12. The Great Gatsby (F. Scott Fitzgerald)
      Literature(
        id: 'lit_great_gatsby',
        title: 'The Great Gatsby',
        author: 'F. Scott Fitzgerald',
        description: 'The quintessential portrait of the Roaring Twenties on Long Island. Nick Carraway is drawn into the lavish world and tragic obsession of the enigmatic Jay Gatsby.',
        type: LiteratureType.novel,
        genres: ['Classics', 'Romance & Society', 'Drama'],
        gemCost: 950,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'gg_ch1',
            chapterNumber: 1,
            title: 'The Green Light at the End of the Dock',
            estimatedMinutes: 5,
            quoteHighlight: 'In my younger and more vulnerable years my father gave me some advice that I’ve been turning over in my mind ever since.',
            quoteContext: 'Nick Carraway’s opening reflections',
            content: '''
In my younger and more vulnerable years my father gave me some advice that I’ve been turning over in my mind ever since. "Whenever you feel like criticizing any one," he told me, "just remember that all the people in this world haven’t had the advantages that you’ve had." He didn’t say any more, but we’ve always been unusually communicative in a reserved way, and I understood that he meant a great deal more than that.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'gg_lvl_1',
            literatureId: 'lit_great_gatsby',
            levelNumber: 1,
            title: 'Chapter 1: Advice from Father',
            description: 'Begin Nick Carraway’s summer in West Egg.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 13. Moby-Dick (Herman Melville)
      Literature(
        id: 'lit_moby_dick',
        title: 'Moby-Dick; or, The Whale',
        author: 'Herman Melville',
        description: 'An epic voyage of vengeance, fate, and obsession. Sailor Ishmael boards the Pequod under Captain Ahab, who is consumed by his quest to slay the monstrous white whale.',
        type: LiteratureType.novel,
        genres: ['Adventure & Chivalry', 'Classics', 'Philosophy & Fables'],
        gemCost: 1100,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'md_ch1',
            chapterNumber: 1,
            title: 'Loomings',
            estimatedMinutes: 5,
            quoteHighlight: 'Call me Ishmael. Some years ago—never mind how long precisely—having little or no money in my purse, and nothing particular to interest me on shore, I thought I would sail about a little.',
            quoteContext: 'The immortal opening lines',
            content: '''
Call me Ishmael. Some years ago—never mind how long precisely—having little or no money in my purse, and nothing particular to interest me on shore, I thought I would sail about a little and see the watery part of the world. It is a way I have of driving off the spleen and regulating the circulation. Whenever I find myself growing grim about the mouth; whenever it is a damp, drizzly November in my soul... then, I account it high time to get to sea as soon as I can.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'md_lvl_1',
            literatureId: 'lit_moby_dick',
            levelNumber: 1,
            title: 'Chapter 1: Loomings',
            description: 'Board the whaler in New Bedford with Ishmael.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 14. Treasure Island (Robert Louis Stevenson)
      Literature(
        id: 'lit_treasure_island',
        title: 'Treasure Island',
        author: 'Robert Louis Stevenson',
        description: 'The golden classic of high-seas piracy. Young Jim Hawkins discovers a pirate treasure map and embarks upon the Hispaniola, unaware that Long John Silver leads a mutinous crew.',
        type: LiteratureType.novel,
        genres: ['Adventure & Chivalry', 'Classics', 'Mystery'],
        gemCost: 800,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'ti_ch1',
            chapterNumber: 1,
            title: 'The Old Sea-dog at the Admiral Benbow',
            estimatedMinutes: 5,
            quoteHighlight: 'Fifteen men on the dead man’s chest—Yo-ho-ho, and a bottle of rum!',
            quoteContext: 'Billy Bones arrives at the inn',
            content: '''
Squire Trelawney, Dr. Livesey, and the rest of these gentlemen having asked me to write down the whole particulars about Treasure Island, from the beginning to the end, keeping nothing back but the bearings of the island, and that only because there is still treasure not yet lifted, I take up my pen in the year of grace 17__ and go back to the time when my father kept the Admiral Benbow inn and the brown old seaman with the sabre cut first took up his lodging under our roof.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'ti_lvl_1',
            literatureId: 'lit_treasure_island',
            levelNumber: 1,
            title: 'Chapter 1: The Admiral Benbow Inn',
            description: 'Meet the mysterious captain with the sea chest.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 15. The Strange Case of Dr Jekyll and Mr Hyde (Robert Louis Stevenson)
      Literature(
        id: 'lit_jekyll_hyde',
        title: 'The Strange Case of Dr Jekyll and Mr Hyde',
        author: 'Robert Louis Stevenson',
        description: 'The psychological exploration of humanity’s dual nature. The respectable Dr. Henry Jekyll brews a potion that unleashes his malevolent, cruel alter ego, Edward Hyde.',
        type: LiteratureType.novel,
        genres: ['Gothic & Horror', 'Mystery', 'Classics'],
        gemCost: 750,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'jh_ch1',
            chapterNumber: 1,
            title: 'Story of the Door',
            estimatedMinutes: 4,
            quoteHighlight: 'It was a nut to crack for many, what these two could see in each other.',
            quoteContext: 'Mr. Utterson’s Sunday walk',
            content: '''
Mr. Utterson the lawyer was a man of a rugged countenance that was never lighted by a smile; cold, scanty and embarrassed in discourse; backward in sentiment; lean, long, dusty, dreary and yet somehow lovable. At friendly meetings, and when the wine was to his taste, something eminently human beaconed from his eye.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'jh_lvl_1',
            literatureId: 'lit_jekyll_hyde',
            levelNumber: 1,
            title: 'Chapter 1: Story of the Door',
            description: 'Walk through London with Mr. Utterson and Mr. Enfield.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 4,
          ),
        ],
      ),

      // 16. The Count of Monte Cristo (Alexandre Dumas)
      Literature(
        id: 'lit_monte_cristo',
        title: 'The Count of Monte Cristo',
        author: 'Alexandre Dumas',
        description: 'The timeless saga of betrayal, escape, and calculating vengeance. Young sailor Edmond Dantès is falsely imprisoned in the Château d’If for fourteen years before escaping with a vast hidden treasure.',
        type: LiteratureType.novel,
        genres: ['Adventure & Chivalry', 'Classics', 'Drama'],
        gemCost: 1200,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'mc_ch1',
            chapterNumber: 1,
            title: 'Marseilles—The Arrival',
            estimatedMinutes: 5,
            quoteHighlight: 'On the 24th of February, 1815, the look-out at Notre-Dame de la Garde signalled the three-master, the Pharaon, from Smyrna, Trieste, and Naples.',
            quoteContext: 'The return of the ship Pharaon',
            content: '''
On the 24th of February, 1815, the look-out at Notre-Dame de la Garde signalled the three-master, the Pharaon, from Smyrna, Trieste, and Naples. As usual, a pilot put off immediately, and rounding the Château d\'If, got on board the vessel between Cape Morgion and Rion island.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'mc_lvl_1',
            literatureId: 'lit_monte_cristo',
            levelNumber: 1,
            title: 'Chapter 1: Arrival in Marseilles',
            description: 'Edmond Dantès steers the Pharaon into port.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 17. The Three Musketeers (Alexandre Dumas)
      Literature(
        id: 'lit_three_musketeers',
        title: 'The Three Musketeers',
        author: 'Alexandre Dumas',
        description: 'Swashbuckling chivalry and brotherhood in 17th-century France. Young d’Artagnan joins Athos, Porthos, and Aramis to defend the honour of the Queen against Cardinal Richelieu.',
        type: LiteratureType.novel,
        genres: ['Adventure & Chivalry', 'Classics'],
        gemCost: 950,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: '3m_ch1',
            chapterNumber: 1,
            title: 'The Three Presents of d’Artagnan the Elder',
            estimatedMinutes: 5,
            quoteHighlight: 'All for one, one for all!',
            quoteContext: 'The immortal motto of the King’s musketeers',
            content: '''
On the first Monday of the month of April, 1625, the market town of Meung, in which the author of Romance of the Rose was born, appeared to be in as perfect a state of revolution as if the Huguenots had just made a second Rochelle of it. Many citizens, seeing the women flying toward the High Street, leaving their children crying at the open doors, hastened to don the cuirass.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: '3m_lvl_1',
            literatureId: 'lit_three_musketeers',
            levelNumber: 1,
            title: 'Chapter 1: The Gascon Adventurer',
            description: 'd\'Artagnan rides his yellow pony toward Paris.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 18. Les Misérables (Victor Hugo)
      Literature(
        id: 'lit_les_miserables',
        title: 'Les Misérables',
        author: 'Victor Hugo',
        description: 'A monument of compassion, redemption, and justice. Ex-convict Jean Valjean strives for moral redemption while ruthlessly pursued by the unyielding Inspector Javert.',
        type: LiteratureType.novel,
        genres: ['Classics', 'Drama', 'Philosophy & Fables'],
        gemCost: 1200,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'lm_ch1',
            chapterNumber: 1,
            title: 'Monsieur Myriel',
            estimatedMinutes: 5,
            quoteHighlight: 'To love or have loved, that is enough. Ask nothing further. There is no other pearl to be found in the dark folds of life.',
            quoteContext: 'The Bishop of Digne’s grace',
            content: '''
In 1815, M. Charles-François-Bienvenu Myriel was Bishop of Digne. He was an old man of about seventy-five years of age; he had occupied the see of Digne since 1806. Although this detail has no connection whatever with the real substance of what we are about to relate, it will not be superfluous to mention here the rumors and conversations which had been current about him when he arrived in the diocese.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'lm_lvl_1',
            literatureId: 'lit_les_miserables',
            levelNumber: 1,
            title: 'Chapter 1: The Bishop of Digne',
            description: 'Meet the saintly Bishop who shelters Jean Valjean.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 19. Crime and Punishment (Fyodor Dostoevsky)
      Literature(
        id: 'lit_crime_punishment',
        title: 'Crime and Punishment',
        author: 'Fyodor Dostoevsky',
        description: 'The intense psychological crucible of guilt and spiritual resurrection. Impoverished student Rodion Raskolnikov commits murder to test his theory of extraordinary men.',
        type: LiteratureType.novel,
        genres: ['Classics', 'Philosophy & Fables', 'Mystery'],
        gemCost: 1100,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'cp_ch1',
            chapterNumber: 1,
            title: 'The St. Petersburg Heat',
            estimatedMinutes: 5,
            quoteHighlight: 'It takes something more than intelligence to act intelligently.',
            quoteContext: 'Raskolnikov leaving his garret',
            content: '''
On an exceptionally hot evening early in July a young man came out of the garret in which he lodged in S. Place and walked slowly, as though in hesitation, towards K. bridge. He had successfully avoided meeting his landlady on the staircase. His garret was under the roof of a high, five-storied house and was more like a cupboard than a room.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'cp_lvl_1',
            literatureId: 'lit_crime_punishment',
            levelNumber: 1,
            title: 'Chapter 1: The Garret in S. Place',
            description: 'Walk the humid streets of St. Petersburg with Raskolnikov.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 20. Wuthering Heights (Emily Brontë)
      Literature(
        id: 'lit_wuthering_heights',
        title: 'Wuthering Heights',
        author: 'Emily Brontë',
        description: 'The stormy tale of passionate, vengeful love on the desolate Yorkshire moors. Heathcliff and Catherine Earnshaw share an elemental, destructive bond.',
        type: LiteratureType.novel,
        genres: ['Classics', 'Gothic & Horror', 'Romance & Society'],
        gemCost: 850,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'wh_ch1',
            chapterNumber: 1,
            title: 'A Visit to Wuthering Heights',
            estimatedMinutes: 5,
            quoteHighlight: 'Whatever our souls are made of, his and mine are the same.',
            quoteContext: 'Mr. Lockwood visiting his brooding landlord Heathcliff',
            content: '''
1801.—I have just returned from a visit to my landlord—the solitary neighbour that I shall be troubled with. This is certainly a beautiful country! In all England, I do not believe that I could have fixed on a situation so completely removed from the stir of society. A perfect misanthropist’s heaven: and Mr. Heathcliff and I are such a suitable pair to divide the desolation between us.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'wh_lvl_1',
            literatureId: 'lit_wuthering_heights',
            levelNumber: 1,
            title: 'Chapter 1: The Moorland Threshold',
            description: 'Visit the windswept farmhouse of Heathcliff.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 21. Jane Eyre (Charlotte Brontë)
      Literature(
        id: 'lit_jane_eyre',
        title: 'Jane Eyre',
        author: 'Charlotte Brontë',
        description: 'An enduring tale of moral integrity, independence, and gothic passion. Orphan Jane Eyre becomes governess at Thornfield Hall and falls in love with the brooding Mr. Rochester.',
        type: LiteratureType.novel,
        genres: ['Classics', 'Romance & Society', 'Gothic & Horror'],
        gemCost: 850,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'je_ch1',
            chapterNumber: 1,
            title: 'Gateshead Hall',
            estimatedMinutes: 5,
            quoteHighlight: 'I am no bird; and no net ensnares me; I am a free human being with an independent will.',
            quoteContext: 'Jane sitting in the window-seat with Bewick’s Birds',
            content: '''
There was no possibility of taking a walk that day. We had been wandering, indeed, in the leafless shrubbery an hour in the morning; but since dinner (Mrs. Reed, when there was no company, dined early) the cold winter wind had brought with it clouds so sombre, and a rain so penetrating, that further outdoor exercise was now out of the question.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'je_lvl_1',
            literatureId: 'lit_jane_eyre',
            levelNumber: 1,
            title: 'Chapter 1: The Window-Seat Refuge',
            description: 'Seek solitude in the curtained recess of Gateshead.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 22. A Tale of Two Cities (Charles Dickens)
      Literature(
        id: 'lit_two_cities',
        title: 'A Tale of Two Cities',
        author: 'Charles Dickens',
        description: 'The monumental historical drama of London and Paris during the Reign of Terror. Sydney Carton makes the ultimate sacrifice for love upon the guillotine.',
        type: LiteratureType.novel,
        genres: ['Classics', 'Drama', 'Adventure & Chivalry'],
        gemCost: 900,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'ttc_ch1',
            chapterNumber: 1,
            title: 'The Period',
            estimatedMinutes: 5,
            quoteHighlight: 'It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness.',
            quoteContext: 'The famous opening cadence',
            content: '''
It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of light, it was the season of darkness, it was the spring of hope, it was the winter of despair.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'ttc_lvl_1',
            literatureId: 'lit_two_cities',
            levelNumber: 1,
            title: 'Chapter 1: The Best and Worst of Times',
            description: 'Contemplate the dualities of London and revolutionary Paris.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 23. Great Expectations (Charles Dickens)
      Literature(
        id: 'lit_great_expectations',
        title: 'Great Expectations',
        author: 'Charles Dickens',
        description: 'The coming-of-age masterwork of orphan Pip, who is plucked from the blacksmith forge by an anonymous benefactor to become a London gentleman.',
        type: LiteratureType.novel,
        genres: ['Classics', 'Drama'],
        gemCost: 850,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'ge_ch1',
            chapterNumber: 1,
            title: 'The Churchyard on the Marshes',
            estimatedMinutes: 5,
            quoteHighlight: 'My father’s family name being Pirrip, and my christian name Philip, my infant tongue could make of both names nothing longer or more explicit than Pip.',
            quoteContext: 'Pip meeting the convict Magwitch in the marshes',
            content: '''
My father’s family name being Pirrip, and my christian name Philip, my infant tongue could make of both names nothing longer or more explicit than Pip. So, I called myself Pip, and came to be called Pip. I give Pirrip as my father’s family name, on the authority of his tombstone and my sister—Mrs. Joe Gargery, who married the blacksmith.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'ge_lvl_1',
            literatureId: 'lit_great_expectations',
            levelNumber: 1,
            title: 'Chapter 1: The Marsh Graves',
            description: 'Meet the terrifying convict in the churchyard.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 24. The Odyssey (Homer)
      Literature(
        id: 'lit_odyssey',
        title: 'The Odyssey',
        author: 'Homer',
        description: 'The foundational epic of world literature. Follow the cunning Greek hero Odysseus on his perilous ten-year journey home from Troy past monsters, sirens, and angry gods.',
        type: LiteratureType.classic,
        genres: ['Adventure & Chivalry', 'Classics', 'Poetry & Verse'],
        gemCost: 1200,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'ody_ch1',
            chapterNumber: 1,
            title: 'Invocation to the Muse',
            estimatedMinutes: 5,
            quoteHighlight: 'Tell me, Muse, of the man of twists and turns driven time and again off course.',
            quoteContext: 'The poet appeals to the goddess of song',
            content: '''
Tell me, O Muse, of that ingenious hero who travelled far and wide after he had sacked the famous citadel of Troy. Many cities did he visit, and many were the nations with whose manners and customs he was acquainted; moreover he suffered much by sea while trying to save his own life and bring his men safely home; but do what he might he could not save his men, for they perished through their own sheer folly in eating the cattle of the sun-god Hyperion.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'ody_lvl_1',
            literatureId: 'lit_odyssey',
            levelNumber: 1,
            title: 'Book 1: Invocation to the Muse',
            description: 'Sing of Odysseus trapped on Calypso’s enchanted isle.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 25. The Iliad (Homer)
      Literature(
        id: 'lit_iliad',
        title: 'The Iliad',
        author: 'Homer',
        description: 'The wrath of Achilles outside the high walls of Ilium. An epic poem of honor, martial fury, tragic fate, and brotherhood in the Trojan War.',
        type: LiteratureType.classic,
        genres: ['Adventure & Chivalry', 'Classics', 'Poetry & Verse'],
        gemCost: 1200,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'ili_ch1',
            chapterNumber: 1,
            title: 'The Wrath of Achilles',
            estimatedMinutes: 5,
            quoteHighlight: 'Sing, goddess, the anger of Peleus’ son Achilles and its devastation.',
            quoteContext: 'Achilles withdraws from the Greek line',
            content: '''
Sing, O goddess, the anger of Achilles son of Peleus, that brought countless ills upon the Achaeans. Many a brave soul did it send hurrying down to Hades, and many a hero did it yield a prey to dogs and vultures, for so were the counsels of Jove fulfilled from the day on which the son of Atreus, king of men, and great Achilles, first fell out with one another.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'ili_lvl_1',
            literatureId: 'lit_iliad',
            levelNumber: 1,
            title: 'Book 1: Quarrel of the Kings',
            description: 'Witness Agamemnon and Achilles quarrel on the beach.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 26. Meditations (Marcus Aurelius)
      Literature(
        id: 'lit_meditations',
        title: 'Meditations',
        author: 'Marcus Aurelius',
        description: 'The personal philosophical journal of Rome’s philosopher-emperor. Timeless Stoic reflections on duty, emotional resilience, mortality, and tranquility.',
        type: LiteratureType.classic,
        genres: ['Philosophy & Fables', 'Classics'],
        gemCost: 850,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'med_ch1',
            chapterNumber: 1,
            title: 'Debts and Lessons',
            estimatedMinutes: 5,
            quoteHighlight: 'You have power over your mind—not outside events. Realize this, and you will find strength.',
            quoteContext: 'Reflections on virtue and teachers',
            content: '''
From my grandfather Verus I learned good morals and the government of my temper. From the reputation and remembrance of my father, modesty and a manly character. From my mother, piety and beneficence, and abstinence, not only from evil deeds, but even from evil thoughts; and further, simplicity in my way of living, far removed from the habits of the rich.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'med_lvl_1',
            literatureId: 'lit_meditations',
            levelNumber: 1,
            title: 'Book 1: Debts and Lessons',
            description: 'Reflect upon the teachers and virtues that shaped the Emperor.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 27. The Art of War (Sun Tzu)
      Literature(
        id: 'lit_art_of_war',
        title: 'The Art of War',
        author: 'Sun Tzu',
        description: 'The ancient Chinese treatise on military strategy, deception, and conflict resolution. The supreme art of war is to subdue the enemy without fighting.',
        type: LiteratureType.classic,
        genres: ['Philosophy & Fables', 'Classics'],
        gemCost: 700,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'aow_ch1',
            chapterNumber: 1,
            title: 'Laying Plans',
            estimatedMinutes: 4,
            quoteHighlight: 'All warfare is based on deception.',
            quoteContext: 'The five fundamental factors of conflict',
            content: '''
Sun Tzu said: The art of war is of vital importance to the State. It is a matter of life and death, a road either to safety or to ruin. Hence it is a subject of inquiry which can on no account be neglected. The moral law causes the people to be in complete accord with their ruler, so that they will follow him regardless of their lives, undismayed by any danger.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'aow_lvl_1',
            literatureId: 'lit_art_of_war',
            levelNumber: 1,
            title: 'Chapter 1: Laying Plans',
            description: 'Evaluate the five factors that determine strategic victory.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 4,
          ),
        ],
      ),

      // 28. The Prince (Niccolò Machiavelli)
      Literature(
        id: 'lit_the_prince',
        title: 'The Prince',
        author: 'Niccolò Machiavelli',
        description: 'The groundbreaking Renaissance manual of political realism and statecraft. An uncompromising examination of power, fortune, and whether it is better to be loved or feared.',
        type: LiteratureType.classic,
        genres: ['Philosophy & Fables', 'Classics'],
        gemCost: 750,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'prn_ch1',
            chapterNumber: 1,
            title: 'How Many Kinds of Principalities There Are',
            estimatedMinutes: 4,
            quoteHighlight: 'It is much safer to be feared than loved because love is preserved by the link of obligation which men will break whenever it suits them.',
            quoteContext: 'Machiavelli addresses Lorenzo de\' Medici',
            content: '''
All states, all powers, that have held and hold rule over men have been and are either republics or principalities. Principalities are either hereditary, in which the family has been long established; or they are new. The new are either entirely new, as was Milan to Francesco Sforza, or they are, as it were, members annexed to the hereditary state of the prince who has acquired them.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'prn_lvl_1',
            literatureId: 'lit_the_prince',
            levelNumber: 1,
            title: 'Chapter 1: The Nature of States',
            description: 'Analyze hereditary and acquired principalities.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 4,
          ),
        ],
      ),

      // 29. The Prophet (Kahlil Gibran)
      Literature(
        id: 'lit_the_prophet',
        title: 'The Prophet',
        author: 'Kahlil Gibran',
        description: 'A poetic masterpiece of spiritual wisdom. The prophet Almustafa shares poetic sermons on love, marriage, work, joy, sorrow, and freedom before sailing home.',
        type: LiteratureType.poem,
        genres: ['Philosophy & Fables', 'Poetry & Verse'],
        gemCost: 650,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'pro_ch1',
            chapterNumber: 1,
            title: 'The Coming of the Ship',
            estimatedMinutes: 4,
            quoteHighlight: 'Love gives naught but itself and takes naught but from itself. Love possesses not nor would it be possessed.',
            quoteContext: 'Almustafa gazes out to the sea of Orphalese',
            content: '''
Almustafa, the chosen and the beloved, who was a dawn unto his own day, had waited twelve years in the city of Orphalese for his ship that was to return and bear him back to the isle of his birth. And in the twelfth year, on the seventh day of Ielool, the month of reaping, he climbed the hill without the city walls and looked seaward; and he beheld his ship coming with the mist.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'pro_lvl_1',
            literatureId: 'lit_the_prophet',
            levelNumber: 1,
            title: 'Part 1: The Coming of the Ship',
            description: 'Ascend the hill of Orphalese as the white sails arrive.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 4,
          ),
        ],
      ),

      // 30. The Metamorphosis (Franz Kafka)
      Literature(
        id: 'lit_metamorphosis',
        title: 'The Metamorphosis',
        author: 'Franz Kafka',
        description: 'The defining surrealist allegory of modern alienation. Traveling salesman Gregor Samsa awakens one morning to find himself transformed into a monstrous insect.',
        type: LiteratureType.novel,
        genres: ['Classics', 'Philosophy & Fables'],
        gemCost: 800,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'meta_ch1',
            chapterNumber: 1,
            title: 'The Awakening of Gregor Samsa',
            estimatedMinutes: 5,
            quoteHighlight: 'One morning, when Gregor Samsa woke from troubled dreams, he found himself transformed in his bed into a horrible vermin.',
            quoteContext: 'The opening transformation',
            content: '''
One morning, when Gregor Samsa woke from troubled dreams, he found himself transformed in his bed into a horrible vermin. He lay on his armour-like back, and if he lifted his head a little he could see his brown belly, slightly domed and divided by arches into stiff sections. The bedding was hardly able to cover it and seemed ready to slide off any moment.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'meta_lvl_1',
            literatureId: 'lit_metamorphosis',
            levelNumber: 1,
            title: 'Chapter 1: The Monstrous Awakening',
            description: 'Discover Gregor Samsa on his domed shell back.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 31. The Call of the Wild (Jack London)
      Literature(
        id: 'lit_call_of_the_wild',
        title: 'The Call of the Wild',
        author: 'Jack London',
        description: 'The raw, primal tale of survival in the frozen Yukon. Buck, a pampered dog from California, is stolen and sold into the brutal world of Alaskan sled teams.',
        type: LiteratureType.novel,
        genres: ['Adventure & Chivalry', 'Classics'],
        gemCost: 750,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'cotw_ch1',
            chapterNumber: 1,
            title: 'Into the Primitive',
            estimatedMinutes: 5,
            quoteHighlight: 'Old longings nomadic leap, / Chafing at custom\'s chain; / Again from its brumal sleep / Wakens the ferine strain.',
            quoteContext: 'Opening poetic epigraph',
            content: '''
Buck did not read the newspapers, or he would have known that trouble was brewing, not alone for himself, but for every tide-water dog, strong of muscle and with warm, long hair, from Puget Sound to San Diego. Because men, groping in the Arctic darkness, had found a yellow metal, and because steamship and transportation companies were booming the find, thousands of men were rushing into the Northland.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'cotw_lvl_1',
            literatureId: 'lit_call_of_the_wild',
            levelNumber: 1,
            title: 'Chapter 1: Into the Primitive',
            description: 'Follow Buck from Judge Miller’s sunny estate to the Northland.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 32. The Adventures of Tom Sawyer (Mark Twain)
      Literature(
        id: 'lit_tom_sawyer',
        title: 'The Adventures of Tom Sawyer',
        author: 'Mark Twain',
        description: 'The golden American classic of boyhood along the Mississippi River. Tom whitewashes fences, hunts for pirate treasure with Huckleberry Finn, and explores McDougal’s cave.',
        type: LiteratureType.novel,
        genres: ['Adventure & Chivalry', 'Classics'],
        gemCost: 700,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'ts_ch1',
            chapterNumber: 1,
            title: 'Y-o-u-u Tom!',
            estimatedMinutes: 4,
            quoteHighlight: 'Work consists of whatever a body is obliged to do, and Play consists of whatever a body is not obliged to do.',
            quoteContext: 'Aunt Polly calling for Tom',
            content: '''
"TOM!" No answer. "TOM!" No answer. "What’s gone with that boy, I wonder? You TOM!" No answer. The old lady pulled her spectacles down and looked over them about the room; then she put them up and looked out under them. She seldom or never looked through them for so small a thing as a boy; they were her state pair, the pride of her heart, and were built for "style," not service.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'ts_lvl_1',
            literatureId: 'lit_tom_sawyer',
            levelNumber: 1,
            title: 'Chapter 1: Aunt Polly and the Closet',
            description: 'Catch Tom sneaking jam in Aunt Polly’s kitchen.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 4,
          ),
        ],
      ),

      // 33. Adventures of Huckleberry Finn (Mark Twain)
      Literature(
        id: 'lit_huck_finn',
        title: 'Adventures of Huckleberry Finn',
        author: 'Mark Twain',
        description: 'Ernest Hemingway declared all modern American literature comes from this one book. Huck Finn and runaway slave Jim raft down the mighty Mississippi River toward freedom.',
        type: LiteratureType.novel,
        genres: ['Adventure & Chivalry', 'Classics'],
        gemCost: 850,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'hf_ch1',
            chapterNumber: 1,
            title: 'Civilizing Huck',
            estimatedMinutes: 5,
            quoteHighlight: 'You don\'t know about me without you have read a book by the name of The Adventures of Tom Sawyer; but that ain\'t no matter.',
            quoteContext: 'Huck introducing his voice',
            content: '''
You don’t know about me without you have read a book by the name of The Adventures of Tom Sawyer; but that ain’t no matter. That book was made by Mr. Mark Twain, and he told the truth, mainly. There was things which he stretched, but mainly he told the truth. That is nothing. I never seen anybody but lied one time or another, without it was Aunt Polly, or the widow, or maybe Mary.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'hf_lvl_1',
            literatureId: 'lit_huck_finn',
            levelNumber: 1,
            title: 'Chapter 1: The Widow Douglas’s Household',
            description: 'Huck struggles with civilized life in St. Petersburg.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 34. The Jungle Book (Rudyard Kipling)
      Literature(
        id: 'lit_jungle_book',
        title: 'The Jungle Book',
        author: 'Rudyard Kipling',
        description: 'The Law of the Jungle in the Seeonee hills of India. Mowgli, the boy raised by wolves, learns survival from Baloo the bear and Bagheera the black panther.',
        type: LiteratureType.novel,
        genres: ['Adventure & Chivalry', 'Classics'],
        gemCost: 750,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'jb_ch1',
            chapterNumber: 1,
            title: 'Mowgli’s Brothers',
            estimatedMinutes: 5,
            quoteHighlight: 'Now this is the Law of the Jungle—as old and as true as the sky.',
            quoteContext: 'Father Wolf discovers the man-cub at the cave mouth',
            content: '''
It was seven o\'clock of a very warm evening in the Seeonee hills when Father Wolf woke up from his day\'s rest, scratched himself, yawned, and spread out his paws one after the other to get rid of the sleepy feeling in their tips. Mother Wolf lay with her big gray nose dropped across her four tumbling, squealing cubs, and the moon shone into the mouth of the cave where they all lived.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'jb_lvl_1',
            literatureId: 'lit_jungle_book',
            levelNumber: 1,
            title: 'Chapter 1: The Cave of the Seeonee Wolves',
            description: 'Mother Wolf protects the tiny naked man-cub from Shere Khan.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 35. Peter Pan and Wendy (J.M. Barrie)
      Literature(
        id: 'lit_peter_pan',
        title: 'Peter and Wendy',
        author: 'J.M. Barrie',
        description: 'The whimsical, bittersweet classic of Neverland, the boy who wouldn\'t grow up, Tinker Bell, Captain Hook, and the second star to the right.',
        type: LiteratureType.novel,
        genres: ['Classics', 'Adventure & Chivalry'],
        gemCost: 700,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'pan_ch1',
            chapterNumber: 1,
            title: 'Peter Breaks Through',
            estimatedMinutes: 5,
            quoteHighlight: 'All children, except one, grow up.',
            quoteContext: 'The legendary opening line',
            content: '''
All children, except one, grow up. They soon know that they will grow up, and the way Wendy knew was this. One day when she was two years old she was playing in a garden, and she plucked another flower and ran with it to her mother. I suppose she must have looked rather delightful, for Mrs. Darling put her hand to her heart and cried, "Oh, why can\'t you remain like this for ever!"
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'pan_lvl_1',
            literatureId: 'lit_peter_pan',
            levelNumber: 1,
            title: 'Chapter 1: The Darling Nursery',
            description: 'Meet Wendy, John, Michael, and Nana the Newfoundland nurse.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 36. Little Women (Louisa May Alcott)
      Literature(
        id: 'lit_little_women',
        title: 'Little Women',
        author: 'Louisa May Alcott',
        description: 'The heartwarming story of the four March sisters—Meg, Jo, Beth, and Amy—growing up in New England during the Civil War.',
        type: LiteratureType.novel,
        genres: ['Romance & Society', 'Classics'],
        gemCost: 750,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'lw_ch1',
            chapterNumber: 1,
            title: 'Playing Pilgrims',
            estimatedMinutes: 5,
            quoteHighlight: 'Christmas won’t be Christmas without any presents, grumbled Jo, lying on the rug.',
            quoteContext: 'The four sisters around the parlor fire',
            content: '''
"Christmas won’t be Christmas without any presents," grumbled Jo, lying on the rug. "It’s so dreadful to be poor!" sighed Meg, looking down at her old dress. "I don’t think it’s fair for some girls to have plenty of pretty things, and other girls nothing at all," added little Amy, with an injured sniff. "We’ve got Father and Mother, and each other," said Beth contentedly from her corner.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'lw_lvl_1',
            literatureId: 'lit_little_women',
            levelNumber: 1,
            title: 'Chapter 1: The March Parlor on Christmas Eve',
            description: 'Gather around the hearth with Meg, Jo, Beth, and Amy.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 37. Gulliver’s Travels (Jonathan Swift)
      Literature(
        id: 'lit_gulliver',
        title: 'Gulliver’s Travels',
        author: 'Jonathan Swift',
        description: 'The biting satire of human folly and pride. Lemuel Gulliver is shipwrecked upon the tiny island of Lilliput, the land of the giants in Brobdingnag, and the rational Houyhnhnms.',
        type: LiteratureType.novel,
        genres: ['Adventure & Chivalry', 'Classics', 'Philosophy & Fables'],
        gemCost: 800,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'gul_ch1',
            chapterNumber: 1,
            title: 'A Voyage to Lilliput',
            estimatedMinutes: 5,
            quoteHighlight: 'I felt something alive moving on my left leg, which advancing gently forward over my breast, came almost up to my chin; when, bending my eyes downward, I perceived it to be a human creature not six inches high.',
            quoteContext: 'Waking bound on the Lilliputian beach',
            content: '''
My father had a small estate in Nottinghamshire: I was the third of five sons. He sent me to Emanuel College in Cambridge at fourteen years old, where I resided three years, and applied myself close to my studies; but the charge of maintaining me, although I had a very scanty allowance, being too great for a narrow fortune, I was bound apprentice to Mr. James Bates, an eminent surgeon in London.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'gul_lvl_1',
            literatureId: 'lit_gulliver',
            levelNumber: 1,
            title: 'Part 1: The Awakening on the Beach',
            description: 'Awake tied to the earth by slender cords.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 38. Robinson Crusoe (Daniel Defoe)
      Literature(
        id: 'lit_robinson_crusoe',
        title: 'Robinson Crusoe',
        author: 'Daniel Defoe',
        description: 'The legendary tale of solitude, self-reliance, and survival. Shipwrecked on a desert island for twenty-eight years, Crusoe builds a fortress and befriends Friday.',
        type: LiteratureType.novel,
        genres: ['Adventure & Chivalry', 'Classics'],
        gemCost: 800,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'rc_ch1',
            chapterNumber: 1,
            title: 'Start in Life',
            estimatedMinutes: 5,
            quoteHighlight: 'I was born in the year 1632, in the city of York, of a good family, though not of that country.',
            quoteContext: 'Crusoe defying his father to go to sea',
            content: '''
I was born in the year 1632, in the city of York, of a good family, though not of that country, my father being a foreigner of Bremen, who settled first at Hull. He got a good estate by merchandise, and leaving off his trade, lived afterwards at York, from whence he had married my mother, whose relations were named Robinson, a very good family in that country, and from whom I was called Robinson Kreutznaer.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'rc_lvl_1',
            literatureId: 'lit_robinson_crusoe',
            levelNumber: 1,
            title: 'Chapter 1: The Sailor’s Itch',
            description: 'Defy fatherly counsel and embark from Hull on the fatal voyage.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 39. Heart of Darkness (Joseph Conrad)
      Literature(
        id: 'lit_heart_of_darkness',
        title: 'Heart of Darkness',
        author: 'Joseph Conrad',
        description: 'A chilling journey up the Congo River into the dark interior of colonial exploitation and the human soul, seeking the enigmatic ivory trader Kurtz.',
        type: LiteratureType.novel,
        genres: ['Classics', 'Philosophy & Fables'],
        gemCost: 800,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'hod_ch1',
            chapterNumber: 1,
            title: 'Aboard the Nellie on the Thames',
            estimatedMinutes: 5,
            quoteHighlight: 'The horror! The horror!',
            quoteContext: 'Marlow sitting cross-legged at sunset',
            content: '''
The Nellie, a cruising yawl, swung to her anchor without a flutter of the sails, and was at rest. The flood had made, the wind was nearly calm, and being bound down the river, the only thing for it was to come to and wait for the turn of the tide. The sea-reach of the Thames stretched before us like the beginning of an interminable waterway.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'hod_lvl_1',
            literatureId: 'lit_heart_of_darkness',
            levelNumber: 1,
            title: 'Chapter 1: The Gloom on the Estuary',
            description: 'Listen to Marlow’s tale as the sun sets over Gravesend.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 40. The War of the Worlds (H.G. Wells)
      Literature(
        id: 'lit_war_of_worlds',
        title: 'The War of the Worlds',
        author: 'H.G. Wells',
        description: 'The grandfather of alien invasion science fiction. Martian cylinders crash on Horsell Common, unleashing towering tripod fighting machines with heat-rays upon London.',
        type: LiteratureType.novel,
        genres: ['Sci-Fi', 'Classics', 'Adventure & Chivalry'],
        gemCost: 850,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'wow_ch1',
            chapterNumber: 1,
            title: 'The Eve of the War',
            estimatedMinutes: 5,
            quoteHighlight: 'No one would have believed in the last years of the nineteenth century that this world was being watched keenly and closely by intelligences greater than man’s.',
            quoteContext: 'The immortal opening prophecy',
            content: '''
No one would have believed in the last years of the nineteenth century that this world was being watched keenly and closely by intelligences greater than man\'s and yet as mortal as his own; that as men busied themselves about their various concerns they were scrutinised and studied, perhaps almost as narrowly as a man with a microscope might scrutinise the transient creatures that swarm and multiply in a drop of water.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'wow_lvl_1',
            literatureId: 'lit_war_of_worlds',
            levelNumber: 1,
            title: 'Chapter 1: The Eve of the War',
            description: 'Observe the green flashes on the red planet Mars.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 41. The Republic (Plato)
      Literature(
        id: 'lit_republic',
        title: 'The Republic',
        author: 'Plato',
        description: 'The supreme Socratic dialogue on justice, the philosopher king, the harmony of the soul, and the famous Allegory of the Cave.',
        type: LiteratureType.classic,
        genres: ['Philosophy & Fables', 'Classics'],
        gemCost: 900,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'rep_ch1',
            chapterNumber: 1,
            title: 'Descent to the Piraeus',
            estimatedMinutes: 5,
            quoteHighlight: 'I went down yesterday to the Piraeus with Glaucon the son of Ariston, that I might offer up my prayers to the goddess.',
            quoteContext: 'Socrates setting out the investigation of justice',
            content: '''
I went down yesterday to the Piraeus with Glaucon the son of Ariston, that I might offer up my prayers to the goddess; and also because I wanted to see in what manner they would celebrate the festival, which was a new thing. I was delighted with the procession of the inhabitants; but that of the Thracians was equally, if not more, beautiful.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'rep_lvl_1',
            literatureId: 'lit_republic',
            levelNumber: 1,
            title: 'Book 1: Justice and Cephalus',
            description: 'Inquire into the meaning of justice with Socrates.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),

      // 42. Walden (Henry David Thoreau)
      Literature(
        id: 'lit_walden',
        title: 'Walden; or, Life in the Woods',
        author: 'Henry David Thoreau',
        description: 'The transcendentalist manifesto of simple living, nature, and self-reliance at Walden Pond. "I went to the woods because I wished to live deliberately."',
        type: LiteratureType.classic,
        genres: ['Philosophy & Fables', 'Classics'],
        gemCost: 750,
        isOwned: false,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'wal_ch1',
            chapterNumber: 1,
            title: 'Economy',
            estimatedMinutes: 5,
            quoteHighlight: 'The mass of men lead lives of quiet desperation. What is called resignation is confirmed desperation.',
            quoteContext: 'Building the cabin beside Walden Pond',
            content: '''
When I wrote the following pages, or rather the bulk of them, I lived alone, in the woods, a mile from any neighbor, in a house which I had built myself, on the shore of Walden Pond, in Concord, Massachusetts, and earned my living by the labor of my hands only. I lived there two years and two months. At present I am a sojourner in civilized life again.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'wal_lvl_1',
            literatureId: 'lit_walden',
            levelNumber: 1,
            title: 'Chapter 1: Economy and Solitude',
            description: 'Enter the woods to live deliberately by the pond.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
            estimatedMinutes: 5,
          ),
        ],
      ),
    ];
}
