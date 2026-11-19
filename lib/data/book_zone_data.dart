import 'package:flutter/material.dart';
import '../models/literature.dart';

/// Metadata for a single zone banner on a book's Quest Map.
class BookZoneMeta {
  final String title;
  final String subtitle;
  final IconData icon;

  const BookZoneMeta({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

/// Complete 3-zone literary world setting + final mastery apex for a book.
class BookWorldSetting {
  final BookZoneMeta zone1;
  final BookZoneMeta zone2;
  final BookZoneMeta zone3;
  final String apexTitle;
  final String apexSubtitle;

  const BookWorldSetting({
    required this.zone1,
    required this.zone2,
    required this.zone3,
    required this.apexTitle,
    required this.apexSubtitle,
  });
}

/// Maps every book in Quixoria's 42-book catalog to its own authentic literary
/// settings, zones, and final landmark — never repeating "Plains of La Mancha"
/// on unrelated books.
class BookZoneData {
  static BookWorldSetting forLiterature(Literature lit) {
    final mapped = _catalogZones[lit.id];
    if (mapped != null) return mapped;

    // Smart fallback using the book's own chapter titles if a custom book is added later
    final ch1 = lit.chapters.isNotEmpty ? lit.chapters[0].title : 'The Opening Chapters';
    final ch2 = lit.chapters.length > 1 ? lit.chapters[1].title : 'The Heart of the Story';
    final ch3 = lit.chapters.length > 2 ? lit.chapters[2].title : 'The Final Reckoning';

    return BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ACT I: ${ch1.toUpperCase()}',
        subtitle: '${lit.title} • Opening Setting & Foundations',
        icon: Icons.menu_book_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ACT II: ${ch2.toUpperCase()}',
        subtitle: '${lit.author} • Rising Conflict & Discovery',
        icon: Icons.explore_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ACT III: ${ch3.toUpperCase()}',
        subtitle: '${lit.title} • Climax & Grand Mastery',
        icon: Icons.auto_awesome_rounded,
      ),
      apexTitle: 'CROWN OF ${lit.title.toUpperCase()}',
      apexSubtitle: 'Complete every trial to earn a Golden Key',
    );
  }

  static const Map<String, BookWorldSetting> _catalogZones = {
    'lit_secret_garden': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: MISSELTHWAITE MANOR',
        subtitle: 'Yorkshire • Silent Corridors & Locked Doors',
        icon: Icons.villa_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THE YORKSHIRE MOOR',
        subtitle: 'Windy Heath • The Robin & The Buried Key',
        icon: Icons.vpn_key_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: THE SECRET GARDEN',
        subtitle: 'Walled Bower • Roses Awakening in Spring',
        icon: Icons.local_florist_rounded,
      ),
      apexTitle: 'THE BLOOMING SANCTUARY',
      apexSubtitle: 'Master the Secret Garden to earn a Golden Key',
    ),
    'lit_wind_in_willows': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: THE RIVER BANK',
        subtitle: 'Willow Shade • Mole, Ratty & Messing About in Boats',
        icon: Icons.water_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THE WILD WOOD',
        subtitle: 'Deep Thicket • Badger’s Hearth & Winter Shadows',
        icon: Icons.forest_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: TOAD HALL',
        subtitle: 'Grand Estate • Motorcars & The Battle for Home',
        icon: Icons.castle_rounded,
      ),
      apexTitle: 'THE BANQUET OF TOAD HALL',
      apexSubtitle: 'Reclaim the riverbanks to earn a Golden Key',
    ),
    'lit_hope_feathers': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: THE AMHERST PARLOR',
        subtitle: 'Quiet Verse • Listening to the Song Without Words',
        icon: Icons.edit_note_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THE GALE & THE CHILLEST LAND',
        subtitle: 'Stormy Seas • Courage That Never Stops at All',
        icon: Icons.air_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: THE STRANGEST SEA',
        subtitle: 'Lyric Mastery • Imagery, Meter & Metaphor',
        icon: Icons.auto_awesome_rounded,
      ),
      apexTitle: 'PERCH OF THE SOUL',
      apexSubtitle: 'Master Dickinson’s lyric craft to earn a Golden Key',
    ),
    'lit_sonnet_18': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: THE SUMMER MEADOW',
        subtitle: 'Elizabethan Verse • Rough Winds & Darling Buds of May',
        icon: Icons.wb_sunny_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THE GLOBE STAGE',
        subtitle: 'Iambic Pentameter • Quatrains & The Poetic Volta',
        icon: Icons.theater_comedy_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: ETERNAL LINES OF TIME',
        subtitle: 'Immortal Couplet • Poetry Outliving the Sun',
        icon: Icons.history_edu_rounded,
      ),
      apexTitle: 'THE IMMORTAL FOLIO',
      apexSubtitle: 'Conquer Shakespeare’s sonnet to earn a Golden Key',
    ),
    'lit_don_quixote': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: PLAINS OF LA MANCHA',
        subtitle: 'Castile • The Rusting Armour & The Chivalric Calling',
        icon: Icons.shield_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: WINDMILLS OF MONTIEL',
        subtitle: 'Open Steppe • The Inn of Castles & Monstrous Giants',
        icon: Icons.wind_power_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: SIERRA MORENA',
        subtitle: 'Mountain Passes • Chivalric Trials & The Grand Exam',
        icon: Icons.fort_rounded,
      ),
      apexTitle: 'CITADEL OF LA MANCHA',
      apexSubtitle: 'Complete Don Quixote’s quest to earn a Golden Key',
    ),
    'lit_study_in_scarlet': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: 221B BAKER STREET',
        subtitle: 'Victorian London • Meeting Holmes & The Science of Deduction',
        icon: Icons.search_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: LAURISTON GARDENS',
        subtitle: 'Brixton Road • The Empty House & The Clue of RACHE',
        icon: Icons.fingerprint_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: SCOTLAND YARD',
        subtitle: 'Foggy Streets • Unmasking the Culprit & Case Closed',
        icon: Icons.gavel_rounded,
      ),
      apexTitle: 'THE BAKER STREET ARCHIVE',
      apexSubtitle: 'Solve the scarlet mystery to earn a Golden Key',
    ),
    'lit_around_the_world_80_days': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: THE REFORM CLUB & SUEZ',
        subtitle: 'London to Egypt • The Wager & The Steamer Mongolia',
        icon: Icons.directions_boat_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: BOMBAY & THE INDIAN JUNGLE',
        subtitle: 'Across India • Kiouni the Elephant & Calcutta',
        icon: Icons.train_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: THE PACIFIC & DATE LINE',
        subtitle: 'Yokohama to London • Racing Against the Clock',
        icon: Icons.public_rounded,
      ),
      apexTitle: 'THE 80TH DAY CLOCKTOWER',
      apexSubtitle: 'Finish the circumnavigation to earn a Golden Key',
    ),
    'lit_pride_and_prejudice': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: LONGBOURN & MERYTON',
        subtitle: 'Hertfordshire • The Bennet Parlor & Assembly Ball',
        icon: Icons.celebration_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: NETHERFIELD & ROSINGS',
        subtitle: 'Country Estates • First Impressions & Pride Unmasked',
        icon: Icons.account_balance_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: PEMBERLEY HALL',
        subtitle: 'Derbyshire • Letters, Reconciliation & Regency Wit',
        icon: Icons.favorite_rounded,
      ),
      apexTitle: 'THE GATES OF PEMBERLEY',
      apexSubtitle: 'Master Austen’s classic to earn a Golden Key',
    ),
    'lit_frankenstein': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: INGOLSTADT LABORATORY',
        subtitle: 'Bavaria • The Spark of Being & A Dreary Night',
        icon: Icons.bolt_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THE DE LACEY COTTAGE',
        subtitle: 'Swiss Alps • Solitude, Language & Rejection',
        icon: Icons.landscape_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: THE ARCTIC ICEFIELDS',
        subtitle: 'Frozen North • Captain Walton’s Ship & The Final Chase',
        icon: Icons.ac_unit_rounded,
      ),
      apexTitle: 'THE FROZEN HORIZON',
      apexSubtitle: 'Complete Shelley’s gothic tale to earn a Golden Key',
    ),
    'lit_dracula': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: BORGO PASS & CASTLE DRACULA',
        subtitle: 'Transylvania • Wolves of the Night & The Count’s Keep',
        icon: Icons.nights_stay_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: WHITBY ABBEY & THE DEMETER',
        subtitle: 'English Coast • The Ghost Ship & Midnight Shadows',
        icon: Icons.sailing_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: CARFAX & THE CARPATHIANS',
        subtitle: 'Van Helsing’s Hunt • Sunlight & The Final Pursuit',
        icon: Icons.flare_rounded,
      ),
      apexTitle: 'DAWN OVER TRANSYLVANIA',
      apexSubtitle: 'Vanquish the shadow to earn a Golden Key',
    ),
    'lit_dorian_gray': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: BASIL’S LONDON STUDIO',
        subtitle: 'Mayfair • The Scent of Lilacs & The Painted Portrait',
        icon: Icons.palette_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: WEST END SALONS & THEATRES',
        subtitle: 'Gilded Society • Lord Henry’s Epigrams & Sibyl Vane',
        icon: Icons.theater_comedy_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: THE LOCKED SCHOOLROOM',
        subtitle: 'Hidden Attic • The Unblemished Youth & The Canvas',
        icon: Icons.auto_fix_high_rounded,
      ),
      apexTitle: 'THE GILDED FRAME',
      apexSubtitle: 'Unravel Wilde’s masterpiece to earn a Golden Key',
    ),
    'lit_great_gatsby': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: WEST EGG & THE GREEN LIGHT',
        subtitle: 'Long Island • Nick’s Bungalow & Jazz-Age Galas',
        icon: Icons.wine_bar_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THE VALLEY OF ASHES',
        subtitle: 'Road to New York • The Eyes of Doctor T. J. Eckleburg',
        icon: Icons.visibility_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: THE PLAZA & EAST EGG',
        subtitle: 'Summer Climax • Dreams Against the Current',
        icon: Icons.light_mode_rounded,
      ),
      apexTitle: 'THE DOCK AT WEST EGG',
      apexSubtitle: 'Master the Jazz Age classic to earn a Golden Key',
    ),
    'lit_moby_dick': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: NEW BEDFORD & SPOUTER-INN',
        subtitle: 'Nantucket • Call Me Ishmael & Queequeg’s Bond',
        icon: Icons.anchor_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THE PEQUOD’S QUARTER-DECK',
        subtitle: 'Open Ocean • Captain Ahab & The Golden Doubloon',
        icon: Icons.sailing_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: THE PACIFIC CHASE',
        subtitle: 'Three Days at Sea • The White Whale Rises',
        icon: Icons.waves_rounded,
      ),
      apexTitle: 'THE MARINER’S COMPASS',
      apexSubtitle: 'Survive the voyage of the Pequod to earn a Golden Key',
    ),
    'lit_treasure_island': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: ADMIRAL BENBOW INN',
        subtitle: 'Bristol Coast • Billy Bones & Captain Flint’s Map',
        icon: Icons.map_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: ABOARD THE HISPANIOLA',
        subtitle: 'High Seas • Long John Silver & The Apple Barrel',
        icon: Icons.sailing_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: SPYGLASS HILL & STOCKADE',
        subtitle: 'Skeleton Island • Ben Gunn & The Buried Gold',
        icon: Icons.diamond_rounded,
      ),
      apexTitle: 'CAPTAIN FLINT’S TREASURE',
      apexSubtitle: 'Claim the island’s secrets to earn a Golden Key',
    ),
    'lit_jekyll_hyde': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: THE DOOR IN THE BY-STREET',
        subtitle: 'Soho Fog • Utterson’s Walk & The Sinister Will',
        icon: Icons.door_front_door_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: CAVENDISH SQUARE & SOHO',
        subtitle: 'Gaslit London • Dr. Lanyon’s Shock & Midnight Steps',
        icon: Icons.science_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: THE CABINET LABORATORY',
        subtitle: 'Dual Nature • Henry Jekyll’s Full Statement',
        icon: Icons.contrast_rounded,
      ),
      apexTitle: 'THE SEALED CONFESSION',
      apexSubtitle: 'Uncover the dual identity to earn a Golden Key',
    ),
    'lit_monte_cristo': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: HARBOR OF MARSEILLE',
        subtitle: 'The Pharaon • Edmond Dantès & The Betrayal',
        icon: Icons.anchor_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: CHÂTEAU D’IF',
        subtitle: 'Island Prison • Abbé Faria & The Escape to Sea',
        icon: Icons.fort_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: ISLE OF MONTE CRISTO & PARIS',
        subtitle: 'Spada’s Hoard • Wait and Hope',
        icon: Icons.diamond_rounded,
      ),
      apexTitle: 'THE GROTTO OF MONTE CRISTO',
      apexSubtitle: 'Master Dumas’s epic of justice to earn a Golden Key',
    ),
    'lit_three_musketeers': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: MEUNG & PARIS COURTYARDS',
        subtitle: '1625 France • D’Artagnan Meets Athos, Porthos & Aramis',
        icon: Icons.shield_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THE ROAD TO CALAIS',
        subtitle: 'The Queen’s Diamonds • Outriding Richelieu’s Guards',
        icon: Icons.directions_run_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: SIEGE OF LA ROCHELLE',
        subtitle: 'All for One • The Bastion Saint-Gervais',
        icon: Icons.fort_rounded,
      ),
      apexTitle: 'THE KING’S MUSKETEER CREST',
      apexSubtitle: 'Earn your musketeer’s cassock and a Golden Key',
    ),
    'lit_les_miserables': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: DIGNE & MONTREUIL-SUR-MER',
        subtitle: 'Silver Candlesticks • Jean Valjean’s Redemption',
        icon: Icons.candlestick_chart_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: MONTFERMEIL & RUE PLUMET',
        subtitle: 'Cosette’s Rescue • Shadows of Inspector Javert',
        icon: Icons.park_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: THE PARIS BARRICADES',
        subtitle: 'June Rebellion • Mercy, Justice & Grace',
        icon: Icons.account_balance_rounded,
      ),
      apexTitle: 'THE SILVER CANDLESTICKS',
      apexSubtitle: 'Complete Hugo’s epic to earn a Golden Key',
    ),
    'lit_crime_punishment': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: HAYMARKET GARRET',
        subtitle: 'St. Petersburg • Raskolnikov’s Narrow Room & Theory',
        icon: Icons.apartment_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THE POLICE BUREAU',
        subtitle: 'Porfiry Petrovich • Fever, Guilt & Cat-and-Mouse',
        icon: Icons.psychology_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: SENNAYA SQUARE & SIBERIA',
        subtitle: 'Sonia’s Compassion • Confession & Renewal',
        icon: Icons.wb_twilight_rounded,
      ),
      apexTitle: 'DAWN OVER THE NEVA',
      apexSubtitle: 'Master Dostoevsky’s masterwork to earn a Golden Key',
    ),
    'lit_wuthering_heights': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: WUTHERING HEIGHTS',
        subtitle: 'Stormy Farmhouse • Lockwood’s Snowbound Visit',
        icon: Icons.thunderstorm_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THRUSHCROSS GRANGE',
        subtitle: 'Valley Estate • Catherine, Heathcliff & Nelly’s Tale',
        icon: Icons.villa_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: PENISTONE CRAGS',
        subtitle: 'Wind-Swept Moors • Passion Across Generations',
        icon: Icons.terrain_rounded,
      ),
      apexTitle: 'THE QUIET MOORLAND',
      apexSubtitle: 'Conquer Brontë’s tempest to earn a Golden Key',
    ),
    'lit_jane_eyre': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: GATESHEAD & LOWOOD SCHOOL',
        subtitle: 'Early Resilience • The Red Room & Helen Burns',
        icon: Icons.school_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THORNFIELD HALL',
        subtitle: 'Battlemented Manor • Mr. Rochester & The Third Story',
        icon: Icons.castle_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: MOOR HOUSE & FERNDEAN',
        subtitle: 'Independence • Choosing One’s Own Path',
        icon: Icons.forest_rounded,
      ),
      apexTitle: 'THE HEARTH OF FERNDEAN',
      apexSubtitle: 'Complete Jane’s journey to earn a Golden Key',
    ),
    'lit_two_cities': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: DOVER MAIL & TELLSON’S BANK',
        subtitle: 'London 1775 • Recalled to Life',
        icon: Icons.account_balance_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: SAINT ANTOINE & SOHO',
        subtitle: 'Echoing Footsteps • Madame Defarge’s Knitting',
        icon: Icons.location_city_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: THE BASTILLE & CONCIERGERIE',
        subtitle: 'Paris 1793 • A Far, Far Better Thing',
        icon: Icons.flare_rounded,
      ),
      apexTitle: 'THE BRIDGE BETWEEN CITIES',
      apexSubtitle: 'Master Dickens’s twin-city epic to earn a Golden Key',
    ),
    'lit_great_expectations': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: THE KENT MARSHES & FORGE',
        subtitle: 'Misty Churchyard • Pip, Joe Gargery & The Convict',
        icon: Icons.water_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: SATIS HOUSE',
        subtitle: 'Stopped Clocks • Miss Havisham & Estella',
        icon: Icons.hourglass_disabled_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: BARNARD’S INN & THE THAMES',
        subtitle: 'London Gentleman • True Worth Revealed',
        icon: Icons.location_city_rounded,
      ),
      apexTitle: 'THE GARDEN OF SATIS HOUSE',
      apexSubtitle: 'Complete Pip’s coming-of-age to earn a Golden Key',
    ),
    'lit_odyssey': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: OGYGIA & PHAEACIA',
        subtitle: 'Aegean Sea • Calypso’s Isle & Nausicaa’s Shore',
        icon: Icons.sailing_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: CYCLOPS, CIRCE & THE SIRENS',
        subtitle: 'Wine-Dark Sea • Cunning Against Monsters',
        icon: Icons.waves_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: THE HALLS OF ITHACA',
        subtitle: 'Homecoming • The Great Bow & Penelope’s Loom',
        icon: Icons.account_balance_rounded,
      ),
      apexTitle: 'THE OLIVE TREE OF ITHACA',
      apexSubtitle: 'Bring Odysseus home to earn a Golden Key',
    ),
    'lit_iliad': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: THE ACHAEAN SHIPS',
        subtitle: 'Trojan Shore • The Wrath of Achilles',
        icon: Icons.sailing_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THE PLAINS OF SCAMANDER',
        subtitle: 'Bronze & Valor • Hector of the Shining Helm',
        icon: Icons.shield_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: THE SCAEAN GATES OF TROY',
        subtitle: 'High Walls • Priam’s Plea & Heroic Honor',
        icon: Icons.fort_rounded,
      ),
      apexTitle: 'THE CITADEL OF ILIUM',
      apexSubtitle: 'Conquer Homer’s epic to earn a Golden Key',
    ),
    'lit_meditations': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: THE DANUBE FRONTIER CAMP',
        subtitle: 'Carnuntum • Evening Reflections of an Emperor',
        icon: Icons.nights_stay_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THE INNER CITADEL',
        subtitle: 'Stoic Discipline • Controlling Only What Is Yours',
        icon: Icons.self_improvement_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: THE COSMOPOLIS OF REASON',
        subtitle: 'Roman Virtue • Duty, Calm & Mortality',
        icon: Icons.account_balance_rounded,
      ),
      apexTitle: 'THE STOIC SANCTUARY',
      apexSubtitle: 'Master Marcus Aurelius’s wisdom to earn a Golden Key',
    ),
    'lit_art_of_war': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: THE WAR COUNCIL PAVILION',
        subtitle: 'Laying Plans • Measuring the Five Constant Factors',
        icon: Icons.map_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THE HIGH GROUND & PASSES',
        subtitle: 'Tactical Terrain • Winning Without Fighting',
        icon: Icons.terrain_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: THE NINE GROUNDS',
        subtitle: 'Grand Strategy • Speed, Adaptation & Mastery',
        icon: Icons.military_tech_rounded,
      ),
      apexTitle: 'THE STRATEGIST’S PAVILION',
      apexSubtitle: 'Master Sun Tzu’s treatise to earn a Golden Key',
    ),
    'lit_the_prince': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: PALAZZO VECCHIO',
        subtitle: 'Renaissance Florence • Principalities & Governance',
        icon: Icons.account_balance_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THE CITADELS OF ITALY',
        subtitle: 'Fortuna & Virtù • The Lion and the Fox',
        icon: Icons.fort_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: THE COUNCIL CHAMBER',
        subtitle: 'Statecraft • Counsel, Reputation & Leadership',
        icon: Icons.gavel_rounded,
      ),
      apexTitle: 'THE FLORENTINE SIGNORIA',
      apexSubtitle: 'Master Machiavelli’s treatise to earn a Golden Key',
    ),
    'lit_the_prophet': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: THE HILLS OF ORPHALESE',
        subtitle: 'Twelve Years Waiting • The Ship Appears in the Mist',
        icon: Icons.sailing_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THE TEMPLE SQUARE',
        subtitle: 'Almustafa Speaks • On Love, Work, Joy & Sorrow',
        icon: Icons.temple_buddhist_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: THE HARBOR AT TWILIGHT',
        subtitle: 'Farewell Discourse • Returning to the Isle of Birth',
        icon: Icons.wb_twilight_rounded,
      ),
      apexTitle: 'THE HARBOR OF ORPHALESE',
      apexSubtitle: 'Complete Gibran’s reflections to earn a Golden Key',
    ),
    'lit_metamorphosis': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: GREGOR’S LOCKED BEDROOM',
        subtitle: 'Prague Morning • Uneasy Dreams & The Awakening',
        icon: Icons.door_front_door_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THE SAMSA LIVING ROOM',
        subtitle: 'Behind the Door • The Chief Clerk & Family Strain',
        icon: Icons.chair_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: THE VIOLIN IN THE PARLOR',
        subtitle: 'The Lodgers • Alienation & The Final Dawn',
        icon: Icons.music_note_rounded,
      ),
      apexTitle: 'THE PRAGUE WINDOW',
      apexSubtitle: 'Master Kafka’s novella to earn a Golden Key',
    ),
    'lit_call_of_the_wild': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: SANTA CLARA TO DYEA BEACH',
        subtitle: 'Gold Rush 1897 • Buck Learns the Law of Club and Fang',
        icon: Icons.ac_unit_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THE YUKON MAIL TRAIL',
        subtitle: 'Frozen Rivers • Leading the Pack Across Dawson',
        icon: Icons.pets_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: JOHN THORNTON’S CAMP',
        subtitle: 'Deep Wilderness • Answering the Primordial Call',
        icon: Icons.forest_rounded,
      ),
      apexTitle: 'THE YUKON TIMBERLINE',
      apexSubtitle: 'Answer the Call of the Wild to earn a Golden Key',
    ),
    'lit_tom_sawyer': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: ST. PETERSBURG & THE FENCE',
        subtitle: 'Missouri River • Whitewashing & Aunt Polly’s Yard',
        icon: Icons.fence_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: JACKSON’S ISLAND',
        subtitle: 'Mississippi Sandbar • Pirates of the River',
        icon: Icons.water_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: MCDOUGAL’S CAVE',
        subtitle: 'Lantern Shadows • Becky Thatcher & Hidden Gold',
        icon: Icons.terrain_rounded,
      ),
      apexTitle: 'CARDIFF HILL OVERLOOK',
      apexSubtitle: 'Finish Tom’s adventures to earn a Golden Key',
    ),
    'lit_huck_finn': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: HANNIBAL & JACKSON’S ISLAND',
        subtitle: 'Night Escape • Huck and Jim Set Off Downriver',
        icon: Icons.water_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THE RAFT ON THE MISSISSIPPI',
        subtitle: 'Starlit Current • Fog, Steamboats & Conscience',
        icon: Icons.sailing_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: THE PHELPS PLANTATION',
        subtitle: 'Lighting Out for the Territory • Freedom Won',
        icon: Icons.wb_sunny_rounded,
      ),
      apexTitle: 'THE GREAT RIVER BEND',
      apexSubtitle: 'Complete the river voyage to earn a Golden Key',
    ),
    'lit_jungle_book': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: COUNCIL ROCK OF SEEONEE',
        subtitle: 'Indian Jungle • Mowgli, Baloo & Bagheera',
        icon: Icons.pets_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THE COLD LAIRS',
        subtitle: 'Ruined City • Kaa’s Hunting & The Bandar-log',
        icon: Icons.temple_hindu_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: THE WAINGUNGA RAVINE',
        subtitle: 'The Red Flower • Facing Shere Khan',
        icon: Icons.local_fire_department_rounded,
      ),
      apexTitle: 'SUMMIT OF COUNCIL ROCK',
      apexSubtitle: 'Master the Law of the Jungle to earn a Golden Key',
    ),
    'lit_peter_pan': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: THE DARLING NURSERY',
        subtitle: 'Bloomsbury • Second to the Right & Straight On Till Morning',
        icon: Icons.nights_stay_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: NEVERLAND & MERMAIDS’ LAGOON',
        subtitle: 'Lost Boys’ Hideout • Tinker Bell & Fairy Dust',
        icon: Icons.auto_awesome_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: THE JOLLY ROGER',
        subtitle: 'Captain Hook’s Deck • The Ticking Crocodile',
        icon: Icons.sailing_rounded,
      ),
      apexTitle: 'THE STAR OF NEVERLAND',
      apexSubtitle: 'Conquer Neverland to earn a Golden Key',
    ),
    'lit_little_women': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: ORCHARD HOUSE PARLOR',
        subtitle: 'Concord, Massachusetts • Meg, Jo, Beth & Amy',
        icon: Icons.home_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THE LAURENCE MANSION',
        subtitle: 'Next Door • Laurie, The Pickwick Club & Plays',
        icon: Icons.menu_book_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: PLUMFIELD & THE GARRET',
        subtitle: 'Coming of Age • Stories Written & Dreams Kept',
        icon: Icons.favorite_rounded,
      ),
      apexTitle: 'THE HEARTH OF ORCHARD HOUSE',
      apexSubtitle: 'Complete the March sisters’ story to earn a Golden Key',
    ),
    'lit_gulliver': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: SHORES OF LILLIPUT',
        subtitle: 'Shipwrecked • Six-Inch Citizens & Imperial Politics',
        icon: Icons.sailing_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: BROBDINGNAG & LAPUTA',
        subtitle: 'Giants & Floating Islands • Satire of Pride',
        icon: Icons.cloud_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: LAND OF THE HOUYHNHNMS',
        subtitle: 'Reason & Humanity • Gulliver’s Return Home',
        icon: Icons.explore_rounded,
      ),
      apexTitle: 'THE VOYAGER’S ATLAS',
      apexSubtitle: 'Finish all four voyages to earn a Golden Key',
    ),
    'lit_robinson_crusoe': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: THE SHIPWRECKED COVE',
        subtitle: 'Despair Island • Salvaging Timber & Building Shelter',
        icon: Icons.beach_access_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THE ISLAND FORT & VALLEY',
        subtitle: 'Years of Ingenuity • Crops, Goats & The Footprint',
        icon: Icons.park_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: FRIDAY’S SHORE & RESCUE',
        subtitle: 'Companionship • Sails on the Distant Horizon',
        icon: Icons.sailing_rounded,
      ),
      apexTitle: 'THE ISLAND BEACON',
      apexSubtitle: 'Survive and master Crusoe’s tale to earn a Golden Key',
    ),
    'lit_heart_of_darkness': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: THE NELLIE ON THE THAMES',
        subtitle: 'London Dusk • Marlow Begins His River Tale',
        icon: Icons.water_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THE CENTRAL STATION',
        subtitle: 'Upriver Steamboat • Dense Fog & Broken Rivets',
        icon: Icons.forest_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: THE INNER STATION',
        subtitle: 'Mr. Kurtz • Echoes in the Deep Jungle',
        icon: Icons.visibility_rounded,
      ),
      apexTitle: 'THE MISTY ESTUARY',
      apexSubtitle: 'Complete Conrad’s novella to earn a Golden Key',
    ),
    'lit_war_of_worlds': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: HORSELL COMMON',
        subtitle: 'Surrey • The Falling Cylinder & The Heat-Ray',
        icon: Icons.flare_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THE THAMES & WEYBRIDGE',
        subtitle: 'Fighting-Machines • Thunder Child at Sea',
        icon: Icons.bolt_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: SILENT LONDON',
        subtitle: 'Red Weed • The Humble Triumph of Earth',
        icon: Icons.public_rounded,
      ),
      apexTitle: 'PRIMROSE HILL OBSERVATORY',
      apexSubtitle: 'Survive the Martian invasion to earn a Golden Key',
    ),
    'lit_republic': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: THE PIRAEUS DIALOGUE',
        subtitle: 'Athens • Socrates Questions What Justice Means',
        icon: Icons.account_balance_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THE ALLEGORY OF THE CAVE',
        subtitle: 'Shadows & Firelight • Ascending Toward Truth',
        icon: Icons.wb_sunny_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: THE PHILOSOPHER’S CITY',
        subtitle: 'Kallipolis • Harmony of the Soul & State',
        icon: Icons.auto_awesome_rounded,
      ),
      apexTitle: 'THE ACADEMY OF ATHENS',
      apexSubtitle: 'Master Plato’s dialogue to earn a Golden Key',
    ),
    'lit_walden': BookWorldSetting(
      zone1: BookZoneMeta(
        title: 'ZONE I: THE PINE-WOOD CABIN',
        subtitle: 'Concord Woods • Living Deliberately by the Pond',
        icon: Icons.cabin_rounded,
      ),
      zone2: BookZoneMeta(
        title: 'ZONE II: THE BEAN-FIELD & SHORE',
        subtitle: 'Solitude & Sounds • Simplicity in Nature',
        icon: Icons.forest_rounded,
      ),
      zone3: BookZoneMeta(
        title: 'ZONE III: SPRING THAW AT WALDEN',
        subtitle: 'Deep Ice Melting • Awakening of the Earth',
        icon: Icons.water_drop_rounded,
      ),
      apexTitle: 'WALDEN POND OVERLOOK',
      apexSubtitle: 'Complete Thoreau’s reflections to earn a Golden Key',
    ),
  };
}
