import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GeminiCounselResult {
  final String text;
  final bool isAiPowered;
  final String? model;

  const GeminiCounselResult({
    required this.text,
    required this.isAiPowered,
    this.model,
  });
}

/// Socratic reading companion powered by Google Gemini (gemini-3.8-flash).
///
/// Embodies Don Quixote de la Mancha as a friendly, chivalric reading mentor
/// for children and students. Answers questions about any passage in simple,
/// clear, inspiring language. Falls back to Don Quixote's storybook companion
/// when offline or without an API key.
class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  static const String _defaultModel = 'gemini-3.8-flash';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  /// Verifies whether an API key is valid.
  Future<bool> validateApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) return false;

    try {
      final uri = Uri.parse('$_baseUrl/$_defaultModel:generateContent?key=$trimmed');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Ping'}
              ]
            }
          ],
          'generationConfig': {'maxOutputTokens': 5},
        }),
      ).timeout(const Duration(seconds: 8));

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('GeminiService.validateApiKey error: $e');
      return false;
    }
  }

  /// Consults Don Quixote on a passage with an optional reader query.
  Future<GeminiCounselResult> consultDonQuixote({
    required String passage,
    required String bookTitle,
    String? userQuestion,
    String? apiKey,
    bool isOnline = true,
  }) async {
    final key = apiKey?.trim() ?? '';

    // If online and API key is provided, query Gemini 3.8 Flash
    if (isOnline && key.isNotEmpty) {
      try {
        final studentQuestion = userQuestion?.trim().isNotEmpty == true
            ? userQuestion!.trim()
            : 'What does this passage mean in simple words?';

        final uri = Uri.parse('$_baseUrl/$_defaultModel:generateContent?key=$key');
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'system_instruction': {
              'parts': [
                {
                  'text': 'Thou art Don Quixote de la Mancha, a chivalric and warm reading friend helping young students and kids understand classical literature. '
                      'The student is reading "$bookTitle".\n'
                      'Passage: "$passage".\n\n'
                      'Rules for thy reply:\n'
                      '1. Answer their specific question directly in simple, clear words a young reader can easily understand.\n'
                      '2. Speak like Don Quixote with gentle warmth and chivalric flair ("Noble friend!", "By my lance!"), but keep the explanation simple, encouraging, and clear.\n'
                      '3. Keep thy response short: 2 to 3 sentences maximum.\n'
                      '4. Never say you are an AI or language model.'
                }
              ]
            },
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': 'Question: $studentQuestion'}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': 300,
            },
          }),
        ).timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = data['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List<dynamic>?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String?;
              if (text != null && text.trim().isNotEmpty) {
                return GeminiCounselResult(
                  text: text.trim(),
                  isAiPowered: true,
                  model: _defaultModel,
                );
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('GeminiService online call error, falling back: $e');
      }
    }

    // Friendly local companion fallback
    return GeminiCounselResult(
      text: _generateKidFriendlyCounsel(bookTitle: bookTitle, passage: passage, question: userQuestion),
      isAiPowered: false,
    );
  }

  /// Evaluates a reader's note or reflection.
  Future<GeminiCounselResult> evaluateReaderReflection({
    required String passage,
    required String userReflection,
    required String bookTitle,
    String? apiKey,
    bool isOnline = true,
  }) async {
    final key = apiKey?.trim() ?? '';

    if (isOnline && key.isNotEmpty) {
      try {
        final uri = Uri.parse('$_baseUrl/$_defaultModel:generateContent?key=$key');
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'system_instruction': {
              'parts': [
                {
                  'text': 'Thou art Don Quixote de la Mancha. A young student reading "$bookTitle" wrote this note about a passage: "$userReflection". '
                      'Commend their insight warmly and encourage them in 2 simple, uplifting sentences.'
                }
              ]
            },
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': 'Passage: "$passage"\nStudent Note: "$userReflection"'}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': 200,
            },
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = data['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List<dynamic>?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String?;
              if (text != null && text.trim().isNotEmpty) {
                return GeminiCounselResult(
                  text: text.trim(),
                  isAiPowered: true,
                  model: _defaultModel,
                );
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('GeminiService reflection eval error: $e');
      }
    }

    return GeminiCounselResult(
      text: '“By the helmet of Mambrino, thy quill strikes true! In perceiving "$userReflection", thou peerest beneath the words into the beating heart of "$bookTitle". Press forward, scholar!”',
      isAiPowered: false,
    );
  }

  /// Intelligent, context-aware, kid-friendly Don Quixote companion.
  String _generateKidFriendlyCounsel({
    required String bookTitle,
    required String passage,
    String? question,
  }) {
    final q = question?.toLowerCase().trim() ?? '';
    final pLower = passage.toLowerCase();
    final bLower = bookTitle.toLowerCase();

    // 1. Tricky Words check
    if (q.contains('tricky') || q.contains('hard word') || q.contains('vocab') || q.contains('phrase') || q.contains('archaic')) {
      final foundWords = <String>[];
      if (pLower.contains('perceive')) foundWords.add('• **Perceive**: To notice or figure something out using your sharp eyes and mind.');
      if (pLower.contains('deduction')) foundWords.add('• **Deduction**: Solving a puzzle by putting small clues together.');
      if (pLower.contains('afghanistan')) foundWords.add('• **Afghanistan**: A country far across the sea where Watson had been serving as an army doctor.');
      if (pLower.contains('ayah')) foundWords.add('• **Ayah**: A native nursemaid or nanny who took care of children in India.');
      if (pLower.contains('tyrannical')) foundWords.add('• **Tyrannical**: Bossy, strict, and demanding that everyone obey without question.');
      if (pLower.contains('cholera')) foundWords.add('• **Cholera**: A sudden, dangerous illness from dirty water that spread quickly.');
      if (pLower.contains('compound')) foundWords.add('• **Compound**: A walled yard with several bungalows and houses inside.');
      if (pLower.contains('hidalgo')) foundWords.add('• **Hidalgo**: An honorable Spanish gentleman or knight.');
      if (pLower.contains('buckler')) foundWords.add('• **Buckler**: A small round shield held in the hand to block sword strikes.');
      if (pLower.contains('hack')) foundWords.add('• **Hack**: An ordinary, tired old horse—just like my faithful Rocinante before our glory!');
      if (pLower.contains('ineffable')) foundWords.add('• **Ineffable**: Something so wondrous, beautiful, or deep that words cannot describe it.');
      if (pLower.contains('fastidious')) foundWords.add('• **Fastidious**: Being very neat, orderly, and careful about every tiny detail.');
      if (pLower.contains('melancholy')) foundWords.add('• **Melancholy**: A deep, thoughtful sadness or gloomy mood.');
      if (pLower.contains('solitary')) foundWords.add('• **Solitary**: Existing alone, quiet and secluded from the crowded world.');
      if (pLower.contains('chivalry')) foundWords.add('• **Chivalry**: The noble knight’s code of honor, courage, courtesy, and protecting others.');
      if (pLower.contains('countenance')) foundWords.add('• **Countenance**: A person’s face or facial expression that reveals their inner feelings.');
      if (pLower.contains('astonishment')) foundWords.add('• **Astonishment**: Great surprise or complete wonder.');
      if (pLower.contains('sagacity')) foundWords.add('• **Sagacity**: Wise understanding and good judgment built over time.');
      if (pLower.contains('resolution')) foundWords.add('• **Resolution**: A firm and unbreakable decision to accomplish a goal.');
      if (pLower.contains('tranquility')) foundWords.add('• **Tranquility**: A state of peaceful calm and quiet serenity.');
      if (pLower.contains('perseverance')) foundWords.add('• **Perseverance**: Refusing to give up, even when the mountain seems too steep to climb.');

      if (foundWords.isNotEmpty) {
        return '“Hearken, young reader! Here are the tricky words in this passage:\n\n${foundWords.join('\n')}\n\nMastering these words makes thy vocabulary as sharp as a knight\'s lance!”';
      } else {
        // Dynamically find 2-3 longest vocabulary words from the actual passage
        final cleanedTokens = passage
            .replaceAll(RegExp(r'[^a-zA-Z\s]'), ' ')
            .split(RegExp(r'\s+'))
            .where((w) => w.length >= 7)
            .map((w) => w.toLowerCase())
            .toSet()
            .take(3)
            .toList();

        if (cleanedTokens.isNotEmpty) {
          final wordsFormatted = cleanedTokens.map((w) => '• **${w[0].toUpperCase()}${w.substring(1)}**: A literary word expressing deep emotion and setting in this scene.').join('\n');
          return '“Hearken, noble student! In this passage from "$bookTitle", look closely at these key words:\n\n$wordsFormatted\n\nNotice how the author weaves them together to set the atmosphere. Add them to thy Word Bank in the Scriptorium!”';
        }

        return '“In this part of "$bookTitle", the author writes with vintage elegance! Notice how every sentence paints an atmosphere. Keep thy reading dictionary close, and never fear a long word—it is merely an adventure waiting to be unlocked!”';
      }
    }

    // 2. What would Don Quixote do?
    if (q.contains('quixote do') || q.contains('would you do') || q.contains('sword') || q.contains('lance')) {
      return '“By my steed Rocinante! If I stood in this scene, I would raise my shield, pledge my honor to defend truth, and declare to all that courage conquers fear! A true knight never hesitates to do what is right, no matter how great the challenge!”';
    }

    // 3. What happens next?
    if (q.contains('next') || q.contains('future') || q.contains('later')) {
      return '“Ah, the thrill of the unfolding quest! If thou readest just a little further, the choices made in this very moment will trigger surprising revelations for our heroes. Turn the page with courage, noble friend!”';
    }

    // 4. Meaning & Specific Book Explanations ("What does this mean?")
    if (bLower.contains('scarlet') || pLower.contains('afghanistan') || pLower.contains('holmes') || pLower.contains('watson')) {
      return '“Sherlock Holmes deduced right away that Dr. Watson had just returned from war in Afghanistan! He noticed Watson\'s sunburned skin, his thin and tired face, and how stiffly he held his injured arm. It shows that observing small details can reveal big truths without asking a single question!”';
    }

    if (bLower.contains('secret garden') || pLower.contains('ayah') || pLower.contains('mary') || pLower.contains('cholera')) {
      return '“This shows young Mary Lennox in India when everything in her life suddenly turns upside down! Mortality walks closely here as a terrible illness strikes, but her courage will carry her on an unforgettable quest to England where her true story begins.”';
    }

    if (bLower.contains('prophet') || pLower.contains('almustafa') || pLower.contains('orphalese') || pLower.contains('love') || pLower.contains('heart')) {
      return '“Almustafa is teaching that true love and devotion are gifts given freely from the heart, just as my chivalric devotion to the peerless Lady Dulcinea del Toboso asks naught in return! When you share love and kindness with others, your spirit grows strong and radiant like a knight\'s armor.”';
    }

    if (bLower.contains('frankenstein') || pLower.contains('monster') || pLower.contains('lightning') || pLower.contains('science')) {
      return '“Victor Frankenstein is daring to uncover the deepest secrets of nature! But as every knight knows, great knowledge and power must always be guided by care and responsibility for others.”';
    }

    if (bLower.contains('pride') || pLower.contains('darcy') || pLower.contains('elizabeth') || pLower.contains('bennet')) {
      return '“This scene highlights how people judge each other too quickly based on first impressions and pride! The story teaches that true character and honor take patience and understanding to see.”';
    }

    if (bLower.contains('alice') || pLower.contains('rabbit') || pLower.contains('wonderland')) {
      return '“Alice is discovering that the rules of the normal world don\'t apply down the rabbit hole! Everything is curious and topsy-turvy, daring her to stay brave and think for herself.”';
    }

    if (bLower.contains('treasure island') || pLower.contains('silver') || pLower.contains('pirate')) {
      return '“Danger and hidden gold are in the air! Jim Hawkins is learning to keep his wits sharp among rough sailors. True courage is standing up for honor even when surrounded by pirates!”';
    }

    // 5. Friendly custom question answer
    if (q.contains('who') || q.contains('character')) {
      return '“The characters in "$bookTitle" are facing an important test of courage and heart! In this scene, their words show whether they are acting out of fear, curiosity, or noble loyalty.”';
    }

    if (q.contains('why')) {
      return '“They act this way because of what they believe in their hearts! Notice how this single decision causes everything that happens next in the story.”';
    }

    // Default warm knightly explanation
    return '“Hearken, noble student! In this passage from "$bookTitle", the author is showing us what the characters are feeling deep inside. Notice the quiet emotion beneath their words—it holds the secret to understanding this whole chapter!”';
  }
}
