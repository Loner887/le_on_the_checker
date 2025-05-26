import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/components.dart';

class StartScene extends FlameGame {
  final VoidCallback onNavigateToGame;
  final VoidCallback onShowPrivacy;
  final VoidCallback onShowShop;

  StartScene({
    required this.onNavigateToGame,
    required this.onShowPrivacy,
    required this.onShowShop,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _setupBackground();
    await _setupButtons();
  }

  Future<void> _setupBackground() async {
    final sprite = await Sprite.load('startBackgroundImage.png');
    final background = SpriteComponent(
      sprite: sprite,
      size: size,
      position: size / 2,
      anchor: Anchor.center,
    );
    add(background);
  }

  Future<void> _setupButtons() async {
    final playSprite = await Sprite.load('playButtonImage.png');
    final startSprite = await Sprite.load('startButtonImage.png');
    final privacySprite = await Sprite.load('privacyButtonImage.png');
    final shopSprite = await Sprite.load('shopButtonImage.png');

    final playButton = SpriteButtonComponent(
      button: playSprite,
      position: Vector2(size.x / 2, size.y * 0.35),
      anchor: Anchor.center,
      onPressed: onNavigateToGame,
    );

    final startButton = SpriteButtonComponent(
      button: startSprite,
      position: Vector2(size.x / 2, size.y * 0.48),
      anchor: Anchor.center,
      onPressed: onNavigateToGame,
    );

    final privacyButton = SpriteButtonComponent(
      button: privacySprite,
      position: Vector2(size.x / 2, size.y * 0.77),
      anchor: Anchor.center,
      onPressed: onShowPrivacy,
    );

    final shopButton = SpriteButtonComponent(
      button: shopSprite,
      position: Vector2(size.x / 2, size.y * 0.61),
      anchor: Anchor.center,
      onPressed: onShowShop,
    );

    add(playButton);
    add(startButton);
    add(privacyButton);
    add(shopButton);
  }
}
