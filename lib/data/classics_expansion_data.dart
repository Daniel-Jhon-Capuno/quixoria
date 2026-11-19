import '../models/literature.dart';
import '../models/quest_level.dart';
import '../models/quiz_question.dart';

class ClassicsExpansionData {
  /// 1. Don Quixote de La Mancha (Miguel de Cervantes)
  static Literature getDonQuixote() {
    return Literature(
      id: 'lit_don_quixote',
      title: 'Don Quixote de la Mancha',
      author: 'Miguel de Cervantes',
      description:
          'The founding masterwork of Western literature. An eccentric country gentleman reads so many chivalric romances that he takes up lance and armor to revive knighthood, tilt at windmills, and right the wrongs of the world.',
      type: LiteratureType.novel,
      genres: ['Adventure & Chivalry', 'Classics', 'Philosophy & Fables'],
      gemCost: 1500,
      isOwned: false,
      currentLevelIndex: 0,
      chaptersCompleted: 0,
      gemsEarned: 0,
      totalChapters: 3,
      chapters: [
        const Chapter(
          id: 'dq_ch1',
          chapterNumber: 1,
          title: 'The Renowned Hidalgo and the Rusting Armour',
          estimatedMinutes: 5,
          quoteHighlight:
              'From little sleep and much reading, his brain dried up to such a degree that he came to lose his wits.',
          quoteContext: 'Alonso Quijano’s chivalric transformation',
          content: '''
In a village of La Mancha, the name of which I have no desire to call to mind, there lived not long since one of those gentlemen that keep a lance in the lance-rack, an old buckler, a lean hack, and a greyhound for coursing.

An olla of rather more beef than mutton, a salad on most nights, scraps on Saturdays, lentils on Fridays, and a pigeon or so extra on Sundays, made away with three-quarters of his income.

The age of this gentleman bordered upon fifty; he was of a hardy constitution, spare, gaunt of feature, a very early riser, and a great sportsman. You must know, then, that this gentleman, during every casual moment that he was at leisure, gave himself up to reading books of chivalry with so much relish and zest that he almost entirely neglected the pursuit of his field-sports, and even the management of his property.

His imagination became filled with everything he had read of enchantments, quarrels, battles, challenges, wounds, and courtly loves; and so firmly did he believe this whole fabric of visionary fancies to be true that in his eyes there was no more authentic history in the world!

The first thing he did was to clean up some armour that had belonged to his great-grandfather, and had been for ages lying forgotten in a corner, eaten with rust and covered with mildew. Having no helmet with a closed visor, he patched together a pasteboard face-guard with ribbons. Next, he visited his hack, and though it had more cracks in its hoofs than quarters in a real, he christened the steed Rocinante—a name lofty and sonorous! And finally, declaring that a knight without a lady was like a tree without leaves, he named a farm girl of Toboso: Dulcinea del Toboso!
''',
        ),
        const Chapter(
          id: 'dq_ch2',
          chapterNumber: 2,
          title: 'The Knighting at the Inn of Castles',
          estimatedMinutes: 5,
          quoteHighlight:
              'A knight-errant without the solemn accolade is like a ship without a rudder upon the boundless sea.',
          quoteContext: 'The midnight vigil over his armor',
          content: '''
These preliminaries being settled, he did not care to put off any longer the execution of his design. At the break of a scorching July dawn, without informing a soul, he sallied forth into the open country.

All that day he journeyed, until toward evening his hack and he were weary and dying of hunger. Looking eagerly on every side, he espied an inn near the road, which to his fancy seemed a castle with its four turrets and pinnacles of shining silver, complete with drawbridge and deep moat.

Approaching the gateway, he reined in Rocinante, waiting for some dwarf to appear upon the battlements and sound a trumpet announcing the arrival of a knight.

When the innkeeper—a man of peaceful disposition who quickly perceived his guest’s madness—came out, Don Quixote fell upon his knees and declared: "Never shall I rise from this ground until thy courtesy grants the boon I seek: that thou shalt dub me knight, having this night kept vigil over mine armour in the chapel of thy castle!"

The innkeeper agreed to humour him, warning him that the castle chapel had unfortunately been torn down to build a new one, but that a vigil in the open courtyard was equally acceptable under the strict laws of knighthood. Placing his rusty armor upon a stone horse-trough beside the well, Don Quixote paced back and forth with measured step, gripping his lance, beneath the silver rays of the moon.
''',
        ),
        const Chapter(
          id: 'dq_ch3',
          chapterNumber: 3,
          title: 'The Monstrous Giants of Montiel (Tilting at Windmills)',
          estimatedMinutes: 5,
          quoteHighlight:
              'Look there, friend Sancho Panza, where thirty or more monstrous giants present themselves with long arms!',
          quoteContext: 'The famous charge upon the windmills',
          content: '''
Having enlisted his neighbor, an honest peasant named Sancho Panza, with the promise of governorship over an island, Don Quixote rode forward into the plains of Montiel.

At this point they came in sight of thirty or forty windmills that rise from that vast Spanish plain. As soon as Don Quixote saw them, he said to his squire:

"Fortune is guiding our affairs better than we could have hoped; for look there, friend Sancho Panza, where thirty or more monstrous giants present themselves, with whom I mean to engage in battle and slay every one of them, and with their spoils we will begin to grow rich; for this is lawful warfare, and it is doing God great service to sweep so evil a breed from off the face of the earth!"

"What giants?" asked Sancho Panza in bewilderment.

"Those thou seest there," answered his master, "with the long arms, and some have them nearly two leagues long."

"Look, your worship," said Sancho; "what we see there are not giants but windmills, and what seem to be arms are the sails that turn with the wind to make the millstone grind."

"It is easy to see," replied Don Quixote, "that thou art not used to this business of adventures; those are giants; and if thou art afraid, away with thee out of this and betake thee to prayer while I engage them in fierce and unequal combat!"

And so saying, he gave spur to his steed Rocinante, couched his lance, and charged at full gallop against the first windmill. As the wind caught the sail, the great wooden blade shattered his lance into splinters, lifting both horse and knight high into the air and dashing them rolling across the stony plain!
''',
        ),
      ],
      questLevels: [
        // Level 1: Read Chapter 1
        QuestLevel(
          id: 'dq_lvl_1',
          literatureId: 'lit_don_quixote',
          levelNumber: 1,
          title: 'Chapter 1: The Renowned Hidalgo',
          description: 'Meet Alonso Quijano and his transformation into a knight.',
          type: LevelType.read,
          isCompleted: false,
          isLocked: false,
          gemsReward: 30,
          chapterIndex: 0,
          estimatedMinutes: 5,
        ),
        // Level 2: Recall Quiz
        QuestLevel(
          id: 'dq_lvl_2',
          literatureId: 'lit_don_quixote',
          levelNumber: 2,
          title: 'Recall: The Knight’s Genesis',
          description: 'Test your understanding of Quixote’s origin and steed.',
          type: LevelType.recall,
          isCompleted: false,
          isLocked: true,
          gemsReward: 35,
          energyCost: 1,
          chapterIndex: 0,
          customQuestions: [
            const QuizQuestion(
              id: 'dq_lvl2_q1',
              prompt: 'What was the original social status of the gentleman before his transformation?',
              options: [
                'A country hidalgo (gentleman) of modest means',
                'A wealthy Spanish grandee and duke',
                'A royal inquisitor from Madrid',
                'A Franciscan friar',
              ],
              correctAnswerIndex: 0,
              explanation: 'Alonso Quijano was a modest hidalgo living on lean fare in the dry plains of La Mancha.',
            ),
            const QuizQuestion(
              id: 'dq_lvl2_q2',
              prompt: 'What caused Don Quixote to lose his wits according to Cervantes?',
              options: [
                'Reading countless romances of chivalry with little sleep',
                'A fever contracted during a voyage to the Americas',
                'A head wound sustained during the Battle of Lepanto',
                'A curse cast by a jealous enchanter',
              ],
              correctAnswerIndex: 0,
              explanation: 'His obsession with chivalric books dried his brain until he believed romances were absolute historical fact.',
            ),
            const QuizQuestion(
              id: 'dq_lvl2_q3',
              prompt: 'What lofty name did he bestow upon his lean, bony hack of a horse?',
              options: [
                'Rocinante',
                'Bucephalus',
                'Babieca',
                'Pegasus',
              ],
              correctAnswerIndex: 0,
              explanation: 'He chose Rocinante, meaning formerly a common hack ("rocín"), now chief of all hacks in the world.',
            ),
          ],
        ),
        // Level 3: Practice Drill (Vocabulary)
        QuestLevel(
          id: 'dq_lvl_3',
          literatureId: 'lit_don_quixote',
          levelNumber: 3,
          title: 'Practice: Chivalric Vocab & Terms',
          description: 'Master archaic vocabulary: Hidalgo, buckler, hack, and pasteboard.',
          type: LevelType.practice,
          isCompleted: false,
          isLocked: true,
          gemsReward: 25,
          energyCost: 0,
          chapterIndex: 0,
          customQuestions: [
            const QuizQuestion(
              id: 'dq_lvl3_q1',
              prompt: 'What is a "buckler" in medieval knightly armament?',
              options: [
                'A small, round shield held in the hand or gripped on the forearm',
                'A heavy iron helmet with breathing holes',
                'A dagger strapped to the knightly boot',
                'A velvet saddlecloth embroidered with silver',
              ],
              correctAnswerIndex: 0,
              explanation: 'A buckler was a compact round shield used to parry swords and deflect strikes.',
            ),
            const QuizQuestion(
              id: 'dq_lvl3_q2',
              prompt: 'Why did Don Quixote reinforce his rusted morion with "pasteboard"?',
              options: [
                'To create a makeshift face-guard visor where only an open cap existed',
                'To pad the interior against the blazing summer sun',
                'To display his family coat of arms in bright paint',
                'To muffle the sound of his heavy breathing',
              ],
              correctAnswerIndex: 0,
              explanation: 'His antique helmet had no visor, so he ingeniously built a simulated faceguard from pasteboard and ribbons.',
            ),
          ],
        ),
        // Level 4: Read Chapter 2
        QuestLevel(
          id: 'dq_lvl_4',
          literatureId: 'lit_don_quixote',
          levelNumber: 4,
          title: 'Chapter 2: The Inn of Castles',
          description: 'Follow Don Quixote as he seeks knighthood at a roadside inn.',
          type: LevelType.read,
          isCompleted: false,
          isLocked: true,
          gemsReward: 30,
          chapterIndex: 1,
          estimatedMinutes: 5,
        ),
        // Level 5: Recall Quiz
        QuestLevel(
          id: 'dq_lvl_5',
          literatureId: 'lit_don_quixote',
          levelNumber: 5,
          title: 'Recall: The Courtyard Vigil',
          description: 'Understand the satirical knighting ceremony by the well.',
          type: LevelType.recall,
          isCompleted: false,
          isLocked: true,
          gemsReward: 35,
          energyCost: 1,
          chapterIndex: 1,
          customQuestions: [
            const QuizQuestion(
              id: 'dq_lvl5_q1',
              prompt: 'What did Don Quixote mistake the roadside inn for?',
              options: [
                'A grand turreted castle with silver pinnacles and a drawbridge',
                'A fortified dungeon where maidens were imprisoned',
                'An imperial palace of the King of Aragon',
                'An enchanted maze populated by sorcerers',
              ],
              correctAnswerIndex: 0,
              explanation: 'Through the prism of his romance novels, every humble inn became an impregnable castle.',
            ),
            const QuizQuestion(
              id: 'dq_lvl5_q2',
              prompt: 'Where did Quixote stand his solemn midnight armor vigil?',
              options: [
                'Over a horse-trough beside the courtyard well',
                'In the chapel beneath an altar of St. James',
                'On top of the inn’s kitchen chimney',
                'Inside the tavern wine cellar',
              ],
              correctAnswerIndex: 0,
              explanation: 'Because the inn had no chapel, the innkeeper humored him by having him guard his armor upon a horse-trough.',
            ),
          ],
        ),
        // Level 6: Read Chapter 3
        QuestLevel(
          id: 'dq_lvl_6',
          literatureId: 'lit_don_quixote',
          levelNumber: 6,
          title: 'Chapter 3: The Monstrous Windmills',
          description: 'Experience the legendary battle on the plains of Montiel.',
          type: LevelType.read,
          isCompleted: false,
          isLocked: true,
          gemsReward: 30,
          chapterIndex: 2,
          estimatedMinutes: 5,
        ),
        // Level 7: Recall Quiz
        QuestLevel(
          id: 'dq_lvl_7',
          literatureId: 'lit_don_quixote',
          levelNumber: 7,
          title: 'Recall: The Tilt at Montiel',
          description: 'Analyze Sancho’s warning and the enchanter Friston.',
          type: LevelType.recall,
          isCompleted: false,
          isLocked: true,
          gemsReward: 35,
          energyCost: 1,
          chapterIndex: 2,
          customQuestions: [
            const QuizQuestion(
              id: 'dq_lvl7_q1',
              prompt: 'What did Sancho Panza point out to his master before the charge?',
              options: [
                'That the giants were merely grain-grinding windmills with sail arms',
                'That his horse was too lame to carry a lance',
                'That rain was approaching over the mountains',
                'That bandits were waiting in ambush',
              ],
              correctAnswerIndex: 0,
              explanation: 'Sancho repeatedly warned that the figures were windmills whose sails turned with the breeze.',
            ),
            const QuizQuestion(
              id: 'dq_lvl7_q2',
              prompt: 'How did Don Quixote explain the fact that the giants turned into windmills after his crash?',
              options: [
                'The wicked magician Friston transformed them to rob him of glory',
                'He admitted Sancho was right and apologized',
                'He claimed the windmills were mechanical automatons built by Moors',
                'He blamed Rocinante for stumbling over a boulder',
              ],
              correctAnswerIndex: 0,
              explanation: 'Quixote insisted the enchanter Friston had altered their shapes at the last instant to rob him of triumph.',
            ),
          ],
        ),
        // Level 8: Practice Drill
        QuestLevel(
          id: 'dq_lvl_8',
          literatureId: 'lit_don_quixote',
          levelNumber: 8,
          title: 'Practice: Symbolism & Satire',
          description: 'Explore the deeper meaning behind Cervantes’ chivalric satire.',
          type: LevelType.analysis,
          isCompleted: false,
          isLocked: true,
          gemsReward: 25,
          energyCost: 0,
          chapterIndex: 2,
          customQuestions: [
            const QuizQuestion(
              id: 'dq_lvl8_q1',
              prompt: 'What modern English idiom derives directly from this famous episode?',
              options: [
                '"Tilting at windmills" — attacking imaginary or insurmountable adversaries',
                '"Biting the bullet" — enduring painful hardships with courage',
                '"Spilling the beans" — revealing an unexpected secret',
                '"A feather in one’s cap" — earning an honorable distinction',
              ],
              correctAnswerIndex: 0,
              explanation: '"Tilting at windmills" has become the world’s defining idiom for pursuing idealistic, futile battles.',
            ),
          ],
        ),
        // Level 9: Reading Review
        QuestLevel(
          id: 'dq_lvl_9',
          literatureId: 'lit_don_quixote',
          levelNumber: 9,
          title: 'Grand Review: The Chivalric Code',
          description: 'Review the themes of honor, imagination, and madness vs wisdom.',
          type: LevelType.read,
          isCompleted: false,
          isLocked: true,
          gemsReward: 30,
          chapterIndex: 0,
          estimatedMinutes: 4,
        ),
        // Level 10: Final Boss Assessment
        QuestLevel(
          id: 'dq_lvl_10',
          literatureId: 'lit_don_quixote',
          levelNumber: 10,
          title: 'Final Trial: The Knight of the Sorrowful Countenance',
          description: 'Prove thy total mastery of Cervantes’ opening masterpiece.',
          type: LevelType.finalTest,
          isCompleted: false,
          isLocked: true,
          gemsReward: 100,
          energyCost: 2,
          chapterIndex: 2,
          customQuestions: [
            const QuizQuestion(
              id: 'dq_lvl10_q1',
              prompt: 'What promise persuaded the practical peasant Sancho Panza to become Quixote’s squire?',
              options: [
                'The future governorship of an insula (island)',
                'A heavy bag of Moorish gold doubloons',
                'A herd of prize Andalusian cattle',
                'Freedom from municipal agricultural taxes',
              ],
              correctAnswerIndex: 0,
              explanation: 'Quixote promised Sancho that one day he would win an island and make him governor.',
            ),
            const QuizQuestion(
              id: 'dq_lvl10_q2',
              prompt: 'What is the real identity of the peerless lady Dulcinea del Toboso?',
              options: [
                'Aldonza Lorenzo, a robust country farm girl who salted pork',
                'A Spanish duchess residing in Seville',
                'The innkeeper’s runaway daughter',
                'A fictional character invented purely from Amadis of Gaul',
              ],
              correctAnswerIndex: 0,
              explanation: 'Her real name was Aldonza Lorenzo, a peasant girl whom Quixote idealized into a courtly princess.',
            ),
            const QuizQuestion(
              id: 'dq_lvl10_q3',
              prompt: 'In literary history, what groundbreaking milestone does Don Quixote represent?',
              options: [
                'Widely considered the first modern novel in world literature',
                'The first printed religious drama in Castilian',
                'The earliest recorded collection of animal fables',
                'The first sonnet cycle translated into Latin',
              ],
              correctAnswerIndex: 0,
              explanation: 'Published in 1605, Cervantes’ Don Quixote is globally celebrated as the first modern psychological novel.',
            ),
          ],
        ),
      ],
      recallQuizzes: {},
      practiceQuizzes: {},
      finalExam: [],
    );
  }

