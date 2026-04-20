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
    with TickerProviderStateMixin {
  final List<_Balloon> _balloons = [];
  final math.Random _random = math.Random();
  late AnimationController _tickController;
  late AnimationController _titleBounceController;
  late Animation<double> _titleBounceAnim;
  int _poppedCount = 0;

  final List<_PopParticle> _particles = [];

  static const List<Color> _balloonColors = [
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFFFFE66D),
    Color(0xFFA78BFA),
    Color(0xFF60A5FA),
    Color(0xFFFB923C),
    Color(0xFFF472B6),
    Color(0xFF34D399),
  ];

  @override
  void initState() {
    super.initState();
    _tickController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_tick);
    _tickController.repeat();

    _titleBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _titleBounceAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _titleBounceController, curve: Curves.easeInOut),
    );
    _titleBounceController.repeat(reverse: true);

    for (int i = 0; i < 8; i++) {
      _spawnBalloon(initialSpawn: true);
    }
  }

  void _spawnBalloon({bool initialSpawn = false}) {
    final size = 50.0 + _random.nextDouble() * 50.0;
    final color = _balloonColors[_random.nextInt(_balloonColors.length)];
    _balloons.add(
      _Balloon(
        x: 20 + _random.nextDouble() * 360,
        y: initialSpawn
            ? 100 + _random.nextDouble() * 600
            : 850 + _random.nextDouble() * 100,
        size: size,
        speed: 1.0 + _random.nextDouble() * 2.0,
        wobbleOffset: _random.nextDouble() * math.pi * 2,
        wobbleSpeed: 1.5 + _random.nextDouble() * 2.0,
        color: color,
        highlight: Color.lerp(color, Colors.white, 0.5)!,
      ),
    );
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      final t = DateTime.now().millisecondsSinceEpoch / 1000.0;

      for (int i = _balloons.length - 1; i >= 0; i--) {
        final b = _balloons[i];
        b.y -= b.speed;
        b.x += math.sin(t * b.wobbleSpeed + b.wobbleOffset) * 0.6;
        if (b.y + b.size < -60) {
          _balloons.removeAt(i);
          _spawnBalloon();
        }
      }

      for (int i = _particles.length - 1; i >= 0; i--) {
        final p = _particles[i];
        p.x += p.vx;
        p.y += p.vy;
        p.vy += 0.15;
        p.life -= 0.04;
        if (p.life <= 0) _particles.removeAt(i);
      }

      while (_balloons.length < 8) {
        _spawnBalloon();
      }
    });
  }

  void _onPop(int index) {
    final b = _balloons[index];
    final cx = b.x + b.size / 2;
    final cy = b.y + b.size / 2;

    for (int i = 0; i < 10; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 2.0 + _random.nextDouble() * 4.0;
      _particles.add(
        _PopParticle(
          x: cx,
          y: cy,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 2,
          color: b.color,
          size: 4 + _random.nextDouble() * 6,
        ),
      );
    }

    setState(() {
      _balloons.removeAt(index);
      _poppedCount++;
      _spawnBalloon();
    });
  }

  @override
  void dispose() {
    _tickController.dispose();
    _titleBounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: Colors.black.withOpacity(0.25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Stack(
              children: [
                // ── Floating Balloons ──
                ..._balloons.asMap().entries.map((entry) {
                  final index = entry.key;
                  final balloon = entry.value;
                  final xPos =
                      balloon.x %
                      (constraints.maxWidth - balloon.size).clamp(
                        1,
                        double.infinity,
                      );

                  return Positioned(
                    left: xPos,
                    top: balloon.y,
                    child: GestureDetector(
                      onTap: () => _onPop(index),
                      child: _BalloonWidget(balloon: balloon),
                    ),
                  );
                }),

                // ── Pop Particles ──
                ..._particles.map((p) {
                  return Positioned(
                    left: p.x,
                    top: p.y,
                    child: Opacity(
                      opacity: p.life.clamp(0, 1),
                      child: Container(
                        width: p.size,
                        height: p.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.color,
                          boxShadow: [
                            BoxShadow(
                              color: p.color.withOpacity(0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // ── Counter Badge (Top) — Glassmorphism ──
                Positioned(
                  top: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🎈', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Text(
                                "$_poppedCount",
                                style: GoogleFonts.notoSansSinhala(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Central Content — Glassmorphism Card ──
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 30,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 30,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Loading spinner
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.88, end: 1.12),
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeInOut,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: child,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.2),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    strokeWidth: 4,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Main message
                            AnimatedBuilder(
                              animation: _titleBounceAnim,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _titleBounceAnim.value,
                                  child: child,
                                );
                              },
                              child: Text(
                                "පොඩ්ඩක් ඉන්න... 🎮",
                                style: GoogleFonts.notoSansSinhala(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 8,
                                      color: Colors.black.withOpacity(0.3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Sub message
                            Text(
                              "එතකම් මේ පොඩි mini game එක play කරමු! 🎈",
                              style: GoogleFonts.notoSansSinhala(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "බැලුම් තට්ටු කර පුපුරවන්න!",
                              style: GoogleFonts.notoSansSinhala(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _Balloon {
  double x, y, size, speed, wobbleOffset, wobbleSpeed;
  Color color, highlight;

  _Balloon({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.wobbleOffset,
    required this.wobbleSpeed,
    required this.color,
    required this.highlight,
  });
}

class _PopParticle {
  double x, y, vx, vy, size, life;
  Color color;

  _PopParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    this.life = 1.0,
  });
}

class _BalloonWidget extends StatelessWidget {
  final _Balloon balloon;
  const _BalloonWidget({required this.balloon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: balloon.size,
      height: balloon.size * 1.3,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Balloon body
          Container(
            width: balloon.size,
            height: balloon.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                radius: 0.8,
                colors: [
                  balloon.highlight,
                  balloon.color,
                  Color.lerp(balloon.color, Colors.black, 0.2)!,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: balloon.color.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Align(
              alignment: const Alignment(-0.35, -0.35),
              child: Container(
                width: balloon.size * 0.28,
                height: balloon.size * 0.22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(balloon.size),
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ),

          // Knot
          Positioned(
            bottom: balloon.size * 0.16,
            child: CustomPaint(
              size: const Size(10, 8),
              painter: _KnotPainter(balloon.color),
            ),
          ),

          // String
          Positioned(
            bottom: 0,
            child: Container(
              width: 1.5,
              height: balloon.size * 0.22,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.35),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KnotPainter extends CustomPainter {
  final Color color;
  _KnotPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.lerp(color, Colors.black, 0.2)!
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
