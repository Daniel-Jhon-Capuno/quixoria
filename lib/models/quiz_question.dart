enum QuizType {
  multipleChoice,
  cloze,       // Fill in the blank with interactive word bank
  reorder,     // Tap word chips in sequence to assemble a famous quote
  matching,    // Tap-to-match vocabulary/character pairs
  roleplay,    // In-character literary dialogue & moral dilemma
}

class QuizQuestion {
  final String id;
  final String prompt;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;
  final QuizType type;

  // Cloze (Fill-in-the-blank)
  final String? clozeSentence;
  final String? targetWord;
  final List<String>? wordBank;

  // Sentence / Quote Ordering
  final List<String>? orderedTokens;

  // Matching Pairs (e.g. archaic word -> definition or character -> role)
  final Map<String, String>? matchingPairs;

  // Roleplay / Dialogue context
  final String? characterSpeaker;
  final String? contextHint;

  const QuizQuestion({
    required this.id,
    required this.prompt,
    this.options = const [],
    this.correctAnswerIndex = 0,
    required this.explanation,
    this.type = QuizType.multipleChoice,
    this.clozeSentence,
    this.targetWord,
    this.wordBank,
    this.orderedTokens,
    this.matchingPairs,
    this.characterSpeaker,
    this.contextHint,
  });
}