  /// 2. Sherlock Holmes: A Study in Scarlet (Arthur Conan Doyle)
  static Literature getStudyInScarlet() {
    return Literature(
      id: 'lit_study_in_scarlet',
      title: 'A Study in Scarlet',
      author: 'Sir Arthur Conan Doyle',
      description:
          'The historic debut of Sherlock Holmes and Dr. John H. Watson. From the chemistry benches of Bart’s Hospital to 221B Baker Street, the world’s first consulting detective demonstrates the razor-sharp science of deduction.',
      type: LiteratureType.novel,
      genres: ['Mystery & Sleuthing', 'Classics', 'Adventure & Chivalry'],
      gemCost: 800,
      isOwned: false,
      currentLevelIndex: 0,
      chaptersCompleted: 0,
      gemsEarned: 0,
      totalChapters: 3,
      chapters: [
        const Chapter(
          id: 'sis_ch1',
          chapterNumber: 1,
          title: 'Mr. Sherlock Holmes and the Criterion Bar',
          estimatedMinutes: 5,
          quoteHighlight:
              'You have been in Afghanistan, I perceive.',
          quoteContext: 'Holmes’ legendary first words upon meeting Dr. Watson',
          content: '''
In the year 1878 I took my degree of Doctor of Medicine of the University of London, and proceeded to Netley to go through the course prescribed for army surgeons. Completing my studies there, I was duly attached to the Fifth Northumberland Fusiliers as Assistant Surgeon.

The campaign in Afghanistan brought honors and promotion to many, but for me it had nothing but misfortune and disaster. I was struck on the shoulder by a Jezail bullet, which shattered the bone and grazed the subclavian artery. Worn with pain and weak from prolonged hardships, I was shipped back to England on the troopship Orontes.

I had neither kith nor kin in England, and was therefore as free as air—or as free as an income of eleven shillings and sixpence a day will permit a man to be. Under such circumstances, I naturally gravitated to London, that great cesspool into which all the loungers and idlers of the Empire are irresistibly drained.

One day, standing at the Criterion Bar, someone tapped me on the shoulder, and turning round I recognized young Stamford, who had been a dresser under me at Barts. I confided to him my urgent desire to find modest lodgings that would not overtax my slender military pension.

"A fellow who is working at the chemical laboratory up at the hospital was making the same complaint," remarked Stamford. "He cannot get someone to go halves with him in some nice rooms which he has found."

Stamford led me into the echoing chemical laboratory of St. Bartholomew’s. There, leaping from a table with a test-tube in hand, stood a tall, lean gentleman with hawk-like eyes.

"I\'ve found it! I\'ve found it!" he shouted to my companion. Then, turning his gaze sharply upon me, he seized my hand with surprising strength:

"How are you?" he said cordially. "You have been in Afghanistan, I perceive."
''',
        ),
        const Chapter(
          id: 'sis_ch2',
          chapterNumber: 2,
          title: 'The Science of Deduction at 221B Baker Street',
          estimatedMinutes: 5,
          quoteHighlight:
              'From a drop of water, a logician could infer the possibility of an Atlantic or a Niagara without having seen either.',
          quoteContext: 'Holmes’ philosophy of forensic observation',
          content: '''
We met next day and inspected the rooms at No. 221B, Baker Street. They consisted of two comfortable bedrooms and a single large airy sitting-room, cheerfully lighted by two broad windows, and furnished with that comfortable Victorian clutter which suited our bachelor tastes.

As the weeks passed, my curiosity regarding my companion’s strange profession increased. He was not studying medicine; he had no interest in contemporary politics, astronomy, or philosophy; yet his knowledge of chemistry was profound, his acquaintance with sensational criminal history encyclopedic, and he played the violin with extraordinary melancholy brilliance.

One morning over breakfast, I came across a magazine article titled "The Book of Life." It asserted that an observant man could glean an individual’s trade, history, and secret grief simply by examining his fingertips, trouser knees, and coat cuffs.

"What ineffable twaddle!" I cried, slapping the journal on the table.

"I wrote that article myself," said Holmes calmly. "What you do not understand is that observation with me is second nature. When I met you, my observation showed that you were an army doctor: you had an air of military precision, your skin was dark yet your wrists were pale (showing you were back from the tropics), your face was drawn showing severe illness, and you held your left arm stiffly from an injury. Where in the tropics could an English army doctor have endured such hardships and been wounded in the arm? Clearly in Afghanistan!"
''',
        ),
        const Chapter(
          id: 'sis_ch3',
          chapterNumber: 3,
          title: 'The Lauriston Garden Mystery and RACHE',
          estimatedMinutes: 5,
          quoteHighlight:
              'There is no crime so vulgar that a discerning mind cannot extract its scientific lesson.',
          quoteContext: 'Arrival at the abandoned Brixton crime scene',
          content: '''
A telegram from Tobias Gregson of Scotland Yard summoned Holmes to an empty house at No. 3, Lauriston Gardens, off the Brixton Road. A terrible murder had taken place without any sign of a struggle, robbery, or weapon.

Holmes sprang out of our four-wheeler cab, whipped out a magnifying glass and a tape measure, and spent twenty minutes on his knees upon the muddy pavement outside, measuring wheel ruts and hoofprints with feverish concentration.

Inside the dingy parlor, upon the dusty boards, lay the body of a well-dressed gentleman contorted in horror. His face was twisted in an expression of dread so profound that it chilled my blood. Upon the yellow papered wall, scrawled in dark red letters that looked like dried blood, was a single word:

RACHE.

"Aha!" exclaimed Inspector Lestrade triumphantly. "The murderer was a woman named Rachel, who was disturbed before she could write the final letter!"

Holmes shook his head with a mocking smile. "Do not waste your time seeking a woman named Rachel, Inspector. \'Rache\' is the German word for revenge. The murderer is a tall man, under forty years of age, who has small feet for his height, wears square-toed boots, smokes a Trichinopoly cigar, and came here in a four-wheeled cab with a horse that has three old shoes and one new one on its off foreleg. Furthermore, the dead man was poisoned!"
''',
        ),
      ],
      questLevels: [
        // Level 1: Read Chapter 1
        QuestLevel(
          id: 'sis_lvl_1',
          literatureId: 'lit_study_in_scarlet',
          levelNumber: 1,
          title: 'Chapter 1: The Criterion Meeting',
          description: 'Meet Dr. Watson after the Afghan campaign and his fateful meeting with Holmes.',
          type: LevelType.read,
          isCompleted: false,
          isLocked: false,
          gemsReward: 30,
          chapterIndex: 0,
          estimatedMinutes: 5,
        ),
        // Level 2: Recall Quiz
        QuestLevel(
          id: 'sis_lvl_2',
          literatureId: 'lit_study_in_scarlet',
          levelNumber: 2,
          title: 'Recall: Meeting the Detective',
          description: 'Test your memory of Holmes’ first deduction.',
          type: LevelType.recall,
          isCompleted: false,
          isLocked: true,
          gemsReward: 35,
          energyCost: 1,
          chapterIndex: 0,
          customQuestions: [
            const QuizQuestion(
              id: 'sis_lvl2_q1',
              prompt: 'Where was Dr. John Watson wounded prior to returning to London?',
              options: [
                'In the Second Anglo-Afghan War (Battle of Maiwand)',
                'In the Crimean War outside Sevastopol',
                'In the Boer War in South Africa',
                'In a naval duel in the Mediterranean',
              ],
              correctAnswerIndex: 0,
              explanation: 'Watson was an assistant surgeon struck by a Jezail bullet in Afghanistan.',
            ),
            const QuizQuestion(
              id: 'sis_lvl2_q2',
              prompt: 'What were Sherlock Holmes’ historic first words to Dr. Watson?',
              options: [
                '"You have been in Afghanistan, I perceive."',
                '"Elementary, my dear Watson."',
                '"The game is afoot, gentleman."',
                '"Do you object to tobacco smoke?"',
              ],
              correctAnswerIndex: 0,
              explanation: 'Holmes immediately deduced Watson’s recent deployment from subtle physical cues.',
            ),
          ],
        ),
        // Level 3: Practice Drill (Deduction Science)
        QuestLevel(
          id: 'sis_lvl_3',
          literatureId: 'lit_study_in_scarlet',
          levelNumber: 3,
          title: 'Practice: The Science of Deduction',
          description: 'Analyze Holmes’ method of forensic reasoning.',
          type: LevelType.practice,
          isCompleted: false,
          isLocked: true,
          gemsReward: 25,
          energyCost: 0,
          chapterIndex: 0,
          customQuestions: [
            const QuizQuestion(
              id: 'sis_lvl3_q1',
              prompt: 'What was Holmes testing in the Bart’s laboratory when Watson met him?',
              options: [
                'A chemical reagent that precipitates exclusively with blood haemoglobin',
                'A new anesthetic formula for surgical operations',
                'A poison derived from South American curare',
                'A method of developing photographic glass plates',
              ],
              correctAnswerIndex: 0,
              explanation: 'Holmes had just discovered a foolproof reagent that reacts only to blood stains.',
            ),
          ],
        ),
        // Level 4: Read Chapter 2
        QuestLevel(
          id: 'sis_lvl_4',
          literatureId: 'lit_study_in_scarlet',
          levelNumber: 4,
          title: 'Chapter 2: 221B Baker Street',
          description: 'Step into the famous lodgings and learn Holmes’ unique limits of knowledge.',
          type: LevelType.read,
          isCompleted: false,
          isLocked: true,
          gemsReward: 30,
          chapterIndex: 1,
          estimatedMinutes: 5,
        ),
        // Level 5: Recall Quiz
        QuestLevel(
          id: 'sis_lvl_5',
          literatureId: 'lit_study_in_scarlet',
          levelNumber: 5,
          title: 'Recall: The Brain-Attic Theory',
          description: 'Examine Holmes’ theory of mental memory preservation.',
          type: LevelType.recall,
          isCompleted: false,
          isLocked: true,
          gemsReward: 35,
          energyCost: 1,
          chapterIndex: 1,
          customQuestions: [
            const QuizQuestion(
              id: 'sis_lvl5_q1',
              prompt: 'What common scientific fact did Holmes proudly claim NOT to know in Chapter 2?',
              options: [
                'That the Earth travels around the Sun (heliocentric theory)',
                'The chemical composition of gunpowder',
                'The names of the Kings of England',
                'The boiling point of water',
              ],
              correctAnswerIndex: 0,
              explanation: 'Holmes considered the human brain an empty attic and refused to store trivia that did not aid criminal investigation.',
            ),
          ],
        ),
        // Level 6: Read Chapter 3
        QuestLevel(
          id: 'sis_lvl_6',
          literatureId: 'lit_study_in_scarlet',
          levelNumber: 6,
          title: 'Chapter 3: The Lauriston Mystery',
          description: 'Investigate the Brixton crime scene and the word written on the wall.',
          type: LevelType.read,
          isCompleted: false,
          isLocked: true,
          gemsReward: 30,
          chapterIndex: 2,
          estimatedMinutes: 5,
        ),
        // Level 7: Recall Quiz
        QuestLevel(
          id: 'sis_lvl_7',
          literatureId: 'lit_study_in_scarlet',
          levelNumber: 7,
          title: 'Recall: The Clue of RACHE',
          description: 'Deconstruct the inspectors’ blunders versus Holmes’ deduction.',
          type: LevelType.recall,
          isCompleted: false,
          isLocked: true,
          gemsReward: 35,
          energyCost: 1,
          chapterIndex: 2,
          customQuestions: [
            const QuizQuestion(
              id: 'sis_lvl7_q1',
              prompt: 'What did the German word "RACHE" scrawled on the wall translate to?',
              options: [
                'Revenge',
                'Blood',
                'Curse',
                'Justice',
              ],
              correctAnswerIndex: 0,
              explanation: 'Lestrade mistook it for the female name Rachel, but Holmes recognized it as the German word for revenge.',
            ),
          ],
        ),
        // Level 8: Practice Drill (Forensics)
        QuestLevel(
          id: 'sis_lvl_8',
          literatureId: 'lit_study_in_scarlet',
          levelNumber: 8,
          title: 'Practice: Victorian Forensics',
          description: 'Learn how Doyle anticipated real-world forensic science.',
          type: LevelType.analysis,
          isCompleted: false,
          isLocked: true,
          gemsReward: 25,
          energyCost: 0,
          chapterIndex: 2,
          customQuestions: [
            const QuizQuestion(
              id: 'sis_lvl8_q1',
              prompt: 'What physical evidence allowed Holmes to determine the cab horse had three old shoes and one new one?',
              options: [
                'The depth and clarity of hoof impressions in the Brixton road mud',
                'A horseshoe nail found on the doorstep',
                'Interrogation of the local stable master',
                'Chalk marks left on the curb',
              ],
              correctAnswerIndex: 0,
              explanation: 'Holmes analyzed the distinct impression patterns left by the hooves in the wet soil.',
            ),
          ],
        ),
        // Level 9: Reading Review
        QuestLevel(
          id: 'sis_lvl_9',
          literatureId: 'lit_study_in_scarlet',
          levelNumber: 9,
          title: 'Grand Review: The Consulting Detective',
          description: 'Synthesize the dynamic partnership between Watson and Holmes.',
          type: LevelType.read,
          isCompleted: false,
          isLocked: true,
          gemsReward: 30,
          chapterIndex: 1,
          estimatedMinutes: 4,
        ),
        // Level 10: Final Boss Assessment
        QuestLevel(
          id: 'sis_lvl_10',
          literatureId: 'lit_study_in_scarlet',
          levelNumber: 10,
          title: 'Final Trial: Baker Street Master Sleuth',
          description: 'Earn your degree in Victorian forensic deduction.',
          type: LevelType.finalTest,
          isCompleted: false,
          isLocked: true,
          gemsReward: 100,
          energyCost: 2,
          chapterIndex: 2,
          customQuestions: [
            const QuizQuestion(
              id: 'sis_lvl10_q1',
              prompt: 'Who was the real-life medical professor that inspired Arthur Conan Doyle to create Sherlock Holmes?',
              options: [
                'Dr. Joseph Bell of the Royal Infirmary of Edinburgh',
                'Dr. Thomas Watson of the London Hospital',
                'Sir William Osler of Oxford',
                'Dr. Sigmund Freud of Vienna',
              ],
              correctAnswerIndex: 0,
              explanation: 'Doyle was a medical clerk for Dr. Joseph Bell, whose miraculous deductive diagnosis of patients stunned students.',
            ),
            const QuizQuestion(
              id: 'sis_lvl10_q2',
              prompt: 'What was the specific poison weapon utilized in the Brixton murder case?',
              options: [
                'Alkaloid pills manufactured from South American curare poison',
                'Arsenic powder dissolved in sherry',
                'Cyanide gas trapped in a clockwork box',
                'Strychnine smeared on a needle tip',
              ],
              correctAnswerIndex: 0,
              explanation: 'The killer Jefferson Hope forced his victims to choose between two identical pills, one harmless and one lethal.',
            ),
          ],
        ),
      ],
      recallQuizzes: {},
      practiceQuizzes: {},
      finalExam: [],
    );
  }

