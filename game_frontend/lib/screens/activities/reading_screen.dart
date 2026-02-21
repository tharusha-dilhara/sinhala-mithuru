// lib/screens/activities/reading_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/game_service.dart';
import 'activity_layout.dart';

class ReadingScreen extends StatefulWidget {
  final Map<String, dynamic> taskData;
  const ReadingScreen({super.key, required this.taskData});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final _stopwatch = Stopwatch();
  final _gameService = GameService();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    _stopwatch.stop();
    
    try {
      final result = await _gameService.evaluateActivity(
        component: 'pron',
        timeTaken: _stopwatch.elapsedMilliseconds / 1000.0,
        rawInput: {
          "target_text": widget.taskData['target_text'],
          "audio_data": "BASE64_STUB", // මෙතැනට මයික්‍රොෆෝනයෙන් එන දත්ත දිය යුතුයි
          "audio_format": "wav"
        },
      );

      if (result['status'] == 'success' && mounted) {
        Navigator.pop(context, true); // සාර්ථක නම් Home එකට
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      _stopwatch.start();
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ActivityLayout(
      headerText: "සිංහල මිතුරු - කියවීම",
      title: "පාඩම කියවමු",
      baseColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.taskData['target_text'] ?? "", // Backend එකෙන් ආපු වචනය
              style: GoogleFonts.notoSansSinhala(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
            ),
            const SizedBox(height: 50),
            if (_isSubmitting) 
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.mic),
                label: const Text("කියවා අවසන් කරන්න"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
              ),
          ],
        ),
      ),
    );
  }
}