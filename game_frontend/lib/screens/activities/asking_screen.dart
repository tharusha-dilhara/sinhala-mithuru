import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/game_service.dart';
import 'activity_layout.dart';

class AskingScreen extends StatefulWidget {
  // Backend එකෙන් එන දත්ත ලබා ගැනීමට (JSON හි narrative ලැයිස්තුවේ ඇති අංගය)
  final Map<String, dynamic> taskData;
  const AskingScreen({super.key, required this.taskData});

  @override
  State<AskingScreen> createState() => _AskingScreenState();
}

class _AskingScreenState extends State<AskingScreen> {
  final _stopwatch = Stopwatch();
  final _gameService = GameService();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _stopwatch.start(); // අභ්‍යාසය ආරම්භ කළ මොහොතේ සිට කාලය මැනීම අරඹන්න
  }

  Future<void> _submitActivity() async {
    setState(() => _isSubmitting = true);
    _stopwatch.stop();

    try {
      // Backend එකට දත්ත යැවීම (component=narr)
      final result = await _gameService.evaluateActivity(
        component: 'narr',
        timeTaken: _stopwatch.elapsedMilliseconds / 1000.0,
        rawInput: {
          "target_sentence": widget.taskData['target_sentence'] ?? "", // "බල්ලා බත් කයි"
          "audio_data": "BASE64_AUDIO_STUB", // පසුව මයික්‍රොෆෝනයෙන් ලබාගන්නා හඬපටයේ base64 කේතය මෙතැනට දෙන්න
          "audio_format": "wav"
        },
      );

      // සාර්ථක නම් ආපසු Game Home Screen එකට යන්න
      if (result['status'] == 'success' && mounted) {
        Navigator.pop(context, true); // අවසන් කළේ නම් true එකෙන් යන්න එවිට refresh වෙයි
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("දෝෂයකි: $e")),
        );
      }
      _stopwatch.start(); // දෝෂයක් ආවොත් නැවත කාලය මැනීම අරඹන්න
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // JSON එකෙන් ලැබෙන වාක්‍යය ලබා ගැනීම
    final String sentence = widget.taskData['target_sentence'] ?? "වාක්‍යයක් නොමැත";

    return ActivityLayout(
      headerText: "සිංහල මිතුරු - විමසීම",
      title: "පහත වාක්‍යය කියවන්න",
      baseColor: Colors.orange,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // විමසීම අංශයේ අයිකනය
          Icon(
            Icons.psychology,
            size: 100,
            color: Colors.orange.withOpacity(0.5),
          ),
          const SizedBox(height: 30),
          
          // දරුවාට කියවීමට ඇති වාක්‍යය පෙන්වීම
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              sentence,
              style: GoogleFonts.notoSansSinhala(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade900,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 50),

          // පටිගත කිරීම අවසන් කිරීමේ බොත්තම
          _isSubmitting
              ? const CircularProgressIndicator(color: Colors.orange)
              : ElevatedButton.icon(
                  onPressed: _submitActivity,
                  icon: const Icon(Icons.mic),
                  label: const Text("පටිගත කර අවසන් කරන්න"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    textStyle: GoogleFonts.notoSansSinhala(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}