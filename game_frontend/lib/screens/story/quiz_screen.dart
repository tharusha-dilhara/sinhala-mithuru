import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/quiz_model.dart';
import 'score_screen.dart';
import '../activities/activity_layout.dart';

class QuizScreen extends StatefulWidget {
  final List<QuizQuestion> questions;
  final String storyText;
  final int grade;
  final int level;
  final int masterLevelId;

  const QuizScreen({
    super.key,
    required this.questions,
    required this.storyText,
    required this.grade,
    required this.level,
    required this.masterLevelId,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  int? _selectedOptionIndex;

  void _handleAnswer(int selectedIndex) {
    if (_isAnswered) return;

    bool isCorrect =
        selectedIndex == widget.questions[_currentIndex].correctAnswerIndex;

    setState(() {
      _isAnswered = true;
      _selectedOptionIndex = selectedIndex;
      if (isCorrect) _score++;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _nextQuestion();
    });
  }

  Future<void> _nextQuestion() async {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _isAnswered = false;
        _selectedOptionIndex = null;
      });
    } else {
      final scoreResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScoreScreen(
            score: _score,
            totalQuestions: widget.questions.length,
            grade: widget.grade,
            level: widget.level,
            masterLevelId: widget.masterLevelId,
          ),
        ),
      );

      // Forward the result back to StoryScreen → GameHomeScreen
      if (mounted) Navigator.pop(context, scoreResult);
    }
  }

  void _showStoryHint() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "📖 කතාව",
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.brown.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    widget.storyText,
                    style: GoogleFonts.notoSansSinhala(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "හරි, ප්‍රශ්නයට යමු!",
                    style: GoogleFonts.notoSansSinhala(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return ActivityLayout(
        headerText: 'සිංහල මිතුරු - අවබෝදය',
        title: 'ප්‍රශ්න',
        baseColor: Colors.orange,
        body: Center(
          child: Text(
            "ප්‍රශ්න සොයාගත නොහැක.",
            style: GoogleFonts.notoSansSinhala(fontSize: 18),
          ),
        ),
      );
    }

    final question = widget.questions[_currentIndex];
    double progress = (_currentIndex + 1) / widget.questions.length;

    return ActivityLayout(
      headerText: 'සිංහල මිතුරු - අවබෝදය',
      title: 'ප්‍රශ්න අංක ${_currentIndex + 1}',
      baseColor: Colors.orange,
      body: Column(
        children: [
          // ── Progress bar ──
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                color: Colors.orange,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Question card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.shade200, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              question.question,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansSinhala(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.brown.shade800,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Options ──
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: question.options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildOptionButton(
                index,
                question.options[index],
                question.correctAnswerIndex,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Story hint button ──
          TextButton.icon(
            onPressed: _showStoryHint,
            icon: const Icon(Icons.menu_book_rounded, size: 20),
            label: Text(
              'කතාව බලමු',
              style: GoogleFonts.notoSansSinhala(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(int index, String text, int correctIndex) {
    Color bgColor = Colors.white;
    Color borderColor = Colors.grey.shade300;
    Color textColor = Colors.black87;
    IconData? statusIcon;

    if (_isAnswered) {
      if (index == correctIndex) {
        bgColor = Colors.green.shade50;
        borderColor = Colors.green.shade400;
        textColor = Colors.green.shade800;
        statusIcon = Icons.check_circle_rounded;
      } else if (index == _selectedOptionIndex) {
        bgColor = Colors.red.shade50;
        borderColor = Colors.red.shade400;
        textColor = Colors.red.shade700;
        statusIcon = Icons.cancel_rounded;
      } else {
        bgColor = Colors.grey.shade100;
        borderColor = Colors.grey.shade200;
        textColor = Colors.grey.shade400;
      }
    }

    return GestureDetector(
      onTap: () => _handleAnswer(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color:
                    _isAnswered &&
                        (index == correctIndex || index == _selectedOptionIndex)
                    ? borderColor.withValues(alpha: 0.2)
                    : Colors.orange.shade50,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isAnswered ? borderColor : Colors.orange.shade200,
                ),
              ),
              child: Center(
                child: statusIcon != null
                    ? Icon(statusIcon, color: borderColor, size: 22)
                    : Text(
                        "${index + 1}",
                        style: GoogleFonts.notoSansSinhala(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.orange.shade800,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
