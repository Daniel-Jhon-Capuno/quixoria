import 'package:flutter/material.dart';
import 'quixote_3d_character.dart';

enum QuixoteMood {
  proud,
  inquiring,
  caution,
  triumphant,
  sad,
}

/// Upgraded QuixoteAvatar powered by the volumetric 3D chibi Don Quixote engine.
class QuixoteAvatar extends StatelessWidget {
  final double size;
  final QuixoteMood mood;
  final bool showGoldBorder;

  const QuixoteAvatar({
    super.key,
    this.size = 80,
    this.mood = QuixoteMood.proud,
    this.showGoldBorder = true,
  });

  CharacterEmotion get _emotion {
    switch (mood) {
      case QuixoteMood.proud:
        return CharacterEmotion.happy;
      case QuixoteMood.inquiring:
        return CharacterEmotion.thinking;
      case QuixoteMood.caution:
        return CharacterEmotion.determined;
      case QuixoteMood.triumphant:
        return CharacterEmotion.excited;
      case QuixoteMood.sad:
        return CharacterEmotion.sad;
    }
  }

  CharacterPose get _pose {
    switch (mood) {
      case QuixoteMood.proud:
        return CharacterPose.idle;
      case QuixoteMood.inquiring:
        return CharacterPose.thinking;
      case QuixoteMood.caution:
        return CharacterPose.idle;
      case QuixoteMood.triumphant:
        return CharacterPose.celebration;
      case QuixoteMood.sad:
        return CharacterPose.idle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DonQuixote3DCharacter(
      size: size,
      pose: _pose,
      emotion: _emotion,
      idleValue: 0.5,
      bounceValue: 0.0,
      blinkValue: 0.0,
    );
  }
}
