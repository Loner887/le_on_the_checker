import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MaterialApp(home: GameScreen()));

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset player = Offset.zero;
  String selectedSkinPath = 'assets/images/player1.png'; // по умолчанию

  List<Offset> obstacles = [];
  List<Offset> obstacleVelocities = [];

  Offset velocity = Offset.zero;

  Offset? dragStart;
  Offset? dragCurrent;

  int attempts = 5;
  bool isAnimating = false;
  bool? isWin;

  int level = 1;
  int maxLevel = 3;

  final double playerRadius = 30;
  final double obstacleRadius = 30;
  final double scoringCircleRadius = 200;

  ui.Image? arrowImage;


  void saveSelectedSkin(int itemIndex) async {
    final prefs = await SharedPreferences.getInstance();
    String skinPath;

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
      default:
        skinPath = 'assets/images/player1.png';
    }

    await prefs.setString('selectedSkin', skinPath);
  }

  @override
  void initState() {
    super.initState();
    _loadSelectedSkin(); // ← ВАЖНО
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )
      ..addListener(_onTick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _checkWinCondition();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (isWin != true) {
              setState(() {
                player = Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height - 100);
                velocity = Offset.zero;
              });
            }
          });
        }
      });

    _loadArrowImage();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resetGame());
  }

  Future<void> _loadSelectedSkin() async {
    final prefs = await SharedPreferences.getInstance();
    final skinPath = prefs.getString('selectedSkin');
    if (skinPath != null) {
      setState(() {
        selectedSkinPath = skinPath;
      });
    }
  }

  Future<void> _loadArrowImage() async {
    final data = await rootBundle.load('assets/images/arrow.png');
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() {
      arrowImage = frame.image;
    });
  }

  void _resetGame() {
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height * 0.38);
    final rand = Random();

    final obstaclesCount = maxLevel - level + 1;

    setState(() {
      player = Offset(size.width / 2, size.height - 100);
      velocity = Offset.zero;

      obstacles = List.generate(obstaclesCount, (_) => Offset.zero);
      obstacleVelocities = List.generate(obstaclesCount, (_) => Offset.zero);

      for (int i = 0; i < obstacles.length; i++) {
        obstacles[i] = _randomPointInCircle(center, scoringCircleRadius * 0.8, rand);
        obstacleVelocities[i] = Offset.zero;
      }

      attempts = 5;
      isWin = null;
      isAnimating = false;
      dragStart = null;
      dragCurrent = null;
    });
  }

  Offset _randomPointInCircle(Offset center, double radius, Random rand) {
    final angle = rand.nextDouble() * 2 * pi;
    final r = sqrt(rand.nextDouble()) * radius;
    return Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
  }

  void _onTick() {
    setState(() {
      player += velocity;

      for (int i = 0; i < obstacles.length; i++) {
        obstacles[i] += obstacleVelocities[i];
      }

      for (int i = 0; i < obstacles.length; i++) {
        if (_checkCollision(player, obstacles[i])) {
          _handleCollisionBetween(player, velocity, obstacles[i], obstacleVelocities[i], (newVel, idx) {
            if (idx == 0) velocity = newVel;
            else obstacleVelocities[i] = newVel;
          });
        }
      }

      for (int i = 0; i < obstacles.length; i++) {
        for (int j = i + 1; j < obstacles.length; j++) {
          if (_checkCollision(obstacles[i], obstacles[j])) {
            _handleCollisionBetween(obstacles[i], obstacleVelocities[i], obstacles[j], obstacleVelocities[j], (newVel, idx) {
              if (idx == 0) obstacleVelocities[i] = newVel;
              else obstacleVelocities[j] = newVel;
            });
          }
        }
      }

      for (int i = 0; i < obstacleVelocities.length; i++) {
        obstacleVelocities[i] *= 0.98;
      }

      velocity *= 0.98;
    });
  }

  void _handleCollisionBetween(Offset pos1, Offset vel1, Offset pos2, Offset vel2, void Function(Offset newVelocity, int index) setVelocity) {
    final delta = pos2 - pos1;
    final distance = delta.distance;

    if (distance == 0) return;

    final normal = delta / distance;

    // Добавляем минимальное разделение
    const separationFactor = 1.2;
    final minSeparation = (playerRadius + obstacleRadius) * separationFactor;
    final separation = minSeparation - distance;

    if (separation > 0) {
      final separationVector = normal * separation * 0.5;
      setState(() {
        player -= separationVector;
        for (int i = 0; i < obstacles.length; i++) {
          if (obstacles[i] == pos2) {
            obstacles[i] += separationVector;
            break;
          }
        }
      });
    }

    final v1n = vel1.dx * normal.dx + vel1.dy * normal.dy;
    final v2n = vel2.dx * normal.dx + vel2.dy * normal.dy;

    final v1nAfter = v2n;
    final v2nAfter = v1n;

    final v1nVec = normal * v1nAfter;
    final v2nVec = normal * v2nAfter;

    final v1t = vel1 - normal * v1n;
    final v2t = vel2 - normal * v2n;

    setVelocity((v1t + v1nVec) * 0.8, 0);
    setVelocity((v2t + v2nVec) * 0.8, 1);
  }

  bool _checkCollision(Offset a, Offset b) {
    final dx = a.dx - b.dx;
    final dy = a.dy - b.dy;
    final distance = sqrt(dx * dx + dy * dy);
    return distance <= playerRadius + obstacleRadius;
  }

  void _checkWinCondition() {
    final screenSize = MediaQuery.of(context).size;
    final center = Offset(screenSize.width / 2, screenSize.height * 0.38);

    final allObstaclesOut = obstacles.every((obstacle) {
      return (obstacle - center).distance > scoringCircleRadius + obstacleRadius;
    });

    final isPlayerInside = (player - center).distance <= scoringCircleRadius;

    setState(() {
      if (allObstaclesOut && isPlayerInside) {
        isWin = true;
        isAnimating = false;

        if (level < maxLevel) {
          level++;
          Future.delayed(const Duration(seconds: 1), () {
            _resetGame();
          });
        }
      } else if (attempts == 0 && !allObstaclesOut) {
        isWin = false;
        isAnimating = false;
      } else {
        isAnimating = false;
      }
    });
  }

  void _launchPlayer() {
    if (isAnimating || attempts == 0 || isWin != null || dragStart == null || dragCurrent == null) return;

    final forceVector = dragStart! - dragCurrent!;
    velocity = forceVector * 0.04;

    player = Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height - 100);

    isAnimating = true;
    attempts--;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height * 0.38);

    return GestureDetector(
      onPanStart: (details) {
        dragStart = details.localPosition;
      },
      onPanUpdate: (details) {
        setState(() {
          dragCurrent = details.localPosition;
        });
      },
      onPanEnd: (_) {
        _launchPlayer();
        dragStart = null;
        dragCurrent = null;
      },
      child: Scaffold(
        body: Stack(
          children: [
            SizedBox.expand(
              child: Image.asset(
                'assets/images/gameBackgroundImage.png',
                fit: BoxFit.cover,
              ),
            ),

            CustomPaint(
              size: Size.infinite,
              painter: ScoringCirclePainter(center: center, radius: scoringCircleRadius),
            ),

            for (int i = 0; i < obstacles.length; i++)
              Positioned(
                left: obstacles[i].dx - obstacleRadius,
                top: obstacles[i].dy - obstacleRadius,
                child: Image.asset('assets/images/obstacle.png', width: obstacleRadius * 2),
              ),

            Positioned(
              left: player.dx - playerRadius,
              top: player.dy - playerRadius,
              child: Image.asset(selectedSkinPath, width: playerRadius * 2),
            ),

            if (dragStart != null && dragCurrent != null && arrowImage != null)
              CustomPaint(
                size: Size.infinite,
                painter: DragVectorPainter(
                  from: dragStart!,
                  to: dragCurrent!,
                  arrowImage: arrowImage,
                ),
              ),

            Positioned(
              left: 25,
              top: 25,
              child: Image.asset('assets/images/labelBackgroundImage.png', width: 375, height: 65,),
            ),

            Positioned(
              top: 40,
              right: 80,
              child: Text('Attempts: $attempts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  )),
            ),

            Positioned(
              top: 40,
              left: 80,
              child: Text('Level $level',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  )),
            ),

            if (isWin != null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isWin! ? level == maxLevel ? 'YOU WIN!' : 'YOU WIN!' : 'YOU LOSE',
                      style: const TextStyle(color: Colors.white, fontSize: 36),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (isWin! && level < maxLevel) {
                          _resetGame();
                        } else {
                          setState(() {
                            level = 1;
                          });
                          _resetGame();
                        }
                      },
                      child: Text(isWin! && level < maxLevel ? 'Next Level' : 'Play Again'),
                    )
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ScoringCirclePainter extends CustomPainter {
  final Offset center;
  final double radius;

  ScoringCirclePainter({required this.center, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);

    paint
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0)
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class DragVectorPainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final ui.Image? arrowImage;

  DragVectorPainter({required this.from, required this.to, this.arrowImage});

  @override
  void paint(Canvas canvas, Size size) {
    if (arrowImage == null) return;

    final paint = Paint();

    final vector = to - from;
    final angle = atan2(vector.dy, vector.dx);

    final imgWidth = arrowImage!.width.toDouble();
    final imgHeight = arrowImage!.height.toDouble();

    canvas.save();
    canvas.translate(from.dx, from.dy);
    canvas.rotate(angle);
    canvas.translate(0, -imgHeight / 2);
    canvas.drawImage(arrowImage!, Offset.zero, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DragVectorPainter oldDelegate) {
    return oldDelegate.from != from || oldDelegate.to != to || oldDelegate.arrowImage != arrowImage;
  }
}