  /// 3. Around the World in 80 Days (Jules Verne)
  static Literature getAroundTheWorldIn80Days() {
    return Literature(
      id: 'lit_around_the_world_80_days',
      title: 'Around the World in 80 Days',
      author: 'Jules Verne',
      description:
          'The ultimate voyage of the Victorian age. The meticulous Englishman Phileas Fogg wagers £20,000 at the Reform Club that he can circumnavigate the globe in eighty days, accompanied by his spirited French valet Passepartout.',
      type: LiteratureType.novel,
      genres: ['Voyages & Sci-Fi', 'Adventure & Chivalry', 'Classics'],
      gemCost: 800,
      isOwned: false,
      currentLevelIndex: 0,
      chaptersCompleted: 0,
      gemsEarned: 0,
      totalChapters: 3,
      chapters: [
        const Chapter(
          id: 'atw_ch1',
          chapterNumber: 1,
          title: 'The Imperturbable Mr. Phileas Fogg and Passepartout',
          estimatedMinutes: 5,
          quoteHighlight:
              'Phileas Fogg was a personage who, having once established a timetable for his life, followed it with astronomical precision.',
          quoteContext: 'Introduction of London’s most eccentric gentleman',
          content: '''
Mr. Phileas Fogg lived, in 1872, at No. 7, Savile Row, Burlington Gardens, the house in which Sheridan died in 1814. He was one of the most noticeable members of the Reform Club, though he seemed always to avoid attracting attention.

Certainly an Englishman, it was more doubtful whether Phileas Fogg was a Londoner. He was never seen on ’Change, nor at the Bank; no ship of which he was the owner had ever entered the docks of London. His sole pastime was reading the daily papers and playing whist. He often won, but his winnings always went into his charities.

His life was lived with mathematical regularity. If he breakfasted and dined, it was at the Club, at the same table, in the same room. He returned home exactly at midnight. He used no carriages; he walked with that measured, rhythmic stride which seemed guided by internal escapements.

On the morning of October 2nd, he dismissed his servant James Forster for having brought him shaving-water at eighty-four degrees Fahrenheit instead of eighty-six. Shortly before noon, a French applicant presented himself.

"You are named?" asked Mr. Fogg.

"Jean Passepartout, a surname which has clung to me from my natural aptitude for getting out of awkward scrapes," replied the Frenchman. "I have been a circus rider, a gymnast, a sergeant in the Paris fire brigade. But I wish now to live quietly and orderly."

"Passepartout suits me," said Mr. Fogg. "You have been recommended to me. You know my conditions? The clock is now twenty-nine minutes past eleven. From this moment, Wednesday, October 2nd, 1872, you are in my service."
''',
        ),
        const Chapter(
          id: 'atw_ch2',
          chapterNumber: 2,
          title: 'The Twenty-Thousand Pound Wager at the Reform Club',
          estimatedMinutes: 5,
          quoteHighlight:
              'A true Englishman doesn\'t joke when he is talking about so serious a thing as a wager.',
          quoteContext: 'The wager that launched the journey',
          content: '''
At the Reform Club that afternoon, the conversation among the card players turned to a daring robbery of fifty-five thousand pounds from the Bank of England. The thief, described as a well-dressed gentleman, was suspected of fleeing overseas.

"The world is vast," said Stuart, cutting the pack. "He might hide anywhere."

"It was vast once," remarked Phileas Fogg quietly. "The world has grown smaller since a man can now go round it ten times more quickly than eighty years ago."

"How eighty days?" cried Andrew Stuart. "Because the railway across India from Bombay to Calcutta has just opened? Unforeseen obstacles, bad weather, shipwrecks, train derailments—these do not count in your calculations!"

"All included," said Fogg, laying down his cards.

"I’d like to see you do it in eighty days!"

"I am ready. I have twenty thousand pounds deposited at Baring Brothers. I will wager that sum against anyone that I will make the tour of the world in eighty days or less—that is, in nineteen hundred and twenty hours, or one hundred and fifteen thousand two hundred minutes. Do you accept?"

"We accept," answered the five gentlemen after conferring together.

"Good. The train leaves for Dover at a quarter to nine tonight. I will take it. Today is Wednesday, October 2nd. I ought to be back in this very room of the Reform Club on Saturday, December 21st, at a quarter before nine in the evening; in default of which, the twenty thousand pounds will belong to you, gentlemen."
''',
        ),
        const Chapter(
          id: 'atw_ch3',
          chapterNumber: 3,
          title: 'The Great Train Ride across the Indian Wilderness',
          estimatedMinutes: 5,
          quoteHighlight:
              'Between Kholby and Allahabad there is no railroad; the passengers must find their own conveyance.',
          quoteContext: 'Purchasing the elephant Kiouni in the jungle',
          content: '''
Reaching Bombay ahead of schedule by steamship through the newly inaugurated Suez Canal, Fogg and Passepartout boarded the Great Indian Peninsular Railway bound for Calcutta.

All seemed auspicious as the locomotive steamed past cotton plantations, bamboo groves, and ancient pagodas. But at eight o’clock the following morning, the train ground to a sudden halt in the middle of a dense jungle near the hamlet of Kholby.

"Where are we?" inquired Phileas Fogg.

"The passengers must get out here," replied the conductor nonchalantly.

"And why?"

"Because the railway is not finished. There is a gap of fifty miles between this place and Allahabad, where the track begins again."

"Yet the newspapers announced the complete opening of the line!" cried Passepartout, outraged.

"The papers were mistaken," said the conductor coolly.

While other travelers despaired, Phileas Fogg showed no trace of annoyance. "Passepartout," he said calmly, "we must find some conveyance to Allahabad. A delay of two days was anticipated in my surplus margin."

In the village, Fogg found an Indian peasant with a magnificent tamed elephant named Kiouni. When the owner refused to rent the beast, Fogg calmly bid one thousand pounds, then fifteen hundred, and finally two thousand pounds in cash. The elephant was theirs, and upon its back they plunged into the perilous jungle of Bundelkhand!
''',
        ),
      ],
      questLevels: [
        // Level 1: Read Chapter 1
        QuestLevel(
          id: 'atw_lvl_1',
          literatureId: 'lit_around_the_world_80_days',
          levelNumber: 1,
          title: 'Chapter 1: The Punctual Gentleman',
          description: 'Meet Phileas Fogg and his colorful new valet Jean Passepartout.',
          type: LevelType.read,
          isCompleted: false,
          isLocked: false,
          gemsReward: 30,
          chapterIndex: 0,
          estimatedMinutes: 5,
        ),
        // Level 2: Recall Quiz
        QuestLevel(
          id: 'atw_lvl_2',
          literatureId: 'lit_around_the_world_80_days',
          levelNumber: 2,
          title: 'Recall: Fogg’s Routine',
          description: 'Test your grasp of Fogg’s eccentric precision.',
          type: LevelType.recall,
          isCompleted: false,
          isLocked: true,
          gemsReward: 35,
          energyCost: 1,
          chapterIndex: 0,
          customQuestions: [
            const QuizQuestion(
              id: 'atw_lvl2_q1',
              prompt: 'Why did Phileas Fogg dismiss his previous valet James Forster?',
              options: [
                'He brought shaving water at 84° Fahrenheit instead of 86°',
                'He lost twenty pounds during a card game',
                'He was caught sleeping during the morning tea service',
                'He misread the train schedule to Dover',
              ],
              correctAnswerIndex: 0,
              explanation: 'Fogg’s astronomical obsession with temperature and order led him to fire his valet over a 2-degree discrepancy.',
            ),
          ],
        ),
        // Level 3: Practice Drill (Geography)
        QuestLevel(
          id: 'atw_lvl_3',
          literatureId: 'lit_around_the_world_80_days',
          levelNumber: 3,
          title: 'Practice: 19th-Century Global Routes',
          description: 'Explore the technologies that made 80 days possible.',
          type: LevelType.practice,
          isCompleted: false,
          isLocked: true,
          gemsReward: 25,
          energyCost: 0,
          chapterIndex: 0,
          customQuestions: [
            const QuizQuestion(
              id: 'atw_lvl3_q1',
              prompt: 'Which famous engineering feat opened in 1869, drastically shortening the sea route to India?',
              options: [
                'The Suez Canal in Egypt',
                'The Panama Canal in Central America',
                'The Kiel Canal in Germany',
                'The Corinth Canal in Greece',
              ],
              correctAnswerIndex: 0,
              explanation: 'The opening of the Suez Canal cut thousands of miles off the journey around the Cape of Good Hope.',
            ),
          ],
        ),
        // Level 4: Read Chapter 2
        QuestLevel(
          id: 'atw_lvl_4',
          literatureId: 'lit_around_the_world_80_days',
          levelNumber: 4,
          title: 'Chapter 2: The £20,000 Wager',
          description: 'Witness the historic wager struck at the Reform Club.',
          type: LevelType.read,
          isCompleted: false,
          isLocked: true,
          gemsReward: 30,
          chapterIndex: 1,
          estimatedMinutes: 5,
        ),
        // Level 5: Recall Quiz
        QuestLevel(
          id: 'atw_lvl_5',
          literatureId: 'lit_around_the_world_80_days',
          levelNumber: 5,
          title: 'Recall: The Reform Club Bet',
          description: 'Verify the details and deadline of the wager.',
          type: LevelType.recall,
          isCompleted: false,
          isLocked: true,
          gemsReward: 35,
          energyCost: 1,
          chapterIndex: 1,
          customQuestions: [
            const QuizQuestion(
              id: 'atw_lvl5_q1',
              prompt: 'What was the exact sum Phileas Fogg wagered with his club peers?',
              options: [
                '£20,000 (roughly half his fortune)',
                '£5,000 in British bank bonds',
                '£50,000 in gold ingots',
                '£100,000 and his London mansion',
              ],
              correctAnswerIndex: 0,
              explanation: 'Fogg wagered £20,000, reserving the remaining £20,000 to cover travel expenses.',
            ),
          ],
        ),
        // Level 6: Read Chapter 3
        QuestLevel(
          id: 'atw_lvl_6',
          literatureId: 'lit_around_the_world_80_days',
          levelNumber: 6,
          title: 'Chapter 3: The Indian Wilderness',
          description: 'Ride the elephant Kiouni across the unfinished railway gap.',
          type: LevelType.read,
          isCompleted: false,
          isLocked: true,
          gemsReward: 30,
          chapterIndex: 2,
          estimatedMinutes: 5,
        ),
        // Level 7: Recall Quiz
        QuestLevel(
          id: 'atw_lvl_7',
          literatureId: 'lit_around_the_world_80_days',
          levelNumber: 7,
          title: 'Recall: The Elephant Kiouni',
          description: 'Analyze Fogg’s resourcefulness when the tracks ended.',
          type: LevelType.recall,
          isCompleted: false,
          isLocked: true,
          gemsReward: 35,
          energyCost: 1,
          chapterIndex: 2,
          customQuestions: [
            const QuizQuestion(
              id: 'atw_lvl7_q1',
              prompt: 'How did Fogg overcome the 50-mile unfinished railway gap between Kholby and Allahabad?',
              options: [
                'He bought an elephant named Kiouni for £2,000',
                'He hired a steam launch down the Ganges river',
                'He waited four days for the tracks to be finished',
                'He chartered a hot air balloon',
              ],
              correctAnswerIndex: 0,
              explanation: 'Fogg spent an astonishing £2,000 to buy the elephant Kiouni to traverse the jungle on time.',
            ),
          ],
        ),
        // Level 8: Analysis Drill
        QuestLevel(
          id: 'atw_lvl_8',
          literatureId: 'lit_around_the_world_80_days',
          levelNumber: 8,
          title: 'Analysis: The International Date Line',
          description: 'Master the scientific twist that resolves Verne’s plot.',
          type: LevelType.analysis,
          isCompleted: false,
          isLocked: true,
          gemsReward: 25,
          energyCost: 0,
          chapterIndex: 2,
          customQuestions: [
            const QuizQuestion(
              id: 'atw_lvl8_q1',
              prompt: 'Why did Fogg mistakenly believe he had arrived in London 5 minutes too late at the journey’s end?',
              options: [
                'He traveled eastward, gaining 4 minutes per degree and winning a full day',
                'Passepartout forgot to wind his pocket watch',
                'The London clocks were shifted forward for wartime curfew',
                'A telegraph wire had snapped in Dover',
              ],
              correctAnswerIndex: 0,
              explanation: 'Traveling eastward toward the rising sun, Fogg gained 24 hours without realizing it until the final minutes!',
            ),
          ],
        ),
        // Level 9: Reading Review
        QuestLevel(
          id: 'atw_lvl_9',
          literatureId: 'lit_around_the_world_80_days',
          levelNumber: 9,
          title: 'Grand Review: The Age of Steam and Steel',
          description: 'Review Jules Verne’s celebratory tribute to human ingenuity.',
          type: LevelType.read,
          isCompleted: false,
          isLocked: true,
          gemsReward: 30,
          chapterIndex: 1,
          estimatedMinutes: 4,
        ),
        // Level 10: Final Boss Assessment
        QuestLevel(
          id: 'atw_lvl_10',
          literatureId: 'lit_around_the_world_80_days',
          levelNumber: 10,
          title: 'Final Trial: Master Circumnavigator',
          description: 'Complete the 80-day odyssey and claim Reform Club glory.',
          type: LevelType.finalTest,
          isCompleted: false,
          isLocked: true,
          gemsReward: 100,
          energyCost: 2,
          chapterIndex: 2,
          customQuestions: [
            const QuizQuestion(
              id: 'atw_lvl10_q1',
              prompt: 'Who was Detective Fix and why was he dogging Fogg across every continent?',
              options: [
                'He mistook Fogg for the gentleman thief who robbed the Bank of England',
                'He was hired by the Reform Club to spy on Fogg’s route',
                'He was Passepartout’s estranged older brother',
                'He was an agent of the French consulate',
              ],
              correctAnswerIndex: 0,
              explanation: 'Fix believed Fogg’s sudden departure with bags of banknotes was the getaway of the bank robber.',
            ),
            const QuizQuestion(
              id: 'atw_lvl10_q2',
              prompt: 'Whom did Fogg and Passepartout rescue from the ritual of suttee in the Indian forest?',
              options: [
                'Aouda, an educated young Parsi woman and widow',
                'The daughter of the Rajah of Bombay',
                'An English governor’s niece',
                'A French missionary sister',
              ],
              correctAnswerIndex: 0,
              explanation: 'They boldly rescued Aouda, who accompanied them and ultimately married Fogg in London.',
            ),
          ],
        ),
      ],
      recallQuizzes: {},
      practiceQuizzes: {},
      finalExam: [],
    );
  }

