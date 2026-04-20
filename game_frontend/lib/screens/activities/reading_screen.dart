import 'dart:io';
import 'dart:math' as math;
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../services/game_service.dart';
import '../game/widgets/loading_overlay.dart';
import 'activity_layout.dart';

class ReadingScreen extends StatefulWidget {
  final Map<String, dynamic> taskData;
  const ReadingScreen({super.key, required this.taskData});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen>
    with TickerProviderStateMixin {
  final _stopwatch = Stopwatch();
  final _gameService = GameService();
  final _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  bool _isSubmitting = false;
  bool _isDragging = false;
  String? _verdict; // null=hidden  EXCELLENT / GOOD / INCORRECT
  double _verdictScore = 0.0;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  late final AnimationController _verdictController;
  late final Animation<double> _verdictScaleAnim;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _verdictController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _verdictScaleAnim = CurvedAnimation(
      parent: _verdictController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _verdictController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  // ─────────────── Microphone ───────────────

  Future<void> _startRecording() async {
    if (!await _audioRecorder.hasPermission()) {
      _showSnack('මයික්\u200dරොෆෝනය භාවිතා කිරීමට අවසරයක් නැත', Colors.red);
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.wav),
      path: path,
    );
    setState(() => _isRecording = true);
    _pulseController.repeat(reverse: true);
  }

  Future<void> _stopAndSubmit() async {
    final path = await _audioRecorder.stop();
    _pulseController.stop();
    _stopwatch.stop();
    setState(() {
      _isRecording = false;
      _isSubmitting = true;
    });
    await _submit(path);
  }

  // ─────────────── Drag & Drop ─────────────

  Future<void> _onFileDrop(DropDoneDetails details) async {
    setState(() {
      _isDragging = false;
      _isSubmitting = true;
    });
    _stopwatch.stop();
    final dropped = details.files.firstOrNull;
    if (dropped == null) {
      setState(() => _isSubmitting = false);
      return;
    }
    await _submit(dropped.path);
  }

  // ─────────────── Submit ───────────────────

  Future<void> _submit(String? filePath) async {
    // Show bubble-popping loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => const Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: LoadingOverlay(),
      ),
    );

