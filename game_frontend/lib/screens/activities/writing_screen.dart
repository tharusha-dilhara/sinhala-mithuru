import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/game_service.dart';
import 'activity_layout.dart';

class WritingScreen extends StatefulWidget {
  final Map<String, dynamic> taskData;
  const WritingScreen({super.key, required this.taskData});

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen> {
  final _stopwatch = Stopwatch();
  final _gameService = GameService();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _stopwatch.start(); // කාලය මැනීම අරඹන්න
  }

  Future<void> _submitActivity() async {
    setState(() => _isSubmitting = true);
    _stopwatch.stop();

    try {
      final result = await _gameService.evaluateActivity(
        component: 'hw', 
        timeTaken: _stopwatch.elapsedMilliseconds / 1000.0,
        rawInput: {
          "target_char": widget.taskData['target_char'] ?? "අ",
          "strokes": [
            [[50, 100], [60, 110]], 
            [[100, 150], [110, 160]]
          ] // දරුවා අඳින ඉරි මෙතැනට යාවත්කාලීන කළ හැක
        },
      );

      if (result['status'] == 'success' && mounted) {
        Navigator.pop(context, true); // Home එකට යන්න
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("දෝෂයකි: $e")));
      }
      _stopwatch.start();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String targetChar = widget.taskData['target_char'] ?? "";

    return ActivityLayout(
      headerText: "සිංහල මිතුරු - අත් අකුරු",
      title: "$targetChar අකුර ලියමු",
      baseColor: Colors.redAccent,
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black45,
                  style: BorderStyle.solid,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  // පසුබිමෙන් අදාළ අකුර පෙන්වීම
                  Center(
                    child: Text(
                      targetChar,
                      style: TextStyle(
                        fontSize: 200,
                        color: Colors.grey.withOpacity(0.15),
                      ),
                    ),
                  ),
                  // මෙහි දෝෂය නිවැරදි කර ඇත 👇
                  const CustomPaint(
                    painter: LinePainter(), // දැන් LinePainter එක const ලෙස හඳුනා ගනී
                    child: SizedBox.expand(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "ඉහත කොටුවේ අකුර ලියන්න",
            style: GoogleFonts.notoSansSinhala(
              fontSize: 16,
              color: Colors.brown.shade600,
            ),
          ),
          const SizedBox(height: 10),
          
          // Submit බොත්තම
          _isSubmitting
              ? const CircularProgressIndicator(color: Colors.redAccent)
              : ElevatedButton.icon(
                  onPressed: _submitActivity,
                  icon: const Icon(Icons.check_circle),
                  label: const Text("ලියා අවසන් කළා"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class LinePainter extends CustomPainter {
  // මෙම constructor එක අලුතින් එක් කළා (දෝෂය මඟ හැරීමට) 👇
  const LinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.3),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.7),
      paint,
    );

    _drawDashedLine(
      canvas,
      Offset(0, size.height * 0.1),
      Offset(size.width, size.height * 0.1),
      dashPaint,
    );
    _drawDashedLine(
      canvas,
      Offset(0, size.height * 0.9),
      Offset(size.width, size.height * 0.9),
      dashPaint,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const int dashWidth = 5;
    const int dashSpace = 5;
    double startX = start.dx;
    while (startX < end.dx) {
      canvas.drawLine(Offset(startX, start.dy), Offset(startX + dashWidth, start.dy), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}