import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:url_launcher/url_launcher.dart';
import 'start_scene.dart';
import 'game_scene.dart';
import 'shop_scene.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyGameApp());
}

class MyGameApp extends StatelessWidget {
  const MyGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Game',
      home: const GameWrapper(),
    );
  }
}

class GameWrapper extends StatelessWidget {
  const GameWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: StartScene(
          onNavigateToGame: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GameScreen()),
            );
          },
          onShowSettings: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text(''),
                content: const Text(''),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
          onShowPrivacy: () async {
            final url = Uri.parse('https://doc-hosting.flycricket.io/le-on-the-checker-privacy-policy/3f36afac-e18d-4e84-9ffb-4d84fafd2982/privacy');
            try {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Ошибка: ${e.toString()}")),
              );
            }
          },
          onShowShop: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShopScreen()),
            );
          },
        ),
      ),
    );
  }
}
