import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'auth/login_option_screen.dart';
import 'auth/student_login_screen.dart';
import 'game/game_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Duration _minSplashDuration = Duration(milliseconds: 2000);

  // 1. Logo Intro (Big elastic bounce)
  late AnimationController _logoIntroController;
  late Animation<double> _logoScale;

  // 2. Logo Pulse (Continuous heartbeat after intro)
  late AnimationController _logoPulseController;
  late Animation<double> _logoPulse;

  // 3. Text Smooth Fade & Slide
  late AnimationController _textController;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  final _authService = AuthService();
  final Random _random = Random();
  late final DateTime _startupStartedAt;
  Timer? _textStartTimer;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _startupStartedAt = DateTime.now();

    // Setup 1: Initial massive elastic pop
    _logoIntroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _logoScale = CurvedAnimation(
      parent: _logoIntroController,
      curve: Curves.elasticOut, // Gives that super bouncy cartoon feel
    );

    // Setup 2: Continuous gentle heartbeat
    _logoPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoPulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _logoPulseController, curve: Curves.easeInOut),
    );

    // Setup 3: Smooth elegant text entry
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _textFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );

    // Sequence the animations
    _logoIntroController.forward().then((_) {
      // Once the big bounce finishes, start the continuous pulse
      _logoPulseController.repeat(reverse: true);
    });

    // Start text animation a bit after the logo starts
    _textStartTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        _textController.forward();
      }
    });

    _prepareStartup();
  }

  Future<void> _prepareStartup() async {
    final nextScreen = await _resolveNextScreen();
    final elapsed = DateTime.now().difference(_startupStartedAt);
    final remaining = _minSplashDuration - elapsed;

    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    if (!mounted || _isNavigating) {
      return;
    }

    _isNavigating = true;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<Widget> _resolveNextScreen() async {
    final loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      return const GameHomeScreen();
    }

    final lastStudent = await _authService.getLastStudent();
    if (lastStudent != null) {
      final studentId = int.tryParse(lastStudent['id'] ?? '');
      final studentName = lastStudent['name'];

      if (studentId != null && studentName != null && studentName.isNotEmpty) {
        return StudentPatternScreen(
          studentId: studentId,
          studentName: studentName,
        );
      }
    }

    return const LoginOptionScreen();
  }

  @override
  void dispose() {
    _textStartTimer?.cancel();
    _logoIntroController.dispose();
    _logoPulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE5E5F5), // Light lavender top
              Color(0xFFFFF0F5), // Soft pink middle
              Color(0xFFFBE4D8), // Light peach bottom
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Magical Background Particles
            ...List.generate(15, (index) => _buildAnimatedParticle(index)),

            // Center Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Bouncy and Pulsing Logo
                  ScaleTransition(
                    scale: _logoScale, // The initial big bounce
                    child: ScaleTransition(
                      scale: _logoPulse, // The continuous heartbeat
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.8),
                              blurRadius: 40,
                              spreadRadius: 20,
                            ),
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.3),
                              blurRadius: 60,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Hero(
                          tag: 'app_logo',
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 180,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Smooth gliding text
                  FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Column(
                        children: [
                          Text(
                            'සිංහල මිතුරු',
                            style: GoogleFonts.notoSansSinhala(
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF1A3B74),
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  blurRadius: 15,
                                  color: const Color(
                                    0xFF1A3B74,
                                  ).withOpacity(0.2),
                                  offset: const Offset(0, 8),
                                ),
                                const Shadow(
                                  blurRadius: 2,
                                  color: Colors.white,
                                  offset: Offset(0, -2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              'දරුවන්ට සිංහල ඉගෙනුම විනෝදයක් කරමු',
                              style: GoogleFonts.notoSansSinhala(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to create floating magical particles
  Widget _buildAnimatedParticle(int index) {
    final size = MediaQuery.of(context).size;
    final startX = _random.nextDouble() * size.width;
    final startY = _random.nextDouble() * size.height;

    // Vary the speed and size of each particle
    final duration = Duration(milliseconds: 3000 + _random.nextInt(4000));
    final particleSize = 10.0 + _random.nextDouble() * 25.0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      builder: (context, value, child) {
        // Create an oscillating, floating movement
        final dx = sin(value * 2 * pi + index) * 50;
        final dy = -value * size.height * 0.8; // Float upwards

        return Transform.translate(
          offset: Offset(startX + dx, startY + dy),
          child: Opacity(
            // Fade in and fade out
            opacity: sin(value * pi),
            child: Container(
              width: particleSize,
              height: particleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.8),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
