import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/game_service.dart';
import '../activities/activity_layout.dart';

class ScoreScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final int grade;
  final int level;
  final int masterLevelId;

  const ScoreScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.grade,
    required this.level,
    required this.masterLevelId,
  });

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen>
    with TickerProviderStateMixin {
  final _gameService = GameService();
  bool _isSubmitting = false;
  String? _verdict;
  double _verdictScore = 0.0;

  late final AnimationController _verdictCtrl;
  late final Animation<double> _verdictScale;

  @override
  void initState() {
    super.initState();
    _verdictCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _verdictScale = CurvedAnimation(
      parent: _verdictCtrl,
      curve: Curves.elasticOut,
    );

    // Auto-submit on mount
    WidgetsBinding.instance.addPostFrameCallback((_) => _submitResult());
  }

  @override
  void dispose() {
    _verdictCtrl.dispose();
    super.dispose();
  }

  double get _scorePercentage =>
      widget.totalQuestions > 0 ? widget.score / widget.totalQuestions : 0;

  Future<void> _submitResult() async {
    setState(() => _isSubmitting = true);

    try {
      final result = await _gameService.evaluateActivity(
        component: 'narr',
        timeTaken: 0,
        rawInput: {
          "quiz_score": widget.score,
          "total_questions": widget.totalQuestions,
          "grade": widget.grade,
          "level": widget.level,
          "master_level_id": widget.masterLevelId,
        },
      );

      if (!mounted) return;

      final score = ((result['score'] ?? _scorePercentage) * 100)
          .roundToDouble();
      final isOk = result['status'] == 'success';

      final rawVerdict = (result['verdict'] ?? '')
          .toString()
          .toUpperCase()
          .trim();
      final verdict = rawVerdict.isNotEmpty
          ? rawVerdict
          : (isOk ? 'EXCELLENT' : 'INCORRECT');

      setState(() {
        _isSubmitting = false;
        _verdict = verdict;
        _verdictScore = score;
      });
      _verdictCtrl.forward(from: 0);

      await Future.delayed(const Duration(milliseconds: 2000));

      if (isOk) {
        if (mounted) Navigator.pop(context, true);
      } else {
        // On failure, show verdict then go back (no retry for comprehension)
        if (mounted) Navigator.pop(context, false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('දෝෂයකි: $e', style: GoogleFonts.notoSansSinhala()),
            backgroundColor: Colors.red,
          ),
        );
        // Still navigate back on error
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) Navigator.pop(context, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ActivityLayout(
      headerText: 'සිංහල මිතුරු - අවබෝදය',
      title: 'ප්‍රතිඵලය',
      baseColor: Colors.orange,
      body: Stack(
        children: [
          // ── Main content (visible while submitting) ──
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSubmitting) ...[
                  const SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      color: Colors.orange,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ප්‍රතිඵලය ලබා ගනිමින්...',
                    style: GoogleFonts.notoSansSinhala(
                      fontSize: 16,
                      color: Colors.orange.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.score} / ${widget.totalQuestions} නිවැරදියි',
                    style: GoogleFonts.notoSansSinhala(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Verdict overlay (same pattern as ReadingScreen/WritingScreen) ──
          if (_verdict != null)
            IgnorePointer(
              child: _VerdictOverlay(
                verdict: _verdict!,
                score: _verdictScore,
                scaleAnim: _verdictScale,
                quizScore: widget.score,
                totalQuestions: widget.totalQuestions,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Verdict overlay widget (matches ReadingScreen/WritingScreen)
// ─────────────────────────────────────────────────────────────

class _VerdictOverlay extends StatelessWidget {
  final String verdict;
  final double score;
  final Animation<double> scaleAnim;
  final int quizScore;
  final int totalQuestions;

  const _VerdictOverlay({
    required this.verdict,
    required this.score,
    required this.scaleAnim,
    required this.quizScore,
    required this.totalQuestions,
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

            // Quiz score
            Text(
              '$quizScore / $totalQuestions නිවැරදියි',
              style: GoogleFonts.notoSansSinhala(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ලකුණු: ${score.toStringAsFixed(0)}%',
              style: GoogleFonts.notoSansSinhala(
                fontSize: 16,
                color: Colors.white60,
              ),
            ),

            if (verdict == 'INCORRECT') ...[
              const SizedBox(height: 12),
              Text(
                'තවත් උත්සාහ කරන්න...',
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
          color: const Color(0xFFD4A017),
          icon: Icons.star_rounded,
          label: 'ඉතා හොඳයි!',
          tag: 'EXCELLENT',
        );
      case 'GOOD':
        return (
          color: const Color(0xFF0097A7),
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
