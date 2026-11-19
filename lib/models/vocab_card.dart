/// A single word in the reader's personal Word Bank, scheduled with a
/// Leitner-style spaced-repetition system.
///
/// Box 0 = brand new / just missed (due immediately), box 5 = mastered.
/// Each correct review moves the card up one box and pushes the next review
/// further into the future; a miss drops it back to box 0.
class VocabCard {
  final String word;
  final String definition;
  final String example;
  final String literatureId;
  final String literatureTitle;
  int box;
  DateTime dueAt;
  int timesCorrect;
  int timesWrong;
  final DateTime addedAt;

  /// Days until the next review for each box.
  static const List<int> intervalDays = [0, 1, 3, 7, 16, 35];
  static const int masteredBox = 5;

  VocabCard({
    required this.word,
    required this.definition,
    this.example = '',
    required this.literatureId,
    required this.literatureTitle,
    this.box = 0,
    DateTime? dueAt,
    this.timesCorrect = 0,
    this.timesWrong = 0,
    DateTime? addedAt,
  })  : dueAt = dueAt ?? DateTime.now(),
        addedAt = addedAt ?? DateTime.now();

  String get key => word.trim().toLowerCase();

  bool get isMastered => box >= masteredBox;

  bool isDue([DateTime? now]) => !dueAt.isAfter(now ?? DateTime.now());

  /// 0.0 - 1.0 mastery used for progress bars.
  double get mastery => (box / masteredBox).clamp(0.0, 1.0);

  String get strengthLabel {
    if (box <= 0) return 'New';
    if (box == 1) return 'Learning';
    if (box == 2) return 'Familiar';
    if (box == 3) return 'Strong';
    if (box == 4) return 'Nearly mastered';
    return 'Mastered';
  }

  void markCorrect([DateTime? now]) {
    final t = now ?? DateTime.now();
    timesCorrect++;
    box = (box + 1).clamp(0, masteredBox);
    dueAt = _startOfDay(t).add(Duration(days: intervalDays[box]));
  }

  void markWrong([DateTime? now]) {
    timesWrong++;
    box = 0;
    dueAt = now ?? DateTime.now();
  }

  static DateTime _startOfDay(DateTime t) => DateTime(t.year, t.month, t.day);

  Map<String, dynamic> toJson() => {
        'word': word,
        'definition': definition,
        'example': example,
        'literatureId': literatureId,
        'literatureTitle': literatureTitle,
        'box': box,
        'dueAt': dueAt.toIso8601String(),
        'timesCorrect': timesCorrect,
        'timesWrong': timesWrong,
        'addedAt': addedAt.toIso8601String(),
      };

  factory VocabCard.fromJson(Map<String, dynamic> j) => VocabCard(
        word: j['word'] as String,
        definition: j['definition'] as String,
        example: (j['example'] as String?) ?? '',
        literatureId: (j['literatureId'] as String?) ?? '',
        literatureTitle: (j['literatureTitle'] as String?) ?? '',
        box: (j['box'] as num?)?.toInt() ?? 0,
        dueAt: DateTime.tryParse(j['dueAt'] as String? ?? ''),
        timesCorrect: (j['timesCorrect'] as num?)?.toInt() ?? 0,
        timesWrong: (j['timesWrong'] as num?)?.toInt() ?? 0,
        addedAt: DateTime.tryParse(j['addedAt'] as String? ?? ''),
      );
}
