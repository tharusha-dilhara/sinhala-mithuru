import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/quiz_model.dart';
import 'quiz_screen.dart';
import '../activities/activity_layout.dart';

class StoryScreen extends StatefulWidget {
  final String storyText;
  final Future<List<QuizQuestion>> quizFuture;
  final int grade;
  final int level;
  final int masterLevelId;

  const StoryScreen({
    super.key,
    required this.storyText,
    required this.quizFuture,
    required this.grade,
    required this.level,
    required this.masterLevelId,
  });

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen>
    with SingleTickerProviderStateMixin {
  late List<String> _fixedSentences;
  late List<String> _shuffledSentences;
  late List<String> _correctShuffledOrder;

  bool _isSolved = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  final List<Color> _blockColors = [
    const Color(0xFFFCE4EC), // pink.50
    const Color(0xFFE3F2FD), // blue.50
    const Color(0xFFE8F5E9), // green.50
    const Color(0xFFFFF3E0), // orange.50
    const Color(0xFFF3E5F5), // purple.50
  ];

  final List<Color> _blockBorders = [
    const Color(0xFFF48FB1), // pink.200
    const Color(0xFF90CAF9), // blue.200
    const Color(0xFFA5D6A7), // green.200
    const Color(0xFFFFCC80), // orange.200
    const Color(0xFFCE93D8), // purple.200
  ];

  @override
  void initState() {
    super.initState();
    _initializeDynamicPuzzle();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation =
        Tween<double>(
            begin: 0,
            end: 10,
          ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _shakeController.reset();
            }
          });
  }

  // 🟢 Adaptive Scaffolding Algorithm
  void _initializeDynamicPuzzle() {
    List<String> allSentences = widget.storyText
        .split('.')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => "$s.")
        .toList();

    if (allSentences.isEmpty) {
      allSentences = ["කතාවක් නැත."];
    }

    int shuffleCount = 2;

    if (widget.grade == 1) {
      if (widget.level >= 11 && widget.level <= 15) {
        shuffleCount = 2;
      } else if (widget.level >= 16 && widget.level <= 20) {
        shuffleCount = 3;
      }
    } else {
      if (widget.level >= 1 && widget.level <= 5) {
        shuffleCount = 2;
      } else if (widget.level >= 6 && widget.level <= 10) {
        shuffleCount = 3;
      } else if (widget.level >= 11 && widget.level <= 15) {
        shuffleCount = 4;
      } else if (widget.level >= 16) {
        shuffleCount = allSentences.length;
      }
    }

    if (shuffleCount > allSentences.length) {
      shuffleCount = allSentences.length;
    }

    int fixedCount = allSentences.length - shuffleCount;

    setState(() {
      _fixedSentences = allSentences.sublist(0, fixedCount);
      _correctShuffledOrder = allSentences.sublist(fixedCount);
      _shuffledSentences = List.from(_correctShuffledOrder);
      _shuffledSentences.shuffle();

      while (listEquals(_shuffledSentences, _correctShuffledOrder) &&
          _shuffledSentences.length > 1) {
        _shuffledSentences.shuffle();
      }
    });

    debugPrint("🤖 AI generated ${allSentences.length} sentences.");
    debugPrint("🔒 Locked the first $fixedCount sentences.");
    debugPrint("🔀 Shuffled the last $shuffleCount sentences.");
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final String item = _shuffledSentences.removeAt(oldIndex);
      _shuffledSentences.insert(newIndex, item);
    });
  }

  void _resetPuzzle() {
    setState(() {
      _shuffledSentences.shuffle();
      while (listEquals(_shuffledSentences, _correctShuffledOrder) &&
          _shuffledSentences.length > 1) {
        _shuffledSentences.shuffle();
      }
      _isSolved = false;
    });
  }

  void _checkOrder() {
    if (listEquals(_shuffledSentences, _correctShuffledOrder)) {
      setState(() => _isSolved = true);
      _showFeedback(
        "නියමයි! පිළිවෙල හරි! ✨",
        Colors.green,
        Icons.check_circle_rounded,
      );
    } else {
      _shakeController.forward();
      _showFeedback(
        "තවම හරි නැහැ! ආයේ හදමු 🧩",
        Colors.redAccent,
        Icons.warning_amber_rounded,
      );
    }
  }

  Future<void> _navigateToQuiz() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Colors.orange,
                strokeWidth: 5,
              ),
              const SizedBox(height: 16),
              Text(
                'ප්‍රශ්න සූදානම් කරමින්...',
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    List<QuizQuestion> finalQuiz;
    try {
      finalQuiz = await widget.quizFuture;
    } catch (e) {
      debugPrint("Background Quiz Failed: $e");
      finalQuiz = [
        QuizQuestion(
          question: "කතාව හොඳින් කියෙව්වාද?",
          options: ["ඔව්", "නැහැ", "මතක නැහැ"],
          correctAnswerIndex: 0,
        ),
      ];
    }

    if (mounted) Navigator.pop(context);

    if (mounted) {
      final quizResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(
            questions: finalQuiz,
            storyText: widget.storyText,
            grade: widget.grade,
            level: widget.level,
            masterLevelId: widget.masterLevelId,
          ),
        ),
      );

      // Forward the result back to GameHomeScreen
      if (mounted) Navigator.pop(context, quizResult);
    }
  }

  void _showFeedback(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ActivityLayout(
      headerText: 'සිංහල මිතුරු - අවබෝදය',
      title: 'කතාව හදමු',
      baseColor: Colors.orange,
      body: Column(
        children: [
          // ── Fixed sentences ──
          if (_fixedSentences.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200, width: 1.2),
              ),
              child: Text(
                _fixedSentences.join(" "),
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.brown.shade800,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.justify,
              ),
            ),

          // ── Instruction ──
          Text(
            _isSolved
                ? '✅ හරි! දැන් ප්‍රශ්නවලට යමු'
                : '🔀 වාක්‍ය නිවැරදි පිළිවෙලට සකසන්න',
            style: GoogleFonts.notoSansSinhala(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),

          // ── Reorderable blocks ──
          Expanded(
            child: ReorderableListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              onReorder: _onReorder,
              buildDefaultDragHandles: false,
              children: [
                for (int i = 0; i < _shuffledSentences.length; i++)
                  _buildPuzzleBlock(i, _shuffledSentences[i]),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Bottom buttons ──
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSolved ? null : _resetPuzzle,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    'නැවත හදමු',
                    style: GoogleFonts.notoSansSinhala(fontSize: 13),
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
              Expanded(
                flex: 2,
                child: AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        _shakeAnimation.value *
                            (1 - (_shakeController.value * 2)).sign *
                            5,
                        0,
                      ),
                      child: child,
                    );
                  },
                  child: ElevatedButton.icon(
                    onPressed: _isSolved ? _navigateToQuiz : _checkOrder,
                    icon: Icon(
                      _isSolved
                          ? Icons.arrow_forward_rounded
                          : Icons.check_circle_outline_rounded,
                    ),
                    label: Text(
                      _isSolved ? 'ප්‍රශ්න වලට යමු' : 'හරිද බලමු',
                      style: GoogleFonts.notoSansSinhala(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSolved ? Colors.green : Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 4,
                      shadowColor: (_isSolved ? Colors.green : Colors.orange)
                          .withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzleBlock(int index, String text) {
    final bgColor = _blockColors[index % _blockColors.length];
    final borderColor = _blockBorders[index % _blockBorders.length];

    return ReorderableDragStartListener(
      key: ValueKey(text),
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.drag_indicator_rounded,
                color: Colors.black38,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
