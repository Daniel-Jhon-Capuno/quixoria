class QuoteCard {
  final String id;
  final String quoteText;
  final String literatureId;
  final String literatureTitle;
  final String author;
  final String chapterTitle;
  final String styleKey; // 'parchment', 'sakura', 'midnight', 'frost', 'savannah', 'emerald'
  final DateTime createdAt;

  const QuoteCard({
    required this.id,
    required this.quoteText,
    required this.literatureId,
    required this.literatureTitle,
    required this.author,
    required this.chapterTitle,
    this.styleKey = 'parchment',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'quoteText': quoteText,
        'literatureId': literatureId,
        'literatureTitle': literatureTitle,
        'author': author,
        'chapterTitle': chapterTitle,
        'styleKey': styleKey,
        'createdAt': createdAt.toIso8601String(),
      };

  factory QuoteCard.fromJson(Map<String, dynamic> j) => QuoteCard(
        id: (j['id'] as String?) ?? 'quote_${DateTime.now().millisecondsSinceEpoch}',
        quoteText: (j['quoteText'] as String?) ?? '',
        literatureId: (j['literatureId'] as String?) ?? 'lit_secret_garden',
        literatureTitle: (j['literatureTitle'] as String?) ?? 'The Secret Garden',
        author: (j['author'] as String?) ?? 'Classic Author',
        chapterTitle: (j['chapterTitle'] as String?) ?? 'Chapter 1',
        styleKey: (j['styleKey'] as String?) ?? 'parchment',
        createdAt: DateTime.tryParse((j['createdAt'] as String?) ?? '') ?? DateTime.now(),
      );
}
