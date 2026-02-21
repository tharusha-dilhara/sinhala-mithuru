import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/game_service.dart';
import 'activity_layout.dart';

class LettersScreen extends StatefulWidget {
  final Map<String, dynamic> taskData;
  const LettersScreen({super.key, required this.taskData});

  @override
  State<LettersScreen> createState() => _LettersScreenState();
}

class _LettersScreenState extends State<LettersScreen> {
  final _stopwatch = Stopwatch();
  final _gameService = GameService();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
  }

  Future<void> _submitActivity() async {
    setState(() => _isSubmitting = true);
    _stopwatch.stop();

    try {
      final result = await _gameService.evaluateActivity(
        component: 'gram', // ව්‍යාකරණ සඳහා
        timeTaken: _stopwatch.elapsedMilliseconds / 1000.0,
        rawInput: {
          "theme": widget.taskData['theme'] ?? "සාමාන්‍ය",
          "question": widget.taskData['story_prompt'] ?? "මෙය කුමක්ද?",
          "user_answer": "ක්ෂීරපායී සතෙකි" // ඉදිරියේදී මෙය Text Input එකකින් ලබා ගත හැක
        },
      );

      if (result['status'] == 'success' && mounted) {
        Navigator.pop(context, true);
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
    final String theme = widget.taskData['theme'] ?? "තේමාව";
    final String prompt = widget.taskData['story_prompt'] ?? "කෙටි කතාවක්...";

    return ActivityLayout(
      headerText: "සිංහල මිතුරු - අක්ෂර සහ ව්‍යාකරණ",
      title: "මාතෘකාව: $theme",
      baseColor: Colors.green,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 100,
            color: Colors.green.withOpacity(0.5),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              prompt,
              style: GoogleFonts.notoSansSinhala(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 50),
          
          _isSubmitting
              ? const CircularProgressIndicator(color: Colors.green)
              : ElevatedButton.icon(
                  onPressed: _submitActivity,
                  icon: const Icon(Icons.check_circle),
                  label: const Text("පිළිතුරු ලබා දුන්නා"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
        ],
      ),
    );
  }
}