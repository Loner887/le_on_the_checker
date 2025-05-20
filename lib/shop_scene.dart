import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: ShopGame(context),
      ),
    );
  }
}

class ShopGame extends FlameGame {
  final BuildContext context;
  int coins = 60;
  int selectedSkinIndex = 0;
  final List<SpriteButtonComponent> skinButtons = [];

  ShopGame(this.context);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _setupShopUI();
  }

  Future<void> _setupShopUI() async {
    final backgroundSprite = await Sprite.load('shop_background.png');
    final background = SpriteComponent(
      sprite: backgroundSprite,
      size: size,
      position: size / 2,
      anchor: Anchor.center,
    );
    add(background);

    final backButtonSprite = await Sprite.load('back_button.png');
    final backButton = SpriteButtonComponent(
      button: backButtonSprite,
      position: Vector2(33, 50),
      size: Vector2(184, 65),
      onPressed: () => Navigator.pop(context),
    );
    add(backButton);

    final coinBgSprite = await Sprite.load('coin_bg.png');
    final coinBg = SpriteComponent(
      sprite: coinBgSprite,
      position: Vector2(size.x - 200, 50),
      size: Vector2(184, 65),
    );
    add(coinBg);

    final coinText = TextComponent(
      text: 'SKIN',
      position: Vector2(size.x - 110, 85),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.black,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(coinText);

    final buttonSprite = await Sprite.load('buy_button.png');
    final selectButtonSprite = await Sprite.load('buy_button.png');

    final positions = [
      Vector2(size.x * 0.27, size.y * 0.38),
      Vector2(size.x * 0.73, size.y * 0.38),
      Vector2(size.x / 2, size.y * 0.71),
    ];

    for (int i = 0; i < 3; i++) {
      final button = SpriteButtonComponent(
        button: i == 0 ? selectButtonSprite : buttonSprite,
        position: Vector2(positions[i].x, positions[i].y + 20),
        size: Vector2(170, 46),
        anchor: Anchor.center,
        onPressed: () => _handleItemAction(i),
      );
      add(button);
      skinButtons.add(button);
    }
  }

  void _handleItemAction(int itemIndex) async {
    // Эффект нажатия на кнопку
    final button = skinButtons[itemIndex];
    button.add(
      ScaleEffect.to(
        Vector2(0.9, 0.9),
        EffectController(
          duration: 0.1,
          reverseDuration: 0.1,
          curve: Curves.easeOut,
        ),
      ),
    );

    button.add(
      OpacityEffect.fadeOut(
        EffectController(
          duration: 0.05,
          reverseDuration: 0.1,
          curve: Curves.easeOut,
        ),
      )..onComplete = () {
        button.add(
          OpacityEffect.fadeIn(
            EffectController(
              duration: 0.1,
              curve: Curves.easeIn,
            ),
          ),
        );
      },
    );

    print('Нажата кнопка покупки для предмета $itemIndex');

    final price = 0;
    if (coins >= price) {
      coins -= price;

      String skinPath = '';
      switch (itemIndex) {
        case 0:
          skinPath = 'assets/images/player2.png';
          break;
        case 1:
          skinPath = 'assets/images/player1.png';
          break;
        case 2:
          skinPath = 'assets/images/player3.png';
          break;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedSkin', skinPath);

      // Подсветка выбранного скина
      for (int i = 0; i < skinButtons.length; i++) {
        if (i == itemIndex) {
          skinButtons[i].add(
            SequenceEffect(
              [
                ScaleEffect.to(
                  Vector2(1.1, 1.1),
                  EffectController(duration: 0.2),
                ),
                ScaleEffect.to(
                  Vector2.all(1.0),
                  EffectController(duration: 0.2),
                ),
              ],
            ),
          );
        }
      }

      print('Скин установлен: $skinPath');
    } else {
      print('Недостаточно монет для покупки предмета $itemIndex');

      // Эффект "тряски" кнопки при недостатке монет
      button.add(
        MoveEffect.by(
          Vector2(5, 0),
          EffectController(
            duration: 0.05,
            alternate: true,
            repeatCount: 3,
          ),
        ),
      );

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Недостаточно монет'),
          content: const Text('Вам нужно больше монет для покупки этого предмета.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}