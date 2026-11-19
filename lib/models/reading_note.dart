enum NoteType {
  reflection,
  quote,
  question,
  vocabulary,
}

extension NoteTypeExtension on NoteType {
  String get label {
    switch (this) {
      case NoteType.reflection:
        return 'Reflection';
      case NoteType.quote:
        return 'Quote';
      case NoteType.question:
        return 'Question';
      case NoteType.vocabulary:
        return 'Vocabulary';
    }
  }
}

class ReadingNote {
  final String id;
  final String literatureId;
  final String literatureTitle;
  final String chapterTitle;
  final NoteType type;
  String title;
  String content;
  final DateTime createdAt;

  ReadingNote({
    required this.id,
    required this.literatureId,
    required this.literatureTitle,
    required this.chapterTitle,
    required this.type,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  ReadingNote copyWith({
    String? title,
    String? content,
    NoteType? type,
  }) {
    return ReadingNote(
      id: id,
      literatureId: literatureId,
      literatureTitle: literatureTitle,
      chapterTitle: chapterTitle,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'literatureId': literatureId,
        'literatureTitle': literatureTitle,
        'chapterTitle': chapterTitle,
        'type': type.name,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ReadingNote.fromJson(Map<String, dynamic> j) => ReadingNote(
        id: (j['id'] as String?) ?? 'note_${DateTime.now().millisecondsSinceEpoch}',
        literatureId: (j['literatureId'] as String?) ?? 'lit_secret_garden',
        literatureTitle: (j['literatureTitle'] as String?) ?? 'The Secret Garden',
        chapterTitle: (j['chapterTitle'] as String?) ?? 'Chapter 1',
        type: NoteType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => NoteType.reflection,
        ),
        title: (j['title'] as String?) ?? '',
        content: (j['content'] as String?) ?? '',
        createdAt: DateTime.tryParse((j['createdAt'] as String?) ?? '') ?? DateTime.now(),
      );
}