    try {
      if (filePath == null || !File(filePath).existsSync()) {
        throw Exception('Audio ෆයිල් එක සොයාගත නොහැකිවිය');
      }
      final result = await _gameService.evaluateActivity(
        component: 'pron',
        timeTaken: _stopwatch.elapsedMilliseconds / 1000.0,
        rawInput: {
          'target_text': widget.taskData['target_text'] ?? '',
          'content_id': widget.taskData['id'],
        },
        audioFilePath: filePath,
      );
      if (!mounted) return;
      Navigator.pop(context); // Close loading overlay

      final score = ((result['score'] ?? 0.0) * 100).roundToDouble();
      final isOk = result['status'] == 'success';

      // If backend didn't send verdict (old cache), infer from status
      final rawVerdict = (result['verdict'] ?? '')
          .toString()
          .toUpperCase()
          .trim();
      final verdict = rawVerdict.isNotEmpty
          ? rawVerdict
          : (isOk ? 'EXCELLENT' : 'INCORRECT');

      // Show verdict overlay
      setState(() {
        _isSubmitting = false;
        _verdict = verdict;
        _verdictScore = score;
      });
      _verdictController.forward(from: 0);

      await Future.delayed(const Duration(milliseconds: 2000));

      if (isOk) {
        if (mounted) Navigator.pop(context, true);
      } else {
        if (mounted) setState(() => _verdict = null);
        _stopwatch.reset();
        _stopwatch.start();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading overlay
        _showSnack('දෝෂයකි: $e', Colors.red);
      }
      _stopwatch.reset();
      _stopwatch.start();
    } finally {
      if (mounted && _verdict == null) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ─────────────── Build ────────────────────

  @override
  Widget build(BuildContext context) {
    final targetText = widget.taskData['target_text'] as String? ?? '';

    return ActivityLayout(
      headerText: 'සිංහල මිතුරු - කියවීම',
      title: 'පාඩම කියවමු',
      baseColor: Colors.blue,
      body: DropTarget(
        onDragEntered: (_) => setState(() => _isDragging = true),
        onDragExited: (_) => setState(() => _isDragging = false),
        onDragDone: _onFileDrop,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: _isDragging
                ? Border.all(color: Colors.blue.shade300, width: 2.0)
                : Border.all(color: Colors.transparent, width: 2.0),
            color: _isDragging
                ? Colors.blue.withValues(alpha: 0.07)
                : Colors.transparent,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Main content ─────────────────────────────
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Large letter card ─────────────────
                    Container(
                      constraints: BoxConstraints(
                        minWidth: 220,
                        minHeight: 220,
                        maxWidth: MediaQuery.of(context).size.width * 0.85,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.blue.shade50, Colors.blue.shade100],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.18),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1.6,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          targetText,
                          style: GoogleFonts.notoSansSinhala(
                            fontSize: 110,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Status label ──────────────────────
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        _isRecording
                            ? '⏹️  නිමාවූ විට නැවත ස්පර්ශ කරන්න'
                            : _isSubmitting
                            ? '⏳  AI ඇගයීම සිදු කෙරෙමින්...'
                            : '🎙️  මයික් ස්පර්ශ කර කියවන්න',
                        key: ValueKey('$_isRecording$_isSubmitting'),
                        style: GoogleFonts.notoSansSinhala(
                          fontSize: 15,
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ── Mic button / spinner ──────────────
                    if (_isSubmitting)
                      Column(
                        children: [
                          const _AiLoadingAnimation(),
                          const SizedBox(height: 16),
                          Text(
                            'AI ඇගයීම සිදු කෙරෙමින්...',
                            style: GoogleFonts.notoSansSinhala(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      )
                    else
                      GestureDetector(
                        onTap: _isRecording ? _stopAndSubmit : _startRecording,
                        child: AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (_, child) => Transform.scale(
                            scale: _isRecording ? _pulseAnim.value : 1.0,
                            child: child,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer glow ring — visible only while recording
                              if (_isRecording)
                                AnimatedBuilder(
                                  animation: _pulseAnim,
                                  builder: (ctx, w) => Container(
                                    width: 130,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red.withValues(
                                        alpha: 0.13 * _pulseAnim.value,
                                      ),
                                    ),
                                  ),
                                ),
                              // Main mic circle
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: _isRecording
                                        ? [
                                            Colors.red.shade400,
                                            Colors.red.shade700,
                                          ]
                                        : [
                                            Colors.blue.shade400,
                                            Colors.blue.shade700,
                                          ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (_isRecording
                                                  ? Colors.red
                                                  : Colors.blue)
                                              .withValues(alpha: 0.45),
                                      blurRadius: 24,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isRecording
                                      ? Icons.stop_rounded
                                      : Icons.mic_rounded,
                                  color: Colors.white,
                                  size: 44,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Verdict overlay (EXCELLENT / GOOD / INCORRECT) ──
              if (_verdict != null)
                IgnorePointer(
                  child: _VerdictOverlay(
                    verdict: _verdict!,
                    score: _verdictScore,
                    scaleAnim: _verdictScaleAnim,
                  ),
                ),

              // ── Drag-over full overlay ────────────────────
              if (_isDragging)
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.audio_file_rounded,
                            size: 72,
                            color: Colors.blue.shade400,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'ගොනුව මෙතනට දමන්න',
                            style: GoogleFonts.notoSansSinhala(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  AI Loading Animation widget
// ─────────────────────────────────────────────────────────────

class _AiLoadingAnimation extends StatefulWidget {
  const _AiLoadingAnimation();

  @override
  State<_AiLoadingAnimation> createState() => _AiLoadingAnimationState();
}

class _AiLoadingAnimationState extends State<_AiLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        final glowValue =
            0.5 + 0.5 * math.sin(_controller.value * math.pi * 2).abs();
        return SizedBox(
          width: 76,
          height: 76,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating outer sweep gradient ring
              Transform.rotate(
                angle: _controller.value * 2 * math.pi,
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return SweepGradient(
                      colors: [
                        Colors.blue.withValues(alpha: 0.1),
                        Colors.blue.shade600,
                      ],
                      stops: const [0.0, 1.0],
                    ).createShader(rect);
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                  ),
                ),
              ),
              // Inner glowing AI icon
              Transform.scale(
                scale: 0.85 + (0.15 * glowValue),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade50,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade400.withValues(
                          alpha: 0.4 * glowValue,
                        ),
                        blurRadius: 12 * glowValue,
                        spreadRadius: 4 * glowValue,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Verdict overlay widget
// ─────────────────────────────────────────────────────────────

class _VerdictOverlay extends StatelessWidget {
  final String verdict; // 'EXCELLENT' | 'GOOD' | 'INCORRECT'
  final double score;
  final Animation<double> scaleAnim;

  const _VerdictOverlay({
    required this.verdict,
    required this.score,
    required this.scaleAnim,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = _verdictConfig(verdict);

    return Container(
      decoration: BoxDecoration(
        color: cfg.color.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouncing icon
            ScaleTransition(
              scale: scaleAnim,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                child: Icon(cfg.icon, color: Colors.white, size: 80),
              ),
            ),
            const SizedBox(height: 20),

            // Verdict badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                cfg.tag,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Sinhala label
            Text(
              cfg.label,
              style: GoogleFonts.notoSansSinhala(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // Score
            Text(
              'ලකුණු: ${score.toStringAsFixed(0)}%',
              style: GoogleFonts.notoSansSinhala(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),

            // Retry hint for wrong
            if (verdict == 'INCORRECT') ...[
              const SizedBox(height: 12),
              Text(
                'නැවත උත්සාහ කරන්න...',
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 14,
                  color: Colors.white54,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static ({Color color, IconData icon, String label, String tag})
  _verdictConfig(String v) {
    switch (v) {
      case 'EXCELLENT':
        return (
          color: const Color(0xFFD4A017), // Gold
          icon: Icons.star_rounded,
          label: 'ඉතා හොඳයි!',
          tag: 'EXCELLENT',
        );
      case 'GOOD':
        return (
          color: const Color(0xFF0097A7), // Teal
          icon: Icons.thumb_up_rounded,
          label: 'හොඳයි!',
          tag: 'GOOD',
        );
      default:
        return (
          color: Colors.red.shade600,
          icon: Icons.cancel_rounded,
          label: 'වැරදියි!',
          tag: 'INCORRECT',
        );
    }
  }
}