  /// 4. Pride and Prejudice (Jane Austen)
  static Literature getPrideAndPrejudice() {
    return Literature(
      id: 'lit_pride_and_prejudice',
      title: 'Pride and Prejudice',
      author: 'Jane Austen',
      description:
          'The pinnacle of English romantic satire. Elizabeth Bennet must navigate familial expectations, social snobbery, and her own hasty prejudices against the proud, wealthy Mr. Fitzwilliam Darcy.',
      type: LiteratureType.novel,
      genres: ['Romance & Society', 'Classics', 'Philosophy & Fables'],
      gemCost: 800,
      isOwned: false,
      currentLevelIndex: 0,
      chaptersCompleted: 0,
      gemsEarned: 0,
      totalChapters: 3,
      chapters: [
        const Chapter(
          id: 'pap_ch1',
          chapterNumber: 1,
          title: 'A Truth Universally Acknowledged',
          estimatedMinutes: 5,
          quoteHighlight:
              'It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.',
          quoteContext: 'The opening line of the novel',
          content: '''
It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.

However little known the feelings or views of such a man may be on his first entering a neighbourhood, this truth is so well fixed in the minds of the surrounding families, that he is considered the rightful property of some one or other of their daughters.

"My dear Mr. Bennet," said his lady to him one day, "have you heard that Netherfield Park is let at last?"

Mr. Bennet replied that he had not.

"But it is," returned she; "for Mrs. Long has just been here, and she told me all about it. A young man of large fortune from the north of England; that he came down on Monday in a chaise and four to see the place, and was so much delighted with it, that he agreed with Mr. Morris immediately."

"What is his name?"

"Bingley."

"Is he married or single?"

"Oh! single, my dear, to be sure! A single man of large fortune; four or five thousand a year. What a fine thing for our girls!"

"How so? How can it affect them?"

"My dear Mr. Bennet," replied his wife, "how can you be so tiresome! You must know that I am thinking of his marrying one of them."
''',
        ),
        const Chapter(
          id: 'pap_ch2',
          chapterNumber: 2,
          title: 'Mr. Bingley and the Netherfield Estate',
          estimatedMinutes: 5,
          quoteHighlight:
              'Mr. Bennet was so odd a mixture of quick parts, sarcastic humour, reserve, and caprice.',
          quoteContext: 'The dynamics of the Longbourn household',
          content: '''
Mr. Bennet was among the earliest of those who waited on Mr. Bingley. He had always intended to visit him, though to the last always assuring his wife that he should not go; and till the evening after the visit was paid she had no knowledge of it.

It was then disclosed in the following manner. Observing his second daughter, Elizabeth, employed in trimming a hat, he suddenly addressed her with:

"I hope Mr. Bingley will like it, Lizzy."

"We are not in a way to know what Mr. Bingley likes," said her mother resentfully, "since we are not to visit."

"But you forget, mamma," said Elizabeth, "that we shall meet him at the assemblies, and that Mrs. Long has promised to introduce him."

"I do not believe Mrs. Long will do any such thing. She has two nieces of her own. She is a selfish, hypocritical woman, and I have no opinion of her."

"No more have I," said Mr. Bennet; "and I am glad to find that you do not depend on her serving you."

Mrs. Bennet deigned not to make any reply, but, unable to contain herself, began scolding one of her daughters. "Don’t keep coughing so, Kitty, for heaven’s sake! Have a little compassion on my nerves. You tear them to pieces."

"Kitty has no discretion in her coughs," said her father; "she times them ill."

"I do not cough for my own amusement," replied Kitty fretfully.

"When is your next ball to be, Lizzy?"

"To-morrow fortnight."

"Aye, so it is," cried her mother, "and Mrs. Long does not come back till the day before; so it will be impossible for her to introduce him, for she will not know him herself."

"Then, my dear, you may have the advantage of your friend, and introduce Mr. Bingley to her."

"Impossible, Mr. Bennet, impossible, when I am not acquainted with him myself; how can you be so teasing?"

"I honour your circumspection. A fortnight’s acquaintance is certainly very little. But if you will not venture, I will take it upon myself."

The astonishment of the ladies was just what he wished; that of Mrs. Bennet perhaps surpassing the rest; though, when the first tumult of joy was over, she began to declare that it was what she had expected all the while.
''',
        ),
        const Chapter(
          id: 'pap_ch3',
          chapterNumber: 3,
          title: 'The Assembly Room Ball and Mr. Darcy\'s Pride',
          estimatedMinutes: 5,
          quoteHighlight:
              'She is tolerable; but not handsome enough to tempt me; and I am in no humour at present to give consequence to young ladies who are slighted by other men.',
          quoteContext: 'Mr. Darcy’s rebuff of Elizabeth Bennet',
          content: '''
Not all that Mrs. Bennet, however, with the assistance of her five daughters, could ask on the subject, was sufficient to draw from her husband any satisfactory description of Mr. Bingley.

The evening of the Meryton assembly ball at length arrived. Mr. Bingley was good-looking and gentlemanlike; he had a pleasant countenance, and easy, unaffected manners. His sisters were fine women, with an air of decided fashion. His brother-in-law, Mr. Hurst, merely looked the gentleman; but his friend Mr. Darcy soon drew the attention of the room by his fine, tall person, handsome features, noble mien, and the report which was in general circulation within five minutes after his entrance, of his having ten thousand a year!

The gentlemen pronounced him to be a fine figure of a man, the ladies declared he was much handsomer than Mr. Bingley, and he was looked at with great admiration for about half the evening, till his manners gave a disgust which turned the tide of his popularity; for he was discovered to be proud, to be above his company, and above being pleased; and not all his large estate in Derbyshire could then save him from having a most forbidding, disagreeable countenance.

Elizabeth Bennet had been obliged, by the scarcity of gentlemen, to sit down for two dances; and during part of that time, Mr. Darcy had been standing near enough for her to hear a conversation between him and Mr. Bingley, who had come out of the dance for a few minutes.

"Come, Darcy," said he, "I must have you dance. I hate to see you standing about by yourself in this stupid manner. You had much better dance."

"I certainly shall not. You know how I detest it, unless I am particularly acquainted with my partner. Your sisters are engaged, and there is not another woman in the room whom it would not be a punishment to me to stand up with."

"I would not be so fastidious as you are," cried Bingley, "for a kingdom! Upon my honour, I never met with so many pleasant girls in my life!"

"You are dancing with the only handsome girl in the room," said Mr. Darcy, looking at the eldest Miss Bennet.

"Oh! She is the most beautiful creature I ever beheld! But there is one of her sisters sitting just behind you, who is very pretty, and I dare say very agreeable. Do let me ask my partner to introduce you."

"Which do you mean?" and turning round, he looked for a moment at Elizabeth, till catching her eye, he withdrew his own and coldly said:

"She is tolerable; but not handsome enough to tempt me; and I am in no humour at present to give consequence to young ladies who are slighted by other men."
''',
        ),
      ],
      questLevels: [
        // Level 1: Read Chapter 1
        QuestLevel(
          id: 'pap_lvl_1',
          literatureId: 'lit_pride_and_prejudice',
          levelNumber: 1,
          title: 'Chapter 1: A Truth Universally Acknowledged',
          description: 'Meet the Bennet family and hear news of the tenant at Netherfield.',
          type: LevelType.read,
          isCompleted: false,
          isLocked: false,
          gemsReward: 30,
          chapterIndex: 0,
          estimatedMinutes: 5,
        ),
        // Level 2: Recall Quiz
        QuestLevel(
          id: 'pap_lvl_2',
          literatureId: 'lit_pride_and_prejudice',
          levelNumber: 2,
          title: 'Recall: The Netherfield Tenant',
          description: 'Test your understanding of Mrs. Bennet’s matrimonial ambitions.',
          type: LevelType.recall,
          isCompleted: false,
          isLocked: true,
          gemsReward: 35,
          energyCost: 1,
          chapterIndex: 0,
          customQuestions: [
            const QuizQuestion(
              id: 'pap_lvl2_q1',
              prompt: 'What was the annual income of Mr. Bingley that excited Mrs. Bennet so intensely?',
              options: [
                'Four or five thousand pounds a year',
                'Ten thousand pounds a year',
                'Five hundred pounds a year',
                'Fifty thousand pounds in naval bonds',
              ],
              correctAnswerIndex: 0,
              explanation: 'Mr. Bingley was reported to have four or five thousand a year from the north of England.',
            ),
          ],
        ),
        // Level 3: Analysis Drill (Regency Satire)
        QuestLevel(
          id: 'pap_lvl_3',
          literatureId: 'lit_pride_and_prejudice',
          levelNumber: 3,
          title: 'Analysis: Irony & Social Satire',
          description: 'Analyze Jane Austen’s famous opening line and narrator voice.',
          type: LevelType.analysis,
          isCompleted: false,
          isLocked: true,
          gemsReward: 25,
          energyCost: 0,
          chapterIndex: 0,
          customQuestions: [
            const QuizQuestion(
              id: 'pap_lvl3_q1',
              prompt: 'What literary device is primarily at work in Austen’s famous opening sentence?',
              options: [
                'Irony: the statement pretends to express a universal law, but actually reflects social obsession',
                'Metaphor: comparing men to financial currency',
                'Allegory: representing England as a wandering bachelor',
                'Hyperbole: exaggerating the physical size of estates',
              ],
              correctAnswerIndex: 0,
              explanation: 'The sentence is ironic: it is not the wealthy man who is desperately in want of a wife, but society desperate to marry him.',
            ),
          ],
        ),
        // Level 4: Read Chapter 2
        QuestLevel(
          id: 'pap_lvl_4',
          literatureId: 'lit_pride_and_prejudice',
          levelNumber: 4,
          title: 'Chapter 2: Mr. Bennet’s Secret Visit',
          description: 'Discover how Mr. Bennet teaseth his wife and daughters.',
          type: LevelType.read,
          isCompleted: false,
          isLocked: true,
          gemsReward: 30,
          chapterIndex: 1,
          estimatedMinutes: 5,
        ),
        // Level 5: Recall Quiz
        QuestLevel(
          id: 'pap_lvl_5',
          literatureId: 'lit_pride_and_prejudice',
          levelNumber: 5,
          title: 'Recall: Longbourn Parlor Wits',
          description: 'Examine Mr. Bennet’s dry humor and Kitty’s ill-timed coughs.',
          type: LevelType.recall,
          isCompleted: false,
          isLocked: true,
          gemsReward: 35,
          energyCost: 1,
          chapterIndex: 1,
          customQuestions: [
            const QuizQuestion(
              id: 'pap_lvl5_q1',
              prompt: 'Which daughter was trimming a hat when Mr. Bennet announced his visit?',
              options: [
                'Elizabeth (Lizzy)',
                'Jane',
                'Lydia',
                'Mary',
              ],
              correctAnswerIndex: 0,
              explanation: 'Elizabeth was trimming her bonnet when her father addressed her about Mr. Bingley.',
            ),
          ],
        ),
        // Level 6: Read Chapter 3
        QuestLevel(
          id: 'pap_lvl_6',
          literatureId: 'lit_pride_and_prejudice',
          levelNumber: 6,
          title: 'Chapter 3: The Assembly Ball',
          description: 'Attend the Meryton ball and hear Mr. Darcy’s infamous refusal to dance.',
          type: LevelType.read,
          isCompleted: false,
          isLocked: true,
          gemsReward: 30,
          chapterIndex: 2,
          estimatedMinutes: 5,
        ),
        // Level 7: Recall Quiz
        QuestLevel(
          id: 'pap_lvl_7',
          literatureId: 'lit_pride_and_prejudice',
          levelNumber: 7,
          title: 'Recall: The Rebuff of Elizabeth',
          description: 'Analyze Mr. Darcy’s exact words regarding Elizabeth Bennet.',
          type: LevelType.recall,
          isCompleted: false,
          isLocked: true,
          gemsReward: 35,
          energyCost: 1,
          chapterIndex: 2,
          customQuestions: [
            const QuizQuestion(
              id: 'pap_lvl7_q1',
              prompt: 'What slighting remark did Mr. Darcy make about Elizabeth when Bingley urged him to dance?',
              options: [
                '"She is tolerable; but not handsome enough to tempt me."',
                '"She is far too sharp-tongued for an assembly."',
                '"Her family connections make her unsuitable."',
                '"I prefer ladies of quieter disposition."',
              ],
              correctAnswerIndex: 0,
              explanation: 'Darcy called Elizabeth "tolerable; but not handsome enough to tempt me," which spark Elizabeth’s initial prejudice.',
            ),
          ],
        ),
        // Level 8: Practice Drill (Vocabulary)
        QuestLevel(
          id: 'pap_lvl_8',
          literatureId: 'lit_pride_and_prejudice',
          levelNumber: 8,
          title: 'Practice: Regency Vocabulary',
          description: 'Master archaic terms: fastidious, circumspection, caprice, and mien.',
          type: LevelType.practice,
          isCompleted: false,
          isLocked: true,
          gemsReward: 25,
          energyCost: 0,
          chapterIndex: 2,
          customQuestions: [
            const QuizQuestion(
              id: 'pap_lvl8_q1',
              prompt: 'When Bingley says he would not be so "fastidious" as Darcy, what does he mean?',
              options: [
                'Excessively critical, hard to please, and particular about standards',
                'Lacking physical stamina to dance consecutive sets',
                'Eager to spend money on frivolous entertainment',
                'Frightened of speaking to strangers in society',
              ],
              correctAnswerIndex: 0,
              explanation: 'Fastidious means very attentive to detail and demanding high, hard-to-satisfy standards.',
            ),
          ],
        ),
        // Level 9: Reading Review
        QuestLevel(
          id: 'pap_lvl_9',
          literatureId: 'lit_pride_and_prejudice',
          levelNumber: 9,
          title: 'Grand Review: First Impressions',
          description: 'Review the contrast between Bingley’s geniality and Darcy’s haughtiness.',
          type: LevelType.read,
          isCompleted: false,
          isLocked: true,
          gemsReward: 30,
          chapterIndex: 2,
          estimatedMinutes: 4,
        ),
        // Level 10: Final Boss Assessment
        QuestLevel(
          id: 'pap_lvl_10',
          literatureId: 'lit_pride_and_prejudice',
          levelNumber: 10,
          title: 'Final Trial: Pemberley Scholar',
          description: 'Prove thy complete comprehension of Austen’s characters and world.',
          type: LevelType.finalTest,
          isCompleted: false,
          isLocked: true,
          gemsReward: 100,
          energyCost: 2,
          chapterIndex: 2,
          customQuestions: [
            const QuizQuestion(
              id: 'pap_lvl10_q1',
              prompt: 'What was the grand Derbyshire estate owned by Fitzwilliam Darcy?',
              options: [
                'Pemberley',
                'Rosings Park',
                'Netherfield Park',
                'Longbourn',
              ],
              correctAnswerIndex: 0,
              explanation: 'Pemberley in Derbyshire was Darcy’s ancestral country estate, representing his nobility and true character.',
            ),
            const QuizQuestion(
              id: 'pap_lvl10_q2',
              prompt: 'What was Jane Austen’s original working title for Pride and Prejudice?',
              options: [
                'First Impressions',
                'Elinor and Marianne',
                'The Longbourn Sisters',
                'The Gentleman from Pemberley',
              ],
              correctAnswerIndex: 0,
              explanation: 'Austen originally drafted the novel under the title "First Impressions" in 1796–1797.',
            ),
          ],
        ),
      ],
      recallQuizzes: {},
      practiceQuizzes: {},
      finalExam: [],
    );
  }
}
