import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/grammar_task.dart';
import '../../../services/game_service.dart';
import '../activity_layout.dart';
import 'grammar_feedback.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GrammarGamePage
//   Drag-and-drop sentence building activity.
//   Returns true to caller on success (so game_home_screen reloads data).
// ─────────────────────────────────────────────────────────────────────────────

const Color _kGrammarColor = Color(0xFF7C3AED); // Purple — grammar theme

class GrammarGamePage extends StatefulWidget {
  final GrammarTask task;
  final int grade;

  const GrammarGamePage({super.key, required this.task, this.grade = 1});

  @override
  State<GrammarGamePage> createState() => _GrammarGamePageState();
}

class _GrammarGamePageState extends State<GrammarGamePage> {
  final _gameService = GameService();
  final _stopwatch = Stopwatch();

  late List<String> _correctSentence;
  late List<String> _allWords;
  late List<String> _availableWords;
  late List<String?> _droppedWords;

  int _retryCount = 0;
  bool _showFeedback = false;
  bool _feedbackSuccess = false;
  String? _feedbackMessage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _resetRound();
    _stopwatch.start();
  }

  void _resetRound() {
    _correctSentence = List<String>.from(widget.task.words);
    _allWords = [
      ..._correctSentence,
      if (widget.task.nonRelated1 != null) ...widget.task.nonRelated1!,
      if (widget.task.nonRelated2 != null) ...widget.task.nonRelated2!,
      if (widget.task.nonRelated3 != null) ...widget.task.nonRelated3!,
    ];
    _allWords.shuffle();
    _availableWords = List.from(_allWords);
    _droppedWords = List.filled(_correctSentence.length, null);
  }

  void _handleDrop(int index, String word) {
    setState(() {
      if (_droppedWords[index] != null) {
        _availableWords.add(_droppedWords[index]!);
      }
      _droppedWords[index] = word;
      _availableWords.remove(word);
    });
  }

  void _handleRemove(int index) {
    if (_droppedWords[index] != null) {
      setState(() {
        _availableWords.add(_droppedWords[index]!);
        _droppedWords[index] = null;
      });
    }
  }

  // ─── Check answer ────────────────────────────────────────────────────────

  Future<void> _checkAnswer() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    _stopwatch.stop();

    // Local correctness check
    bool isLocalCorrect = true;
    for (int i = 0; i < _correctSentence.length; i++) {
      if (_droppedWords[i] != _correctSentence[i]) {
        isLocalCorrect = false;
        break;
      }
    }

    String? feedbackMsg;

    if (isLocalCorrect) {
      feedbackMsg = 'විශිෂ්ටයි! ඔබ නිවැරදි පිළිතුර ලබා දුන්නා.';
    } else {
      _retryCount++;
      final correctSet = _correctSentence.toSet();
      final droppedSet = _droppedWords.whereType<String>().toSet();

      if (droppedSet.length == correctSet.length &&
          droppedSet.every((w) => correctSet.contains(w))) {
        feedbackMsg =
            'වචන සියල්ල නිවැරදියි, නමුත් පිළිවෙළ වැරදියි. නැවත උත්සාහ කරන්න!';
      } else if (_droppedWords.first != _correctSentence.first) {
        feedbackMsg = 'වාක්‍යයේ පළමු වචනය වැරදියි. නිවැරදි වචනය තෝරන්න.';
      } else if (_droppedWords.last != _correctSentence.last) {
        feedbackMsg = 'වාක්‍යයේ අවසාන වචනය වැරදියි. නිවැරදිව නිම කරන්න.';
      } else {
        feedbackMsg =
            'වචනයක් හෝ කිහිපයක් වැරදියි. නිවැරදි වචන තෝරා නැවත උත්සාහ කරන්න.';
      }
    }

    // Submit to backend
    try {
      final builtSentence = _droppedWords.whereType<String>().join(' ');
      await _gameService.evaluateActivity(
        component: 'gram',
        timeTaken: _stopwatch.elapsedMilliseconds / 1000.0,
        rawInput: {
          'content_id': widget.task.id,
          'sentence': widget.task.sentence,
          'user_sentence': builtSentence,
          'task_id': widget.task.taskId,
          'is_correct': isLocalCorrect,
          'grade': widget.grade,
        },
      );
    } catch (e) {
      debugPrint('Grammar submit error: $e');
    }

    if (!mounted) return;

    setState(() {
      _feedbackSuccess = isLocalCorrect;
      _feedbackMessage = feedbackMsg;
      _showFeedback = true;
      _isSubmitting = false;
    });
  }

  void _handleTryAgain() {
    setState(() {
      _showFeedback = false;
      _stopwatch.reset();
      _stopwatch.start();
      _resetRound();
    });
  }

  void _handleContinue() {
    Navigator.pop(context, _feedbackSuccess);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isComplete = _droppedWords.every((s) => s != null);

    return ActivityLayout(
      headerText: 'සිංහල මිතුරු - ව්‍යාකරණ',
      title: widget.task.taskName,
      baseColor: _kGrammarColor,
      maxWidth: 1200,
      body: Stack(
        children: [
          // Main scrollable content
          Positioned.fill(
            child: SingleChildScrollView(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                // Retry count indicator
                if (_retryCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      'නැවත: $_retryCount',
                      style: GoogleFonts.notoSansSinhala(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),

                _buildImageAndSlots(),
                const SizedBox(height: 28),

                // Word bank label
                Text(
                  'වචන බැංකුව',
                  style: GoogleFonts.notoSansSinhala(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.brown.shade400,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),

                _buildWordBank(),
                const SizedBox(height: 28),

                _buildCheckButton(isComplete),
                const SizedBox(height: 8),
              ],
            ),
          ),
          ),
          ),

          // Feedback overlay
          if (_showFeedback)
            Positioned.fill(
              child: GrammarFeedbackLayout(
                isSuccess: _feedbackSuccess,
                sinhalaSentence: _correctSentence.join(' '),
                userAnswer: _droppedWords.whereType<String>().join(' '),
                englishSentence: widget.task.taskName,
                feedbackMessage: _feedbackMessage,
                canRetry: true,
                onTryAgain: _handleTryAgain,
                onContinue: _handleContinue,
              ),
            ),

          // Submitting overlay
          if (_isSubmitting)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x55000000),
                child: Center(
                  child: CircularProgressIndicator(
                    color: _kGrammarColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageAndSlots() {
    return Column(
      children: [
        // Task image
        if (widget.task.imageUrl != null)
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: _kGrammarColor.withOpacity(0.3), width: 3),
              boxShadow: [
                BoxShadow(
                  color: _kGrammarColor.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(29),
              child: Image.network(
                widget.task.imageUrl!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    widget.task.imageUrl!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(
                          Icons.image_not_supported,
                          color: _kGrammarColor.withOpacity(0.6),
                          size: 40,
                        ),
                  );
                },
              ),
            ),
          )
        else
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: _kGrammarColor.withOpacity(0.08),
              border: Border.all(color: _kGrammarColor.withOpacity(0.2)),
            ),
            child: Icon(
              Icons.image,
              size: 56,
              color: _kGrammarColor.withOpacity(0.4),
            ),
          ),
        const SizedBox(height: 20),

        // Instruction
        Text(
          'වචන ඇදගෙන නිවැරදි ස්ථානයේ දමන්න',
          style: GoogleFonts.notoSansSinhala(
            fontSize: 13,
            color: Colors.brown.shade400,
          ),
        ),
        const SizedBox(height: 16),

        // Drop slots
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: List.generate(
            _correctSentence.length,
            (i) => _buildDropTarget(i),
          ),
        ),
      ],
    );
  }

  Widget _buildDropTarget(int index) {
    return DragTarget<String>(
      builder: (context, candidateData, _) {
        final isOccupied = _droppedWords[index] != null;
        final isCandidate = candidateData.isNotEmpty;

        return GestureDetector(
          onTap: () => _handleRemove(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 110,
            height: 56,
            decoration: BoxDecoration(
              color: isCandidate
                  ? _kGrammarColor.withOpacity(0.12)
                  : isOccupied
                  ? Colors.white
                  : _kGrammarColor.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCandidate
                    ? _kGrammarColor
                    : isOccupied
                    ? _kGrammarColor.withOpacity(0.4)
                    : _kGrammarColor.withOpacity(0.2),
                width: isCandidate ? 2 : 1.5,
              ),
              boxShadow: isOccupied
                  ? [
                      BoxShadow(
                        color: _kGrammarColor.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: isOccupied
                ? Text(
                    _droppedWords[index]!,
                    style: GoogleFonts.notoSansSinhala(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E1B4B),
                    ),
                  )
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      color: _kGrammarColor.withOpacity(0.35),
                    ),
                  ),
          ),
        );
      },
      onAcceptWithDetails: (data) => _handleDrop(index, data.data),
    );
  }

  Widget _buildWordBank() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: _availableWords.map((word) {
        return Draggable<String>(
          data: word,
          feedback: Material(
            color: Colors.transparent,
            child: _WordChip(text: word, isDragging: true),
          ),
          childWhenDragging: Opacity(
            opacity: 0.35,
            child: _WordChip(text: word),
          ),
          child: _WordChip(text: word),
        );
      }).toList(),
    );
  }

  Widget _buildCheckButton(bool isComplete) {
    return AnimatedOpacity(
      opacity: isComplete ? 1.0 : 0.45,
      duration: const Duration(milliseconds: 300),
      child: ElevatedButton.icon(
        onPressed: isComplete ? _checkAnswer : null,
        icon: const Icon(Icons.check_circle_outline_rounded),
        label: Text(
          'පිළිතුර පරීක්ෂා කරන්න',
          style: GoogleFonts.notoSansSinhala(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kGrammarColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          elevation: 4,
          shadowColor: _kGrammarColor.withOpacity(0.4),
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _WordChip
// ─────────────────────────────────────────────────────────────────────────────

class _WordChip extends StatefulWidget {
  final String text;
  final bool isDragging;

  const _WordChip({required this.text, this.isDragging = false});

  @override
  State<_WordChip> createState() => _WordChipState();
}

class _WordChipState extends State<_WordChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isDragging || _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.translationValues(0, active ? -3 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: active ? _kGrammarColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _kGrammarColor.withOpacity(active ? 0.28 : 0.1),
              blurRadius: active ? 18 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          widget.text,
          style: GoogleFonts.notoSansSinhala(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : const Color(0xFF1E1B4B),
          ),
        ),
      ),
    );
  }
}
