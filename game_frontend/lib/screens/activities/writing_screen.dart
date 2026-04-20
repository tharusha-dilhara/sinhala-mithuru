import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/game_service.dart';
import 'activity_layout.dart';

// ─────────────────────────────────────────────────────────────
//  Writing Screen
// ─────────────────────────────────────────────────────────────

class WritingScreen extends StatefulWidget {
  final Map<String, dynamic> taskData;
  const WritingScreen({super.key, required this.taskData});

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen>
    with TickerProviderStateMixin {
  final _stopwatch = Stopwatch();
  final _gameService = GameService();

  // ── Drawing state ─────────────────────────────────────────
  final List<List<Offset>> _strokes = []; // completed strokes
  List<Offset> _currentStroke = []; // stroke being drawn

  // ── UI state ──────────────────────────────────────────────
  bool _isSubmitting = false;
  String? _verdict; // null | EXCELLENT | GOOD | INCORRECT
  double _verdictScore = 0.0;
  String? _identifiedSymbol; // HW model: ලිව්ව ලෙස හදුනාගත් අකුර

  // ── Animations ────────────────────────────────────────────
  late final AnimationController _verdictCtrl;
  late final Animation<double> _verdictScale;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _verdictCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _verdictScale = CurvedAnimation(
      parent: _verdictCtrl,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _verdictCtrl.dispose();
    super.dispose();
  }

  // ── Drawing callbacks ─────────────────────────────────────

  void _onPanStart(DragStartDetails d) {
    setState(() => _currentStroke = [d.localPosition]);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _currentStroke.add(d.localPosition));
  }

