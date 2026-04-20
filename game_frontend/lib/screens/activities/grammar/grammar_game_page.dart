import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/grammar_task.dart';
import '../../../services/game_service.dart';
import 'grammar_feedback.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GrammarGamePage
//   Drag-and-drop sentence building activity.
//   Returns true to caller on success (so game_home_screen reloads data).
// ─────────────────────────────────────────────────────────────────────────────

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

    return Scaffold(
      backgroundColor: const Color(0xFFE0F2FE),
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE0F2FE), Colors.white],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildImageAndSlots(),
                        const SizedBox(height: 40),
                        _buildWordBank(),
                        const SizedBox(height: 40),
                        _buildCheckButton(isComplete),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Feedback overlay
          if (_showFeedback)
            GrammarFeedbackLayout(
              isSuccess: _feedbackSuccess,
              sinhalaSentence: _correctSentence.join(' '),
              userAnswer: _droppedWords.whereType<String>().join(' '),
              englishSentence: widget.task.taskName,
              feedbackMessage: _feedbackMessage,
              canRetry: true,
              onTryAgain: _handleTryAgain,
              onContinue: _handleContinue,
            ),

          // Submitting overlay
          if (_isSubmitting)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x55000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context, false),
          ),
          Expanded(
            child: Text(
              widget.task.taskName,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansSinhala(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_retryCount > 0)
            Text(
              'නැවත: $_retryCount',
              style: GoogleFonts.notoSansSinhala(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            )
          else
            const SizedBox(width: 48),
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
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueGrey.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
              image: DecorationImage(
                image: NetworkImage(widget.task.imageUrl!),
                fit: BoxFit.cover,
              ),
            ),
          )
        else
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              color: Colors.blue.withOpacity(0.1),
            ),
            child: const Icon(Icons.image, size: 64, color: Colors.blueGrey),
          ),
        const SizedBox(height: 28),

        // Instruction
        Text(
          'වචන ඇදගෙන නිවැරදි ස්ථානයේ දමන්න',
          style: GoogleFonts.notoSansSinhala(
            fontSize: 14,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 20),

        // Drop slots
        Wrap(
          spacing: 16,
          runSpacing: 16,
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
            width: 120,
            height: 60,
            decoration: BoxDecoration(
              color: isCandidate
                  ? Colors.blue.withOpacity(0.15)
                  : isOccupied
                  ? Colors.white
                  : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isCandidate
                    ? Colors.blue
                    : Colors.blueGrey.withOpacity(0.25),
                width: isCandidate ? 2 : 1,
              ),
              boxShadow: isOccupied
                  ? [
                      BoxShadow(
                        color: Colors.blueGrey.withOpacity(0.15),
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  )
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blueGrey.withOpacity(0.4),
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
      spacing: 12,
      runSpacing: 12,
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
      opacity: isComplete ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 300),
      child: ElevatedButton.icon(
        onPressed: isComplete ? _checkAnswer : null,
        icon: const Icon(Icons.check_circle_outline_rounded),
        label: Text(
          'පිළිතුර පරීක්ෂා කරන්න',
          style: GoogleFonts.notoSansSinhala(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _WordChip
// ─────────────────────────────────────────────────────────────────────────────

class _WordChip extends StatelessWidget {
  final String text;
  final bool isDragging;

  const _WordChip({required this.text, this.isDragging = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDragging ? const Color(0xFF0EA5E9) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(isDragging ? 0.35 : 0.15),
            blurRadius: isDragging ? 20 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.notoSansSinhala(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDragging ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
    );
  }
}
