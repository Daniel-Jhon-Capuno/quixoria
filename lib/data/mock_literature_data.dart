import '../models/literature.dart';
import '../models/quest_level.dart';
import '../models/quiz_question.dart';
import 'classics_expansion_data.dart';
import 'library_catalog_data.dart';

class MockLiteratureData {
  static List<Literature> getInitialCatalog() {
    return [
      // 1. The Secret Garden (Frances Hodgson Burnett) - Primary Active Owned Quest
      Literature(
        id: 'lit_secret_garden',
        title: 'The Secret Garden',
        author: 'Frances Hodgson Burnett',
        description:
            'When Mary Lennox is orphaned in India, she is sent to England to live with her reclusive uncle in a gloomy mansion on the Yorkshire moors. There, she discovers a walled garden that has been locked for ten years.',
        type: LiteratureType.novel,
        genres: ['Classics', 'Mystery', 'Adventure'],
        gemCost: 600,
        isOwned: true,
        currentLevelIndex: 1, // Ready for Level 2 (Recall)
        chaptersCompleted: 1,
        gemsEarned: 75,
        totalChapters: 3,
        chapters: [
          const Chapter(
            id: 'sg_ch1',
            chapterNumber: 1,
            title: 'There is No One Left',
            estimatedMinutes: 4,
            quoteHighlight:
                'She had never seemed to belong to anyone, even when her father and mother were alive.',
            quoteContext: 'Opening of Misselthwaite Manor revelation',
            content: '''
When Mary Lennox was sent to Misselthwaite Manor to live with her uncle everybody said she was the most disagreeable-looking child ever seen. It was true, too. She had a little thin face and a little thin body, thin light hair and a sour expression. Her hair was yellow, and her face was yellow because she had been born in India and had always been ill in one way or another.

Her father had held a position under the English Government and had always been busy and ill himself, and her mother had been a great beauty who cared only to go to parties and amuse herself with gay people. She had not wanted a little girl at all, and when Mary was born she handed her over to the care of an Ayah.

Therefore, when she was nine years old she was as tyrannical and selfish a little pig as ever lived. She never remembered seeing familiarly anything but the dark faces of her Ayah and the other native servants, and as they always obeyed her and gave her her own way in everything, by the time she was six years old she was as tyrannical a little ruler as one could imagine.

One terribly hot morning, when she was about nine years of age, she awakened feeling very cross, and she became crosser still when she saw that the servant who stood by her bedside was not her Ayah.

"Why did you come?" Mary asked, stomping her little foot upon the floor. "I will not let you stay. Send my Ayah to me immediately!"

The woman looked frightened, but she only stammered that the Ayah could not come. There was a stillness over the compound—a dreadful silence where even the birds seemed muted beneath the sweltering sky. Soon Mary would learn the sorrowful truth: cholera had struck, and she was alone in the silent house.
''',
          ),
          const Chapter(
            id: 'sg_ch2',
            chapterNumber: 2,
            title: 'The Robin Redbreast and the Wall',
            estimatedMinutes: 5,
            quoteHighlight:
                'It was the sweetest, most mysterious-looking place anyone could imagine.',
            quoteContext: 'Discovery of the ivy-covered perimeter',
            content: '''
The rain had stopped and the gray mist had lifted, leaving the Yorkshire sky pale and clear. Mary walked down paths bordered by high evergreen hedges, her hands deep in the pockets of her warm wool coat.

She had been told of a garden locked away for ten years, its key buried when the lady of the manor had tragically died. As she wandered along the ivy-hung wall, a cheerful chirp broke the quiet.

Perched upon a mossy branch was a robin redbreast, boasting a brilliant scarlet vest. The robin cocked his tiny head, looking at her with such intelligent, welcoming eyes that Mary felt something soften inside her chest.

"You are not like the birds in India," she whispered softly.

The bird chirped and fluttered down onto a mound of fresh earth that a dog had recently disturbed. Mary looked closer. A small ring of rusty iron protruded from the soil. With a racing heart, she knelt and pulled it from the earth—it was an old, heavy brass key!
''',
          ),
          const Chapter(
            id: 'sg_ch3',
            chapterNumber: 3,
            title: 'The Door in the Ivy',
            estimatedMinutes: 5,
            quoteHighlight:
                'Where you tend a rose, my lad, a thistle cannot grow.',
            quoteContext: 'Stepping into the secret domain',
            content: '''
Mary could hear her heart thumping against her ribs. She looked up and down the walk, but nobody was in sight. Holding the heavy key tightly in her hand, she followed the robin back along the high perimeter wall.

A strong gust of moorland wind blew suddenly, lifting a thick curtain of ivy that hung against the stone. Beneath the fluttering leaves, Mary caught sight of a round brass doorknob.

She slipped the key into the keyhole. It was stiff, but with both hands she turned it with a sharp click. The heavy oak door swung open with a slow, groaning creak.

Mary stepped through, shutting the door firmly behind her. She stood inside the hidden garden. It was silent, enchanted, and filled with climbing gray rose vines that looked like tangled webs of slumber.
''',
          ),
        ],
        questLevels: [
          // ==========================================
          // ZONE I: PLAINS OF LA MANCHA & MANOR ARRIVAL (6 Levels)
          // ==========================================
          QuestLevel(
            id: 'sg_lvl_1',
            literatureId: 'lit_secret_garden',
            levelNumber: 1,
            title: 'Chapter 1: There is No One Left',
            description: 'Begin Mary Lennox’s journey from India to the Yorkshire moors.',
            type: LevelType.read,
            isCompleted: true,
            isLocked: false,
            gemsReward: 25,
            chapterIndex: 0,
            estimatedMinutes: 4,
          ),
          QuestLevel(
            id: 'sg_lvl_2',
            literatureId: 'lit_secret_garden',
            levelNumber: 2,
            title: 'Recall Quiz: The Manor Arrival',
            description: 'Test your retention of Mary’s childhood and tragic departure.',
            type: LevelType.recall,
            isCompleted: false,
            isLocked: false,
            gemsReward: 35,
            energyCost: 1,
            chapterIndex: 0,
            customQuestions: [
              const QuizQuestion(
                id: 'sg_lvl2_q1',
                prompt: 'Where was Mary Lennox born and raised before being sent to England?',
                options: ['In British India', 'In the highlands of Scotland', 'In a Spanish villa', 'In rural France'],
                correctAnswerIndex: 0,
                explanation: 'Mary was born in India where her father held a position under the English Government.',
              ),
              const QuizQuestion(
                id: 'sg_lvl2_q2',
                prompt: 'How was Mary Lennox’s disposition described by those around her?',
                options: [
                  'The most disagreeable-looking and tyrannical child ever seen',
                  'A cheerful and obedient darling of the manor',
                  'A quiet scholar absorbed in poetry',
                  'A timid child who wept continuously',
                ],
                correctAnswerIndex: 0,
                explanation: 'Neglected by her parents and indulged by fearful servants, Mary developed a sour, tyrannical disposition.',
              ),
              const QuizQuestion(
                id: 'sg_lvl2_q3',
                prompt: 'To whose gloomy Yorkshire estate is Mary sent after the epidemic?',
                options: [
                  'Her reclusive uncle, Mr. Archibald Craven of Misselthwaite Manor',
                  'Her maternal grandmother in London',
                  'A boarding school headmistress in Sussex',
                  'A distant sea captain in Dover',
                ],
                correctAnswerIndex: 0,
                explanation: 'Mary is sent to live with her reclusive, hunchbacked uncle Archibald Craven at Misselthwaite Manor.',
              ),
            ],
          ),
          QuestLevel(
            id: 'sg_lvl_3',
            literatureId: 'lit_secret_garden',
            levelNumber: 3,
            title: 'Vocabulary Drill: Colonial Terms & Moors',
            description: 'Master archaic terms: Ayah, tyrannical, and compound.',
            type: LevelType.practice,
            isCompleted: false,
            isLocked: true,
            gemsReward: 20,
            energyCost: 0,
            chapterIndex: 0,
            customQuestions: [
              const QuizQuestion(
                id: 'sg_lvl3_q1',
                prompt: 'In Chapter 1, Mary demands her "Ayah". What is an Ayah?',
                options: [
                  'An Indian native nanny or nursemaid who raised British children',
                  'A ceremonial silk sari worn during dinners',
                  'A pony used to traverse tropical roads',
                  'A personal chef specializing in tea',
                ],
                correctAnswerIndex: 0,
                explanation: 'An "Ayah" was a traditional native nursemaid or governess employed in Anglo-Indian households.',
              ),
              const QuizQuestion(
                id: 'sg_lvl3_q2',
                prompt: 'The novel states Mary was "tyrannical". What does this rare word mean?',
                options: [
                  'Arbitrarily overbearing, demanding, and exercising despotic power',
                  'Easily frightened by loud noises and strangers',
                  'Deeply affectionate toward domestic animals',
                  'Suffering from a permanent physical infirmity',
                ],
                correctAnswerIndex: 0,
                explanation: 'Tyrannical means cruel, overbearing, and demanding absolute obedience without reason.',
              ),
              const QuizQuestion(
                id: 'sg_lvl3_q3',
                prompt: 'What was the "compound" that fell into terrifying stillness that morning?',
                options: [
                  'The enclosed residential estate and grounds containing bungalows and quarters',
                  'A mixture of herbs used by colonial apothecaries',
                  'A locked treasure chest hidden in the basement',
                  'A military garrison stationed by the bay',
                ],
                correctAnswerIndex: 0,
                explanation: 'A compound refers to an enclosed or walled cluster of buildings, residences, and servant quarters.',
              ),
              const QuizQuestion(
                id: 'sg_lvl3_q4',
                prompt: 'What fatal epidemic struck the compound, leaving Mary utterly alone?',
                options: [
                  'Cholera',
                  'The Bubonic Plague',
                  'Scarlet fever',
                  'Yellow jaundice',
                ],
                correctAnswerIndex: 0,
                explanation: 'Cholera struck suddenly in the sweltering heat, sweeping through the bungalow within hours.',
              ),
            ],
          ),
          QuestLevel(
            id: 'sg_lvl_4',
            literatureId: 'lit_secret_garden',
            levelNumber: 4,
            title: 'Character Study: Mary’s Bitter Shell',
            description: 'Analyze why neglected children construct tyrannical facades.',
            type: LevelType.analysis,
            isCompleted: false,
            isLocked: true,
            gemsReward: 25,
            energyCost: 0,
            chapterIndex: 0,
            customQuestions: [
              const QuizQuestion(
                id: 'sg_lvl4_q1',
                prompt: 'Why did Mary’s mother hand her over entirely to native servants from birth?',
                options: [
                  'She was a great social beauty who cared only for parties and amusement',
                  'She was bedridden with severe tuberculosis',
                  'She traveled abroad on royal diplomatic missions',
                  'She believed Spartan isolation strengthened children',
                ],
                correctAnswerIndex: 0,
                explanation: 'Her mother cared only for vanity, high society, and dancing, wanting no child to interfere with her gaiety.',
              ),
              const QuizQuestion(
                id: 'sg_lvl4_q2',
                prompt: 'What was the psychological root of Mary’s sour, cold temperament?',
                options: [
                  'Severe emotional neglect and total lack of genuine affection',
                  'An inheritance dispute between her cousins',
                  'Strict military discipline from her father',
                  'Reading too many tragic fables as an infant',
                ],
                correctAnswerIndex: 0,
                explanation: 'Mary’s hostility was an emotional armor formed because she had never been loved or held by her parents.',
              ),
            ],
          ),
          QuestLevel(
            id: 'sg_lvl_5',
            literatureId: 'lit_secret_garden',
            levelNumber: 5,
            title: 'Comprehension: Silence in the Compound',
            description: 'Deep narrative analysis of the silence preceding the tragedy.',
            type: LevelType.recall,
            isCompleted: false,
            isLocked: true,
            gemsReward: 35,
            energyCost: 1,
            chapterIndex: 0,
            customQuestions: [
              const QuizQuestion(
                id: 'sg_lvl5_q1',
                prompt: 'What ominous sensory detail alerted Mary that something terrible had occurred?',
                options: [
                  'A dreadful silence where even the birds seemed muted beneath the sweltering sky',
                  'The ringing of emergency fire bells across the city',
                  'A sudden torrential monsoon washing away the gardens',
                  'The howling of stray dogs outside the gates',
                ],
                correctAnswerIndex: 0,
                explanation: 'The ominous deathly hush over the sweltering compound signaled that cholera had silenced everyone.',
              ),
              const QuizQuestion(
                id: 'sg_lvl5_q2',
                prompt: 'How was Mary found after the tragedy had unfolded?',
                options: [
                  'Playing solitary games in the nursery, entirely forgotten by rescue officers',
                  'Hiding in a hollow tree in the mango grove',
                  'Writing in her diary on the veranda',
                  'Sleeping peacefully in her Ayah’s quarters',
                ],
                correctAnswerIndex: 0,
                explanation: 'British officers exploring the desolate house discovered Mary playing alone with bits of earth in the nursery.',
              ),
            ],
          ),
          QuestLevel(
            id: 'sg_lvl_6',
            literatureId: 'lit_secret_garden',
            levelNumber: 6,
            title: 'Zone I Mastery: Threshold to Yorkshire',
            description: 'Final review checkpoint before crossing into the Secret Greenwood.',
            type: LevelType.practice,
            isCompleted: false,
            isLocked: true,
            gemsReward: 40,
            energyCost: 0,
            chapterIndex: 0,
            customQuestions: [
              const QuizQuestion(
                id: 'sg_lvl6_q1',
                prompt: 'What major transition does Mary Lennox undergo at the end of Zone I?',
                options: [
                  'She leaves colonial India forever to journey across oceans to the Yorkshire moors',
                  'She is adopted by a wealthy merchant in Calcutta',
                  'She returns to a castle in the Spanish mountains',
                  'She becomes an apprentice gardener at age nine',
                ],
                correctAnswerIndex: 0,
                explanation: 'Mary crosses the threshold from the sweltering colonies of India to the cold, windswept Yorkshire moors.',
              ),
              const QuizQuestion(
                id: 'sg_lvl6_q2',
                prompt: 'Which word describes the vast, treeless, wild upland of northern England?',
                options: [
                  'Moorland',
                  'Marshland',
                  'Prairie',
                  'Savanna',
                ],
                correctAnswerIndex: 0,
                explanation: 'Moorland is the wild, windswept, heather-covered upland characteristic of Yorkshire.',
              ),
            ],
          ),

          // ==========================================
          // ZONE II: THE SECRET GREENWOOD (5 Levels)
          // ==========================================
          QuestLevel(
            id: 'sg_lvl_7',
            literatureId: 'lit_secret_garden',
            levelNumber: 7,
            title: 'Chapter 2: The Robin and the Wall',
            description: 'Uncover the scarlet bird guide and the buried brass key.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: true,
            gemsReward: 30,
            chapterIndex: 1,
            estimatedMinutes: 5,
          ),
          QuestLevel(
            id: 'sg_lvl_8',
            literatureId: 'lit_secret_garden',
            levelNumber: 8,
            title: 'Recall Quiz: The Feathered Guide',
            description: 'Test your memory of the scarlet robin and the garden wall.',
            type: LevelType.recall,
            isCompleted: false,
            isLocked: true,
            gemsReward: 35,
            energyCost: 1,
            chapterIndex: 1,
            customQuestions: [
              const QuizQuestion(
                id: 'sg_lvl8_q1',
                prompt: 'Which wild creature first pierces Mary’s emotional isolation in the grounds?',
                options: [
                  'A friendly robin redbreast with an intelligent gaze and scarlet vest',
                  'An old moorland bloodhound named Bruno',
                  'A talking magpie perched upon the chimney',
                  'A solitary white deer roaming the heather',
                ],
                correctAnswerIndex: 0,
                explanation: 'The cheerful robin redbreast cocked his head and looked at Mary with warm intelligence, melting her cold defense.',
              ),
              const QuizQuestion(
                id: 'sg_lvl8_q2',
                prompt: 'What did Mary whisper softly when the robin looked at her?',
                options: [
                  '“You are not like the birds in India.”',
                  '“Fly away, disagreeable creature.”',
                  '“Lead me to my uncle immediately.”',
                  '“Dost thou know where the gold is buried?”',
                ],
                correctAnswerIndex: 0,
                explanation: 'Mary whispered softly that the robin was unlike any bird in India, feeling genuine warmth for the first time.',
              ),
            ],
          ),
          QuestLevel(
            id: 'sg_lvl_9',
            literatureId: 'lit_secret_garden',
            levelNumber: 9,
            title: 'Symbolism Drill: The Scarlet Vest & Ivy',
            description: 'Explore the literary symbolism of nature awakening human empathy.',
            type: LevelType.practice,
            isCompleted: false,
            isLocked: true,
            gemsReward: 25,
            energyCost: 0,
            chapterIndex: 1,
            customQuestions: [
              const QuizQuestion(
                id: 'sg_lvl9_q1',
                prompt: 'The robin is described boasting a “scarlet” vest. What does scarlet mean?',
                options: [
                  'A brilliant, vivid red color with fiery orange undertones',
                  'A muted charcoal gray suited for winter',
                  'A pale, sickly yellow hue',
                  'A midnight blue resembling dusk',
                ],
                correctAnswerIndex: 0,
                explanation: 'Scarlet is a vibrant, intense red tinged with orange, symbolizing vibrant life and awakening vitality.',
              ),
              const QuizQuestion(
                id: 'sg_lvl9_q2',
                prompt: 'What does the stone “perimeter” wall draped in ivy symbolize?',
                options: [
                  'The defensive, guarded boundaries surrounding both the sanctuary and Mary’s heart',
                  'A military fortification against northern invaders',
                  'A prison built for reclusive kings',
                  'A maze designed for festive fox hunts',
                ],
                correctAnswerIndex: 0,
                explanation: 'The high perimeter wall mirrors Mary’s own guarded interior; both locked away and waiting for tender care.',
              ),
              const QuizQuestion(
                id: 'sg_lvl9_q3',
                prompt: 'What is a “perimeter” as referenced in the text?',
                options: [
                  'The continuous outer boundary line enclosing a designated space or estate',
                  'An iron keyhole fitted into an oak door',
                  'A stone sundial situated in the courtyard',
                  'A gardener’s pruning hook for trailing vines',
                ],
                correctAnswerIndex: 0,
                explanation: 'A perimeter is the complete outer border or boundary enclosing a physical area.',
              ),
            ],
          ),
          QuestLevel(
            id: 'sg_lvl_10',
            literatureId: 'lit_secret_garden',
            levelNumber: 10,
            title: 'Discovery Quiz: The Buried Brass Key',
            description: 'Analyze how the freshly disturbed earth revealed the ten-year secret.',
            type: LevelType.recall,
            isCompleted: false,
            isLocked: true,
            gemsReward: 35,
            energyCost: 1,
            chapterIndex: 1,
            customQuestions: [
              const QuizQuestion(
                id: 'sg_lvl10_q1',
                prompt: 'What drew Mary’s attention to the exact spot where the key was buried?',
                options: [
                  'The robin fluttered down onto a mound of fresh earth disturbed by a dog',
                  'A marked parchment map delivered by the postman',
                  'A glint of golden light shining through the heavy fog',
                  'Old gardener Ben pointed directly at the roots with his spade',
                ],
                correctAnswerIndex: 0,
                explanation: 'The robin flew down to the freshly disturbed earth, revealing the rusted ring protruding from the soil.',
              ),
              const QuizQuestion(
                id: 'sg_lvl10_q2',
                prompt: 'Why was the heavy brass key buried ten years ago?',
                options: [
                  'Archibald Craven buried it in inconsolable grief after his wife tragically died there',
                  'Smugglers hid it beneath the moors to safeguard stolen loot',
                  'It was dropped accidentally during the construction of the west wing',
                  'The servants buried it to prevent Mary from entering England',
                ],
                correctAnswerIndex: 0,
                explanation: 'Mr. Craven locked the door and buried the key after Mrs. Craven’s tragic death, vowing never to reopen it.',
              ),
            ],
          ),
          QuestLevel(
            id: 'sg_lvl_11',
            literatureId: 'lit_secret_garden',
            levelNumber: 11,
            title: 'Zone II Checkpoint: Secrets of Misselthwaite',
            description: 'Consolidate the lore before turning the ancient lock.',
            type: LevelType.practice,
            isCompleted: false,
            isLocked: true,
            gemsReward: 40,
            energyCost: 0,
            chapterIndex: 1,
            customQuestions: [
              const QuizQuestion(
                id: 'sg_lvl11_q1',
                prompt: 'What emotional shift occurs in Mary as she clutches the heavy brass key?',
                options: [
                  'Her heart races with wonder, secret purpose, and eager curiosity',
                  'She feels intense fear and resolves to throw it into the stream',
                  'She immediately brings it to Mrs. Medlock for a reward',
                  'She forgets where she found it and returns to India',
                ],
                correctAnswerIndex: 0,
                explanation: 'Holding the key ignites Mary’s imagination, awakening her curiosity and desire for life.',
              ),
              const QuizQuestion(
                id: 'sg_lvl11_q2',
                prompt: 'What natural element of Yorkshire revived Mary’s failing appetite and pale complexion?',
                options: [
                  'The brisk, clean, heather-scented moorland wind',
                  'Drinking rare herbal teas brewed by colonial doctors',
                  'Sitting in front of a roaring hearth all day',
                  'Riding inside closed carriages across the estate',
                ],
                correctAnswerIndex: 0,
                explanation: 'The crisp, pure winds blowing over the wild Yorkshire moors brought color to her cheeks and restored her strength.',
              ),
            ],
          ),

          // ==========================================
          // ZONE III: THE MEDIEVAL CITADEL & SANCTUARY (5 Levels)
          // ==========================================
          QuestLevel(
            id: 'sg_lvl_12',
            literatureId: 'lit_secret_garden',
            levelNumber: 12,
            title: 'Chapter 3: The Door in the Ivy',
            description: 'Turn the ancient brass key and step through the groaning oak door.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: true,
            gemsReward: 35,
            chapterIndex: 2,
            estimatedMinutes: 5,
          ),
          QuestLevel(
            id: 'sg_lvl_13',
            literatureId: 'lit_secret_garden',
            levelNumber: 13,
            title: 'Recall Quiz: Behind the Ivy Curtain',
            description: 'Recall the sleeping garden, gray rose vines, and silent wonder.',
            type: LevelType.recall,
            isCompleted: false,
            isLocked: true,
            gemsReward: 40,
            energyCost: 1,
            chapterIndex: 2,
            customQuestions: [
              const QuizQuestion(
                id: 'sg_lvl13_q1',
                prompt: 'How was the hidden door revealed through the curtain of ivy?',
                options: [
                  'A strong gust of moorland wind blew suddenly, lifting the thick curtain of leaves',
                  'Mary cut the vines away with a sickle borrowed from the shed',
                  'The robin redbreast pecked at the lock until it fell open',
                  'Dickon tapped the stone three times with a wooden staff',
                ],
                correctAnswerIndex: 0,
                explanation: 'A gust of wind lifted the heavy ivy, exposing the round brass doorknob hidden beneath.',
              ),
              const QuizQuestion(
                id: 'sg_lvl13_q2',
                prompt: 'What sound did the ancient oak door make when Mary turned the brass key?',
                options: [
                  'A stiff, slow, groaning creak as it swung open',
                  'A crystal chime echoing across the moors',
                  'It burst open with a loud thudding crash',
                  'It glided open silently on oiled hinges',
                ],
                correctAnswerIndex: 0,
                explanation: 'Unopened for ten years, the heavy oak door turned with a click and groaning creak.',
              ),
            ],
          ),
          QuestLevel(
            id: 'sg_lvl_14',
            literatureId: 'lit_secret_garden',
            levelNumber: 14,
            title: 'Philosophy & Theme: Tend a Rose',
            description: 'Reflect upon "Where you tend a rose, my lad, a thistle cannot grow."',
            type: LevelType.practice,
            isCompleted: false,
            isLocked: true,
            gemsReward: 30,
            energyCost: 0,
            chapterIndex: 2,
            customQuestions: [
              const QuizQuestion(
                id: 'sg_lvl14_q1',
                prompt: 'In the novel’s central theme, what does a "thistle" symbolize?',
                options: [
                  'Spiny, bitter weeds of resentment and neglect that choke the human spirit',
                  'A rare medicinal herb used to cure lung ailments',
                  'The heraldic badge of Yorkshire nobility',
                  'The wild winds that sweep across the cliffs',
                ],
                correctAnswerIndex: 0,
                explanation: 'Thistles are sharp, prickly wild weeds representing anger and bitterness, driven out when love and beauty (roses) are cultivated.',
              ),
              const QuizQuestion(
                id: 'sg_lvl14_q2',
                prompt: 'The climbing rose vines inside the slumbering garden appeared as:',
                options: [
                  'Tangled gray webs of slumber waiting to awaken with the spring',
                  'Dead, brittle sticks that could never bloom again',
                  'Poisonous brambles placed by ancient wizards',
                  'Vibrant crimson garlands ready for harvest',
                ],
                correctAnswerIndex: 0,
                explanation: 'The climbing vines were gray and leafless, hanging like delicate webs in a mysterious slumber.',
              ),
            ],
          ),
          QuestLevel(
            id: 'sg_lvl_15',
            literatureId: 'lit_secret_garden',
            levelNumber: 15,
            title: 'Character Evolution: The Awakening Heart',
            description: 'Evaluate Mary’s metamorphosis from tyrannical child to passionate steward.',
            type: LevelType.recall,
            isCompleted: false,
            isLocked: true,
            gemsReward: 45,
            energyCost: 1,
            chapterIndex: 2,
            customQuestions: [
              const QuizQuestion(
                id: 'sg_lvl15_q1',
                prompt: 'What profound transformation does Mary experience upon stepping into the garden?',
                options: [
                  'Her tyrannical selfishness dissolves into gentle reverence and stewardship for life',
                  'She decides to hide inside and never speak to another living person',
                  'She is frightened by the silence and locks the door forever',
                  'She demands that servants cut all the roses down immediately',
                ],
                correctAnswerIndex: 0,
                explanation: 'Standing in the enchanted sanctuary, Mary is transformed from a sour, neglected child into a devoted guardian of living green things.',
              ),
              const QuizQuestion(
                id: 'sg_lvl15_q2',
                prompt: 'Who shares Mary’s secret devotion and helps her bring the dormant sanctuary back to life?',
                options: [
                  'Dickon, the animal-charming moorland boy, and Colin Craven',
                  'Lord Archibald Craven alone',
                  'The strict housekeeper Mrs. Medlock',
                  'Her former nursemaid from Calcutta',
                ],
                correctAnswerIndex: 0,
                explanation: 'Dickon and Colin join Mary in secret, cultivating the soil and restoring happiness to Misselthwaite.',
              ),
            ],
          ),
          QuestLevel(
            id: 'sg_lvl_16',
            literatureId: 'lit_secret_garden',
            levelNumber: 16,
            title: 'Grand Apex Assessment: The Secret Garden Masterwork',
            description: 'Achieve 100% on the comprehensive guild exam to conquer the work and claim a Golden Key!',
            type: LevelType.finalTest,
            isCompleted: false,
            isLocked: true,
            gemsReward: 100,
            energyCost: 2,
            chapterIndex: 2,
            customQuestions: [
              const QuizQuestion(
                id: 'sg_apex_q1',
                prompt: 'Who penned the timeless literary classic "The Secret Garden"?',
                options: ['Frances Hodgson Burnett', 'Charlotte Brontë', 'Jane Austen', 'Louisa May Alcott'],
                correctAnswerIndex: 0,
                explanation: 'The classic was authored by Frances Hodgson Burnett in 1911.',
              ),
              const QuizQuestion(
                id: 'sg_apex_q2',
                prompt: 'What is an "Ayah"?',
                options: [
                  'A native Indian nursemaid entrusted with raising British children',
                  'A traditional colonial carriage',
                  'A type of spicy Yorkshire tea',
                  'A brass gardening spade',
                ],
                correctAnswerIndex: 0,
                explanation: 'Ayah is the Anglo-Indian word for nursemaid or nanny.',
              ),
              const QuizQuestion(
                id: 'sg_apex_q3',
                prompt: 'What color was the robin redbreast’s brilliant vest?',
                options: ['Scarlet', 'Emerald', 'Indigo', 'Silver'],
                correctAnswerIndex: 0,
                explanation: 'The robin proudly sported a brilliant scarlet vest.',
              ),
              const QuizQuestion(
                id: 'sg_apex_q4',
                prompt: 'Where was the heavy brass key discovered?',
                options: [
                  'In a mound of earth freshly disturbed by a dog',
                  'Under the mattress of Archibald Craven',
                  'At the bottom of the moorland fountain',
                  'In an antique cedar cabinet in the library',
                ],
                correctAnswerIndex: 0,
                explanation: 'The robin guided Mary to the freshly disturbed earth where the rusted ring lay buried.',
              ),
              const QuizQuestion(
                id: 'sg_apex_q5',
                prompt: 'What does the phrase "Where you tend a rose, my lad, a thistle cannot grow" mean?',
                options: [
                  'Nurturing goodness, love, and care leaves no room for bitterness and thorns',
                  'Roses consume all soil nutrients, destroying other plants',
                  'Gardens should never be planted near moorland borders',
                  'One must always wear heavy gloves when tending flowerbeds',
                ],
                correctAnswerIndex: 0,
                explanation: 'The quote is a moral allegory: filling the heart with beauty and care leaves no place for anger or despair.',
              ),
            ],
          ),
        ],
        recallQuizzes: {
          0: [
            const QuizQuestion(
              id: 'sg_q1',
              prompt: 'Where was Mary Lennox born and raised before moving to England?',
              options: ['India', 'Scotland', 'Spain', 'France'],
              correctAnswerIndex: 0,
              explanation:
                  'Mary was born in India to an English government official and a socialite mother.',
            ),
            const QuizQuestion(
              id: 'sg_q2',
              prompt: 'How did people describe Mary Lennox’s disposition as a child?',
              options: [
                'Sweet and charming',
                'Tyrannical, selfish, and sour',
                'Mischievous yet beloved',
                'Shy and studious',
              ],
              correctAnswerIndex: 1,
              explanation:
                  'Burnett describes Mary as tyrannical, sour-faced, and spoiled because the servants always obeyed her.',
            ),
            const QuizQuestion(
              id: 'sg_q3',
              prompt: 'What tragic epidemic struck the compound, leaving Mary orphaned?',
              options: ['The Black Plague', 'Yellow Fever', 'Cholera', 'Scarlet Fever'],
              correctAnswerIndex: 2,
              explanation:
                  'Cholera swept through the station in India, taking Mary’s parents and Ayah.',
            ),
            const QuizQuestion(
              id: 'sg_q4',
              prompt: 'What does the colonial term "Ayah" refer to in the story?',
              options: [
                'A native Indian nursemaid or nanny',
                'A tropical flower garland',
                'A horse-drawn carriage',
                'A military rank',
              ],
              correctAnswerIndex: 0,
              explanation:
                  'An Ayah was a native Indian nursemaid responsible for child-rearing in Anglo-Indian households.',
            ),
            const QuizQuestion(
              id: 'sg_q5',
              prompt: 'Why was Mary’s mother largely absent from her upbringing?',
              options: [
                'She lived in London',
                'She was a great social beauty who cared only for parties and society',
                'She was a scholar studying botany',
                'She had abandoned the family years prior',
              ],
              correctAnswerIndex: 1,
              explanation:
                  'Mary’s mother cared only to go to parties and amuse herself with gay people, handing Mary to the Ayah.',
            ),
          ],
          1: [
            const QuizQuestion(
              id: 'sg_q2_1',
              prompt: 'Which friendly bird befriends Mary upon the Yorkshire manor grounds?',
              options: ['A barn owl', 'A robin redbreast with a scarlet vest', 'A blue magpie', 'A goldfinch'],
              correctAnswerIndex: 1,
              explanation:
                  'The robin redbreast with his brilliant scarlet vest guides Mary toward companionship and discovery.',
            ),
            const QuizQuestion(
              id: 'sg_q2_2',
              prompt: 'For how many years had the secret walled garden remained locked?',
              options: ['Five years', 'Ten years', 'Twenty years', 'A century'],
              correctAnswerIndex: 1,
              explanation:
                  'The garden had been locked away for ten years following the tragic loss of Mrs. Craven.',
            ),
            const QuizQuestion(
              id: 'sg_q2_3',
              prompt: 'What had recently disturbed the fresh mound of earth where the robin landed?',
              options: ['A farmer’s plough', 'A dog digging in the soil', 'A badger burrow', 'A falling branch'],
              correctAnswerIndex: 1,
              explanation:
                  'The robin fluttered down onto a mound of earth that a dog had recently disturbed.',
            ),
            const QuizQuestion(
              id: 'sg_q2_4',
              prompt: 'What did Mary discover protruding from the upturned earth?',
              options: [
                'A silver pocket watch',
                'A small ring of rusty iron which proved to be an old brass key',
                'A buried porcelain doll',
                'A bronze sword hilt',
              ],
              correctAnswerIndex: 1,
              explanation:
                  'A ring of rusty iron caught her eye—it was the heavy brass key to the locked garden.',
            ),
          ],
          2: [
            const QuizQuestion(
              id: 'sg_q3_1',
              prompt: 'How was the hidden door latch revealed beneath the ivy wall?',
              options: [
                'A gardener pointed it out with his cane',
                'A sudden strong gust of moorland wind lifted the thick curtain of ivy',
                'Mary scraped the wall with a trowel',
                'Colin gave her a detailed map',
              ],
              correctAnswerIndex: 1,
              explanation:
                  'A brisk gust of Yorkshire wind blew aside the heavy curtain of ivy, exposing the round brass doorknob.',
            ),
            const QuizQuestion(
              id: 'sg_q3_2',
              prompt: 'What sound occurred when Mary turned the key in the oak door?',
              options: [
                'It broke cleanly in half',
                'It turned stiffly with a sharp, heavy click',
                'A loud alarm bell rang out',
                'It turned silently without resistance',
              ],
              correctAnswerIndex: 1,
              explanation:
                  'It was stiff, but with both hands she turned it with a sharp click before the groaning door swung open.',
            ),
            const QuizQuestion(
              id: 'sg_q3_3',
              prompt: 'What mysterious visual greeted Mary inside the secret garden?',
              options: [
                'Freshly pruned modern hedges',
                'Silent enchanted climbing gray rose vines like tangled webs of slumber',
                'Fountains overflowing with fresh water',
                'A completely empty bare dirt courtyard',
              ],
              correctAnswerIndex: 1,
              explanation:
                  'It was silent, enchanted, and filled with climbing gray rose vines that looked like tangled webs of slumber.',
            ),
          ],
        },
        practiceQuizzes: {
          0: [
            const QuizQuestion(
              id: 'sg_pq0_1',
              prompt: 'What does the word "tyrannical" mean as used to describe young Mary?',
              options: [
                'Ruling autocratically and demanding unquestioning obedience',
                'Exceedingly kind and gentle',
                'Frightened of speaking to strangers',
                'Devoted to religious scholarship',
              ],
              correctAnswerIndex: 0,
              explanation:
                  'Tyrannical signifies imperious and demanding behavior, expecting everyone to yield instantly.',
            ),
            const QuizQuestion(
              id: 'sg_pq0_2',
              prompt: 'What landscape characterizes the setting of Misselthwaite Manor in Yorkshire?',
              options: [
                'A sandy desert oasis',
                'A vast, wild expanse of windy moorland covered with heather',
                'A dense tropical rainforest',
                'A bustling harbor city',
              ],
              correctAnswerIndex: 1,
              explanation:
                  'Misselthwaite sits on the edge of the wild Yorkshire moors, windy and purple with heather.',
            ),
          ],
          1: [
            const QuizQuestion(
              id: 'sg_pq1',
              prompt: 'Which friendly bird befriends Mary upon the manor grounds?',
              options: ['A barn owl', 'A robin redbreast', 'A blue magpie', 'A goldfinch'],
              correctAnswerIndex: 1,
              explanation:
                  'The robin redbreast with his brilliant scarlet vest guides Mary toward companionship and discovery.',
            ),
            const QuizQuestion(
              id: 'sg_pq2',
              prompt: 'For how many years had the secret walled garden remained locked?',
              options: ['Five years', 'Ten years', 'Twenty years', 'A century'],
              correctAnswerIndex: 1,
              explanation:
                  'The garden had been locked away for ten years following the tragic loss of Mrs. Craven.',
            ),
            const QuizQuestion(
              id: 'sg_pq3',
              prompt: 'What kind of weather cleared before Mary encountered the robin?',
              options: [
                'A blinding snowstorm',
                'The Yorkshire rain stopped and gray mist lifted into pale sky',
                'A tropical monsoon',
                'A sweltering heatwave',
              ],
              correctAnswerIndex: 1,
              explanation:
                  'The rain had stopped and the gray mist lifted, leaving the Yorkshire sky pale and clear.',
            ),
            const QuizQuestion(
              id: 'sg_pq4',
              prompt: 'What emotional sensation does Mary experience when the robin cocks his head at her?',
              options: [
                'Terror and suspicion',
                'Something softened inside her chest for the first time',
                'Boredom and indifference',
                'Anger at being watched',
              ],
              correctAnswerIndex: 1,
              explanation:
                  'Mary felt an unfamiliar warmth and softening in her chest when the intelligent little bird looked at her.',
            ),
          ],
          2: [
            const QuizQuestion(
              id: 'sg_pq2_1',
              prompt: 'What famous philosophical quote is spoken regarding tending the garden?',
              options: [
                '"Where you tend a rose, my lad, a thistle cannot grow."',
                '"Gold is the only flower that never fades."',
                '"Leave the gates open for the night."',
                '"Only the strong survive the winter."',
              ],
              correctAnswerIndex: 0,
              explanation:
                  'The core metaphor of the novel is: "Where you tend a rose, my lad, a thistle cannot grow."',
            ),
            const QuizQuestion(
              id: 'sg_pq2_2',
              prompt: 'What happens to Mary’s physical and emotional health once she enters the garden?',
              options: [
                'Her yellow sickly pallor and sour mood transform into healthy, loving vigor',
                'She becomes even more secluded and angry',
                'She decides to immediately return to India',
                'She loses interest in nature completely',
              ],
              correctAnswerIndex: 0,
              explanation:
                  'Working the soil and caring for the sleeping rose vines revitalizes Mary’s spirit and body.',
            ),
          ],
        },
        finalExam: [
          const QuizQuestion(
            id: 'sg_fq1',
            prompt: 'What uncovered the buried brass key in the earth near the perimeter wall?',
            options: [
              'A spade left by Ben Weatherstaff',
              'A dog digging near the robin redbreast',
              'A torrential rainstorm washing away mud',
              'Mary tripping over a stone',
            ],
            correctAnswerIndex: 1,
            explanation:
                'The robin perched on freshly upturned earth dug up by a dog, revealing the ring of the key.',
          ),
          const QuizQuestion(
            id: 'sg_fq2',
            prompt: 'How was the hidden door latch revealed beneath the ivy?',
            options: [
              'A gardener pointed it out with his cane',
              'A sudden strong gust of moorland wind lifted the thick drapery of ivy',
              'Mary scraped the wall with a trowel',
              'Colin dreamed of its location',
            ],
            correctAnswerIndex: 1,
            explanation:
                'A brisk gust of Yorkshire wind blew aside the heavy curtain of ivy, exposing the round brass doorknob.',
          ),
          const QuizQuestion(
            id: 'sg_fq3',
            prompt: 'What central theme embodies Mary’s transformation throughout the story?',
            options: [
              'The pursuit of royal power and wealth',
              'Healing, renewal, and mutual empathy through nature and honest connection',
              'Conquering external foes with chivalric weapons',
              'Renouncing family in search of worldly fame',
            ],
            correctAnswerIndex: 1,
            explanation:
                'The revival of the slumbering garden parallels Mary’s emotional blooming from bitterness into love.',
          ),
          const QuizQuestion(
            id: 'sg_fq4',
            prompt: 'What did the secret garden look like when Mary first stepped inside?',
            options: [
              'Filled with bright blooming tulips and stone fountains',
              'Slumbering under gray climbing rose vines like tangled webs',
              'Burned down to bare ashes',
              'A paved courtyard with marble statues',
            ],
            correctAnswerIndex: 1,
            explanation:
                'It was quiet and enchanted, filled with leafless gray rose vines hanging like tangled webs of sleep.',
          ),
          const QuizQuestion(
            id: 'sg_fq5',
            prompt: 'Who is the mystical moorland boy who can talk with wild animals and charm foxes?',
            options: ['Colin Craven', 'Dickon Sowerby', 'Sancho Panza', 'Ben Weatherstaff'],
            correctAnswerIndex: 1,
            explanation:
                'Dickon Sowerby, Martha’s brother, possesses a gentle magic with the creatures of the Yorkshire moor.',
          ),
          const QuizQuestion(
            id: 'sg_fq6',
            prompt: 'Who is the bedridden, screaming boy Mary discovers hidden in the dark wings of the manor?',
            options: ['Colin Craven, her invalid cousin', 'Dickon', 'A stray orphan', 'Her long-lost brother'],
            correctAnswerIndex: 0,
            explanation:
                'Colin Craven, Mary’s cousin, was convinced he was a hunchback and was kept locked away in gloom.',
          ),
          const QuizQuestion(
            id: 'sg_fq7',
            prompt: 'What memorable quote captures the philosophical spirit of tending the garden?',
            options: [
              '"Where you tend a rose, my lad, a thistle cannot grow."',
              '"Fortune favors only the wealthy."',
              '"Knowledge is sorrow in disguise."',
              '"A locked door must never be forced."',
            ],
            correctAnswerIndex: 0,
            explanation:
                'Burnett writes: "Where you tend a rose, my lad, a thistle cannot grow"—a metaphor for nourishing positive thoughts.',
          ),
          const QuizQuestion(
            id: 'sg_fq8',
            prompt: 'What miracle occurs to Colin through working and playing in the garden?',
            options: [
              'He finds a buried chest of rubies',
              'His strength returns, his spine straightens, and he learns to walk and run',
              'He becomes a master sailor',
              'He decides to move back to London',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Fresh air, honest companionship, and digging in the earth heal Colin until he stands proud and strong.',
          ),
          const QuizQuestion(
            id: 'sg_fq9',
            prompt: 'How does Archibald Craven discover that joy has returned to his ancestral home?',
            options: [
              'He reads a letter from the governor',
              'Guided by a mysterious inner peace, he returns and hears his son’s laughter bursting from the garden',
              'A telegram arrives at his hotel in Austria',
              'A police constable brings news',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Craven returns to Misselthwaite Manor drawn by an inner awakening and finds Colin running outside.',
          ),
          const QuizQuestion(
            id: 'sg_fq10',
            prompt: 'What grand reward does Quixoria award for achieving a 100% perfect score on this Grand Assessment?',
            options: [
              'A standard bronze coin',
              'A Golden Key capable of unlocking any literary masterwork regardless of gem cost',
              'A reset of all game progress',
              'An automatic sign-out',
            ],
            correctAnswerIndex: 1,
            explanation:
                'A perfect score crowns the scholar with a rare Golden Key, allowing free access to legendary literature!',
          ),
        ],
      ),

      // 2. The Wind in the Willows (Kenneth Grahame) - Owned
      Literature(
        id: 'lit_wind_in_willows',
        title: 'The Wind in the Willows',
        author: 'Kenneth Grahame',
        description:
            'A timeless tale of pastoral camaraderie following Mole, the Water Rat, Badger, and the delightfully reckless Mr. Toad of Toad Hall along the gentle riverbank.',
        type: LiteratureType.novel,
        genres: ['Adventure', 'Classics', 'Fantasy'],
        gemCost: 550,
        isOwned: true,
        currentLevelIndex: 0,
        chaptersCompleted: 0,
        gemsEarned: 0,
        totalChapters: 2,
        chapters: [
          const Chapter(
            id: 'ww_ch1',
            chapterNumber: 1,
            title: 'The River Bank',
            estimatedMinutes: 5,
            quoteHighlight:
                'Believe me, my young friend, there is nothing—absolute nothing—half so much worth doing as simply messing about in boats.',
            quoteContext: 'Ratty speaking to Mole on the riverbank',
            content: '''
The Mole had been working very hard all the morning, spring-cleaning his little home. First with brooms, then with dusters; then on ladders and steps and chairs, with a brush and a pail of whitewash; till he had dust in his throat and eyes, and splashes of whitewash all over his black fur, and an aching back and weary arms.

Spring was moving in the air above and in the earth below and around him, penetrating even his dark and lowly little house with its spirit of divine discontent and longing.

It was small wonder, then, that he suddenly flung down his brush on the floor, said "Bother!" and "O blow!" and also "Hang spring-cleaning!" and bolted out of the house without even waiting to put on his coat.

He scraped and scratched and scrabbled, and then he scrabbled again and scratched and scraped, working busily with his little paws and muttering to himself, "Up we go! Up we go!" till at last, pop! His snout came out into the sunlight, and he found himself rolling in the warm grass of a great meadow.

Never in his life had he seen a river before—this sleek, sinuous, full-bodied animal, chasing and chuckling, gripping things with a gurgle and leaving them with a laugh, to fling itself on fresh playmates that shook themselves free, and were caught and held again. All was a-shake and a-shiver—glints and gleams and sparkles, rustle and swirl, chatter and bubble. The Mole was bewitched, entranced, fascinated. By the side of the river he trotted as one trots, when a small child, by the side of a man who holds one spellbound by exciting stories.
''',
          ),
          const Chapter(
            id: 'ww_ch2',
            chapterNumber: 2,
            title: 'The Open Road',
            estimatedMinutes: 4,
            quoteHighlight:
                'Here today, in next week tomorrow! Tomorrow, the world!',
            quoteContext: 'Toad extolling the glory of caravans and motor cars',
            content: '''
"Ratty," said the Mole suddenly, one bright summer morning, "will you take me to call on Mr. Toad? I have heard so much about him, and I do so want to make his acquaintance."

"Why, certainly," said the good-natured Rat, jumping to his feet and dragging his sculls out of the boathouse. "Get the boat out, and we will paddle up there at once. It's never the wrong time to call on Toad. Early or late he's always the same fellow. Always good-tempered, always glad to see you, always sorry when you go!"

They found Toad sitting on an armchair on the lawn of Toad Hall, studying a large map spread out upon his knees.

"Hooray!" cried the Toad, jumping up. "This is splendid of you, fellow travelers! You are the very animals I wanted to see. I am about to embark upon the grandest expedition ever known!"
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'ww_lvl_1',
            literatureId: 'lit_wind_in_willows',
            levelNumber: 1,
            title: 'Chapter 1: The River Bank',
            description: 'Mole abandons spring-cleaning to discover the magical river.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 30,
            chapterIndex: 0,
          ),
          QuestLevel(
            id: 'ww_lvl_2',
            literatureId: 'lit_wind_in_willows',
            levelNumber: 2,
            title: 'Recall Quiz: Ratty & Mole',
            description: 'Test what you recall about the beloved boating encounter.',
            type: LevelType.recall,
            isCompleted: false,
            isLocked: true,
            gemsReward: 35,
            energyCost: 1,
            chapterIndex: 0,
          ),
          QuestLevel(
            id: 'ww_lvl_practice',
            literatureId: 'lit_wind_in_willows',
            levelNumber: 3,
            title: 'Vocabulary: Riverbank Diction & Metaphor',
            description: 'Analyze pastoral imagery and rhetoric in Grahame\'s prose.',
            type: LevelType.practice,
            isCompleted: false,
            isLocked: true,
            gemsReward: 35,
            energyCost: 0,
            chapterIndex: 0,
          ),
          QuestLevel(
            id: 'ww_lvl_analysis',
            literatureId: 'lit_wind_in_willows',
            levelNumber: 4,
            title: 'Subtext: Camaraderie & The Call of Nature',
            description: 'Inferential deduction: examine Mole\'s yearning and the comforting refuge of the river.',
            type: LevelType.analysis,
            isCompleted: false,
            isLocked: true,
            gemsReward: 40,
            energyCost: 1,
            chapterIndex: 0,
          ),
          QuestLevel(
            id: 'ww_lvl_ch1_mastery',
            literatureId: 'lit_wind_in_willows',
            levelNumber: 5,
            title: 'Mastery: The River as Living Sanctuary',
            description: 'Thematic synthesis: evaluate friendship, domesticity, and the idyllic wild.',
            type: LevelType.finalTest,
            isCompleted: false,
            isLocked: true,
            gemsReward: 60,
            energyCost: 2,
            chapterIndex: 0,
          ),
          QuestLevel(
            id: 'ww_lvl_3',
            literatureId: 'lit_wind_in_willows',
            levelNumber: 6,
            title: 'Chapter 2: The Open Road',
            description: 'Meet the exuberant Mr. Toad at historic Toad Hall.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: true,
            gemsReward: 30,
            chapterIndex: 1,
          ),
          QuestLevel(
            id: 'ww_lvl_4',
            literatureId: 'lit_wind_in_willows',
            levelNumber: 7,
            title: 'Grand Assessment: The Riverbank Saga',
            description: 'Achieve 100% to earn a Golden Key!',
            type: LevelType.finalTest,
            isCompleted: false,
            isLocked: true,
            gemsReward: 90,
            energyCost: 2,
            chapterIndex: 1,
          ),
        ],
        recallQuizzes: {
          0: [
            const QuizQuestion(
              id: 'ww_q1',
              prompt: 'What was Mole doing before he impulsively bolted outside?',
              options: ['Baking bread', 'Spring-cleaning his underground home', 'Fishing for minnows', 'Writing a letter'],
              correctAnswerIndex: 1,
              explanation: 'Mole was whitewashing and dusting his underground burrows when spring called.',
            ),
            const QuizQuestion(
              id: 'ww_q2',
              prompt: 'What did Ratty claim was the single most worthwhile thing in life?',
              options: [
                'Counting gold coins',
                'Simply messing about in boats',
                'Sleeping in late during autumn',
                'Traveling to faraway cities',
              ],
              correctAnswerIndex: 1,
              explanation: 'Water Rat famously declared: "There is nothing—half so much worth doing as simply messing about in boats."',
            ),
          ],
        },
        practiceQuizzes: {},
        finalExam: [
          const QuizQuestion(
            id: 'ww_fq1',
            prompt: 'Where does the eccentric and wealthy Mr. Toad reside?',
            options: ['Mole End', 'The Wild Wood', 'Toad Hall', 'The Old Mill'],
            correctAnswerIndex: 2,
            explanation: 'Toad lives in the grand ancestral residence known as Toad Hall.',
          ),
        ],
      ),

      // 3. Hope is the Thing with Feathers (Emily Dickinson) - Owned Poem
      Literature(
        id: 'lit_hope_feathers',
        title: 'Hope is the Thing with Feathers',
        author: 'Emily Dickinson',
        description:
            'A sublime lyrical meditation on the resilient and unyielding nature of the human spirit, figured as an indefatigable songbird.',
        type: LiteratureType.poem,
        genres: ['Poetry', 'Classics'],
        gemCost: 250,
        isOwned: true,
        currentLevelIndex: 0,
        chaptersCompleted: 0,
        gemsEarned: 0,
        totalChapters: 1,
        chapters: [
          const Chapter(
            id: 'hf_ch1',
            chapterNumber: 1,
            title: 'The Unyielding Songbird',
            estimatedMinutes: 2,
            quoteHighlight:
                '“Hope” is the thing with feathers - That perches in the soul - And sings the tune without the words - And never stops - at all -',
            quoteContext: 'Stanza I - The central metaphor of hope',
            content: '''
“Hope” is the thing with feathers -
That perches in the soul -
And sings the tune without the words -
And never stops - at all -

And sweetest - in the Gale - is heard -
And sore must be the storm -
That could abash the little Bird
That kept so many warm -

I’ve heard it in the chillest land -
And on the strangest Sea -
Yet - never - in Extremity,
It asked a crumb - of me.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 'hf_lvl_1',
            literatureId: 'lit_hope_feathers',
            levelNumber: 1,
            title: 'Recite: The Songbird of Soul',
            description: 'Immerse in Emily Dickinson’s timeless stanza.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 20,
            chapterIndex: 0,
          ),
          QuestLevel(
            id: 'hf_lvl_2',
            literatureId: 'lit_hope_feathers',
            levelNumber: 2,
            title: 'Recall: Feathers in the Gale',
            description: 'Reflect upon Dickinson’s metaphors and rhyme.',
            type: LevelType.recall,
            isCompleted: false,
            isLocked: true,
            gemsReward: 30,
            energyCost: 1,
            chapterIndex: 0,
          ),
          QuestLevel(
            id: 'hf_lvl_practice',
            literatureId: 'lit_hope_feathers',
            levelNumber: 3,
            title: 'Practice: Common Meter & Lyric Poetics',
            description: 'Examine Dickinson\'s signature hymn meter and dashes.',
            type: LevelType.practice,
            isCompleted: false,
            isLocked: true,
            gemsReward: 35,
            energyCost: 0,
            chapterIndex: 0,
          ),
          QuestLevel(
            id: 'hf_lvl_analysis',
            literatureId: 'lit_hope_feathers',
            levelNumber: 4,
            title: 'Subtext: Psychological Resilience & Faith',
            description: 'Inferential deduction: explore the unyielding, unrequited devotion of hope in adversity.',
            type: LevelType.analysis,
            isCompleted: false,
            isLocked: true,
            gemsReward: 40,
            energyCost: 1,
            chapterIndex: 0,
          ),
          QuestLevel(
            id: 'hf_lvl_3',
            literatureId: 'lit_hope_feathers',
            levelNumber: 5,
            title: 'Mastery: Final Poem Assessment',
            description: 'A perfect score unlocks the Golden Key!',
            type: LevelType.finalTest,
            isCompleted: false,
            isLocked: true,
            gemsReward: 60,
            energyCost: 2,
            chapterIndex: 0,
          ),
        ],
        recallQuizzes: {
          0: [
            const QuizQuestion(
              id: 'hf_q1',
              prompt: 'What creature does Dickinson compare “Hope” to?',
              options: ['A silent owl', 'A caged lion', 'A feathered bird that perches in the soul', 'A gentle deer'],
              correctAnswerIndex: 2,
              explanation: 'Dickinson characterizes Hope as “the thing with feathers that perches in the soul.”',
            ),
            const QuizQuestion(
              id: 'hf_q2',
              prompt: 'What did the little Bird ask in return for singing through extremities?',
              options: ['A pot of gold', 'Not even a crumb', 'A warm hearth', 'A golden cage'],
              correctAnswerIndex: 1,
              explanation: 'The poet writes: “Yet - never - in Extremity, / It asked a crumb - of me.”',
            ),
          ],
        },
        practiceQuizzes: {},
        finalExam: [
          const QuizQuestion(
            id: 'hf_fq1',
            prompt: 'In what atmospheric condition is the song of Hope heard as “sweetest”?',
            options: ['In a calm summer dawn', 'In the Gale', 'Beneath the midday sun', 'Inside a quiet library'],
            correctAnswerIndex: 1,
            explanation: 'Dickinson notes that Hope’s tune is heard sweetest in the Gale (storms and trials).',
          ),
        ],
      ),

      // 4. Sonnet 18: Shall I compare thee to a summer's day? (Shakespeare) - In Shop (400 Gems)
      Literature(
        id: 'lit_sonnet_18',
        title: 'Sonnet 18: Summer’s Day',
        author: 'William Shakespeare',
        description:
            'Perhaps the most celebrated sonnet in the English language, praising an eternal beloved whose beauty shall outlive mortality through poetry.',
        type: LiteratureType.sonnet,
        genres: ['Poetry', 'Classics'],
        gemCost: 400,
        isOwned: false,
        totalChapters: 1,
        chapters: [
          const Chapter(
            id: 's18_ch1',
            chapterNumber: 1,
            title: 'The Eternal Lines to Time',
            estimatedMinutes: 2,
            quoteHighlight:
                'So long as men can breathe or eyes can see, So long lives this, and this gives life to thee.',
            quoteContext: 'The closing couplet granting immortality',
            content: '''
Shall I compare thee to a summer’s day?
Thou art more lovely and more temperate:
Rough winds do shake the darling buds of May,
And summer’s lease hath all too short a date;
Sometime too hot the eye of heaven shines,
And often is his gold complexion dimm'd;
And every fair from fair sometime declines,
By chance or nature’s changing course untrimm'd;
But thy eternal summer shall not fade,
Nor lose possession of that fair thou ow’st;
Nor shall Death brag thou wander’st in his shade,
When in eternal lines to time thou grow’st:
  So long as men can breathe or eyes can see,
  So long lives this, and this gives life to thee.
''',
          ),
        ],
        questLevels: [
          QuestLevel(
            id: 's18_lvl_1',
            literatureId: 'lit_sonnet_18',
            levelNumber: 1,
            title: 'Read: The Immortal Verse',
            description: 'Contemplate the fourteen lines of iambic pentameter.',
            type: LevelType.read,
            isCompleted: false,
            isLocked: false,
            gemsReward: 25,
            chapterIndex: 0,
          ),
          QuestLevel(
            id: 's18_lvl_2',
            literatureId: 'lit_sonnet_18',
            levelNumber: 2,
            title: 'Recall: Metaphors of Summer & Time',
            description: 'Reflect upon Shakespeare\'s comparisons to the summer sun.',
            type: LevelType.recall,
            isCompleted: false,
            isLocked: true,
            gemsReward: 30,
            energyCost: 1,
            chapterIndex: 0,
            customQuestions: [
              const QuizQuestion(
                id: 's18_q1',
                prompt: 'According to the poet, what does "summer’s lease" have?',
                options: ['All too short a date', 'An eternal bond', 'A golden guarantee', 'A stormy winter'],
                correctAnswerIndex: 0,
                explanation: 'Line 4 declares: "And summer’s lease hath all too short a date."',
              ),
              const QuizQuestion(
                id: 's18_q2',
                prompt: 'What gives immortality to the beloved in the final rhyming couplet?',
                options: ['The poem itself ("this gives life to thee")', 'A portrait in oil', 'A statue in stone', 'A song sung by angels'],
                correctAnswerIndex: 0,
                explanation: 'The closing lines promise that so long as men breathe, "this gives life to thee."',
              ),
            ],
          ),
          QuestLevel(
            id: 's18_lvl_3',
            literatureId: 'lit_sonnet_18',
            levelNumber: 3,
            title: 'Practice: Rhyme Scheme & Volta',
            description: 'Identify the ABAB CDCD EFEF GG structure and the turn of thought.',
            type: LevelType.practice,
            isCompleted: false,
            isLocked: true,
            gemsReward: 35,
            energyCost: 0,
            chapterIndex: 0,
          ),
          QuestLevel(
            id: 's18_lvl_analysis',
            literatureId: 'lit_sonnet_18',
            levelNumber: 4,
            title: 'Subtext: The Volta & Defiance of Death',
            description: 'Inferential deduction: explore the poetic turn at line 9 and humanity\'s triumph over time.',
            type: LevelType.analysis,
            isCompleted: false,
            isLocked: true,
            gemsReward: 40,
            energyCost: 1,
            chapterIndex: 0,
          ),
          QuestLevel(
            id: 's18_lvl_4',
            literatureId: 'lit_sonnet_18',
            levelNumber: 5,
            title: 'Mastery Exam: The Immortal Verse',
            description: 'Attain complete mastery of the Elizabethan sonnet form.',
            type: LevelType.finalTest,
            isCompleted: false,
            isLocked: true,
            gemsReward: 50,
            energyCost: 2,
            chapterIndex: 0,
          ),
        ],
        recallQuizzes: {},
        practiceQuizzes: {},
        finalExam: [],
      ),

      // 5. Don Quixote de La Mancha (Miguel de Cervantes) - Fully expanded 10 levels
      ClassicsExpansionData.getDonQuixote(),

      // 6. Sherlock Holmes: A Study in Scarlet (Sir Arthur Conan Doyle) - Fully expanded 10 levels
      ClassicsExpansionData.getStudyInScarlet(),

      // 7. Around the World in 80 Days (Jules Verne) - Fully expanded 10 levels
      ClassicsExpansionData.getAroundTheWorldIn80Days(),

      // 8. Pride and Prejudice (Jane Austen) - Fully expanded 10 levels
      ClassicsExpansionData.getPrideAndPrejudice(),

      // 9..42. Massive Classical & World Literature Library (40+ Books)
      ...LibraryCatalogData.getExpandedBooks(),
    ];
  }
}