  void _onPanEnd(DragEndDetails _) {
    if (_currentStroke.isNotEmpty) {
      setState(() {
        _strokes.add(List<Offset>.from(_currentStroke));
        _currentStroke = [];
      });
    }
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
      _verdict = null;
    });
    _stopwatch.reset();
    _stopwatch.start();
  }

  // ── Submit ────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'කරුණාකර පළමුව අකුරක් ලියන්න',
            style: GoogleFonts.notoSansSinhala(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    _stopwatch.stop();

    try {
      // Normalise strokes → [{x, y}]
      final strokeData = _strokes
          .map((s) => s.map((o) => {'x': o.dx, 'y': o.dy}).toList())
          .toList();

      final result = await _gameService.evaluateActivity(
        component: 'hw',
        timeTaken: _stopwatch.elapsedMilliseconds / 1000.0,
        rawInput: {
          'target_char': widget.taskData['target_char'] ?? 'අ',
          'expected_label': widget.taskData['expected_label'],
          'content_id': widget.taskData['id'],
          'strokes': strokeData,
        },
      );

      if (!mounted) return;

      final score = ((result['score'] ?? 0.0) * 100).roundToDouble();
      final isOk = result['status'] == 'success';
      final raw = (result['verdict'] ?? '').toString().toUpperCase().trim();
      String verdict = raw.isNotEmpty
          ? raw
          : (isOk ? 'EXCELLENT' : 'INCORRECT');

      // Backend now marks it as success if the letter matches, but might still return verdict INCORRECT due to low score.
      // We must ensure the UI shows a passing state if isOk is true.
      if (isOk && verdict == 'INCORRECT') {
        verdict = 'GOOD';
      }

      final idSym = result['identified_symbol']?.toString();

      setState(() {
        _isSubmitting = false;
        _verdict = verdict;
        _verdictScore = score;
        _identifiedSymbol = idSym;
      });
      _verdictCtrl.forward(from: 0);

      await Future.delayed(const Duration(milliseconds: 2000));

      if (isOk) {
        if (mounted) Navigator.pop(context, true);
      } else {
        if (mounted) {
          setState(() => _verdict = null);
          _stopwatch.reset();
          _stopwatch.start();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('දෝෂයකි: $e', style: GoogleFonts.notoSansSinhala()),
            backgroundColor: Colors.red,
          ),
        );
        _stopwatch.reset();
        _stopwatch.start();
      }
    } finally {
      if (mounted && _verdict == null) setState(() => _isSubmitting = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final targetChar = widget.taskData['target_char']?.toString() ?? 'අ';

    return ActivityLayout(
      headerText: 'සිංහල මිතුරු - අත් අකුරු',
      title: '"$targetChar" අකුර ලියමු',
      baseColor: const Color(0xFFE91E63),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // ── Instruction ──────────────────────────────────
          Text(
            'ඉහත කොටුව ඇතුළත අකුර ලියන්න',
            style: GoogleFonts.notoSansSinhala(
              fontSize: 15,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),

          // ── Canvas area ───────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCanvas(targetChar),
            ),
          ),

          const SizedBox(height: 16),

          // ── Bottom buttons ────────────────────────────────
          _buildBottomBar(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Canvas widget ─────────────────────────────────────────

  Widget _buildCanvas(String targetChar) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // White drawing surface with shadow border
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE91E63).withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),

          // Guide lines painter
          CustomPaint(
            painter: _GuideLinePainter(),
            child: const SizedBox.expand(),
          ),

          // Touch / draw area
          GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: CustomPaint(
              painter: _StrokePainter(
                strokes: _strokes,
                current: _currentStroke,
              ),
              child: const SizedBox.expand(),
            ),
          ),

          // ── Verdict overlay ──────────────────────────────
          if (_verdict != null)
            _VerdictOverlay(
              verdict: _verdict!,
              score: _verdictScore,
              scaleAnim: _verdictScale,
              identifiedSymbol: _identifiedSymbol,
            ),
        ],
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Clear button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _clear,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'නැවත ලියන්න',
                style: GoogleFonts.notoSansSinhala(fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Submit button
          Expanded(
            flex: 2,
            child: _isSubmitting
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFE91E63),
                      strokeWidth: 3,
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: Text(
                      'ඉදිරිපත් කරන්න',
                      style: GoogleFonts.notoSansSinhala(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 4,
                      shadowColor: const Color(
                        0xFFE91E63,
                      ).withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Stroke painter — renders all recorded strokes + live stroke
// ─────────────────────────────────────────────────────────────

class _StrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> current;

  const _StrokePainter({required this.strokes, required this.current});

  static final Paint _ink = Paint()
    ..color = const Color(0xFF1A1A2E)
    ..strokeWidth = 8.0
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    _drawStroke(canvas, current);
  }

  void _drawStroke(Canvas canvas, List<Offset> pts) {
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(path, _ink);
  }

  @override
  bool shouldRepaint(_StrokePainter old) => true;
}

// ─────────────────────────────────────────────────────────────
//  Guide line painter — dotted lines + solid midlines
// ─────────────────────────────────────────────────────────────

class _GuideLinePainter extends CustomPainter {
  const _GuideLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final solid = Paint()
      ..color = Colors.pink.shade100
      ..strokeWidth = 1.2;

    final dashed = Paint()
      ..color = Colors.pink.shade50
      ..strokeWidth = 1.0;

    // 4 guide lines at 20%, 40%, 60%, 80%
    for (final frac in [0.2, 0.4, 0.6, 0.8]) {
      final y = size.height * frac;
      if (frac == 0.4 || frac == 0.6) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), solid);
      } else {
        _dashes(canvas, Offset(0, y), Offset(size.width, y), dashed);
      }
    }

    // Vertical centre guide
    _dashes(
      canvas,
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      dashed,
    );
  }

  void _dashes(Canvas canvas, Offset a, Offset b, Paint p) {
    const step = 8.0, gap = 6.0;
    final dx = b.dx - a.dx, dy = b.dy - a.dy;
    final len = (b - a).distance;
    double t = 0;
    while (t < len) {
      final t1 = t / len;
      final t2 = (t + step).clamp(0, len) / len;
      canvas.drawLine(
        Offset(a.dx + dx * t1, a.dy + dy * t1),
        Offset(a.dx + dx * t2, a.dy + dy * t2),
        p,
      );
      t += step + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────
//  Verdict overlay (shared with reading_screen pattern)
// ─────────────────────────────────────────────────────────────

class _VerdictOverlay extends StatelessWidget {
  final String verdict;
  final double score;
  final Animation<double> scaleAnim;
  final String? identifiedSymbol; // HW model: ලිව්ව ලෙස හදුනාගත් අකුර

  const _VerdictOverlay({
    required this.verdict,
    required this.score,
    required this.scaleAnim,
    this.identifiedSymbol,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg(verdict);
    return Container(
      decoration: BoxDecoration(
        color: cfg.color.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: scaleAnim,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                child: Icon(cfg.icon, color: Colors.white, size: 78),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                cfg.tag,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              cfg.label,
              style: GoogleFonts.notoSansSinhala(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (score > 0) ...[
              const SizedBox(height: 6),
              Text(
                'ලකුණු: ${score.toStringAsFixed(0)}%',
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 17,
                  color: Colors.white70,
                ),
              ),
            ],
            if (verdict == 'INCORRECT') ...[
              const SizedBox(height: 10),
              // Show which letter was identified (HW feedback)
              if (identifiedSymbol != null && identifiedSymbol!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              Text(
                'නැවත ලියා බලන්න...',
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 13,
                  color: Colors.white54,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static ({Color color, IconData icon, String label, String tag}) _cfg(
    String v,
  ) {
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
