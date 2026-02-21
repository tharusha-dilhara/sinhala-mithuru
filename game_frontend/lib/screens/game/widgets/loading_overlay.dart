import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:math' as math;

class LoadingOverlay extends StatefulWidget {
  const LoadingOverlay({super.key});

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with SingleTickerProviderStateMixin {
  final List<_Bubble> _bubbles = [];
  final math.Random _random = math.Random();
  late AnimationController _controller;
  int _poppedCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateBubbles);
    _controller.repeat();

    // Initial bubbles
    for (int i = 0; i < 5; i++) {
      _spawnBubble();
    }
  }

  void _spawnBubble() {
    final size = 40.0 + _random.nextDouble() * 60.0;
    _bubbles.add(
      _Bubble(
        x: _random.nextDouble() * 400, // Will be adjusted by layout
        y: 800, // Start below screen
        size: size,
        speed: 1.5 + _random.nextDouble() * 2.5,
        color: Colors.primaries[_random.nextInt(Colors.primaries.length)]
            .withOpacity(0.4),
      ),
    );
  }

  void _updateBubbles() {
    setState(() {
      for (int i = _bubbles.length - 1; i >= 0; i--) {
        _bubbles[i].y -= _bubbles[i].speed;
        if (_bubbles[i].y + _bubbles[i].size < -100) {
          _bubbles.removeAt(i);
          _spawnBubble();
        }
      }

      // Keep bubble count consistent
      if (_bubbles.length < 8 && _random.nextDouble() < 0.05) {
        _spawnBubble();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPop(int index) {
    setState(() {
      _bubbles.removeAt(index);
      _poppedCount++;
      _spawnBubble(); // Immediate respawn
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: Colors.black.withOpacity(0.4),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Stack(
              children: [
                // 1. Floating Bubbles
                ..._bubbles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final bubble = entry.value;
                  // Handle wrapping based on actual width
                  final xPos = bubble.x % (constraints.maxWidth - bubble.size);

                  return Positioned(
                    left: xPos,
                    top: bubble.y,
                    child: GestureDetector(
                      onTap: () => _onPop(index),
                      child: _BubbleWidget(bubble: bubble),
                    ),
                  );
                }),

                // 2. Popped Counter
                Positioned(
                  top: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Bubbles Popped: $_poppedCount",
                        style: GoogleFonts.notoSansSinhala(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Central Loading UI
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.8, end: 1.2),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return Transform.scale(scale: value, child: child);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.orange,
                            ),
                            strokeWidth: 5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Text(
                        "පොඩ්ඩක් ඉන්න...",
                        style: GoogleFonts.notoSansSinhala(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            const Shadow(blurRadius: 10, color: Colors.black),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "බුබුලු මත තට්ටු කර ඒවා පුපුරවන්න!",
                        style: GoogleFonts.notoSansSinhala(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Bubble {
  double x;
  double y;
  double size;
  double speed;
  Color color;

  _Bubble({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
  });
}

class _BubbleWidget extends StatelessWidget {
  final _Bubble bubble;
  const _BubbleWidget({required this.bubble});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: bubble.size,
      height: bubble.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bubble.color,
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: bubble.size * 0.4,
          height: bubble.size * 0.4,
          margin: const EdgeInsets.only(top: 5, left: 5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.2),
          ),
        ),
      ),
    );
  }
}
