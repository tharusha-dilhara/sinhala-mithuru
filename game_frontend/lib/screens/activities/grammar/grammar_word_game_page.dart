import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/grammar_task.dart';
import '../../../services/game_service.dart';
import '../activity_layout.dart';
import 'grammar_feedback.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GrammarWordGamePage  (Grades 3–5)
//   Word-only drag-and-drop grammar game — no image selection step.
//   One word is pre-placed as a hint; remaining words are dragged from the bank.
//   Supports up to 3 rounds drawn from the supplied task list.
// ─────────────────────────────────────────────────────────────────────────────

const Color _kGrammarColor = Color(0xFF7C3AED); // Purple — grammar theme

class GrammarWordGamePage extends StatefulWidget {
  final List<GrammarTask> tasks;
  final int grade;

  const GrammarWordGamePage({
    super.key,
    required this.tasks,
    required this.grade,
  });

  @override
  State<GrammarWordGamePage> createState() => _GrammarWordGamePageState();
}

class _GrammarWordGamePageState extends State<GrammarWordGamePage> {
  final _gameService = GameService();

  List<Map<String, dynamic>> _rounds = [];
  int _currentRoundIndex = 0;

  // Per-round state
  List<String?> _droppedWords = [];
  List<String> _availableWords = [];

  int _retryCount = 0;
  bool _showFeedback = false;
  bool _feedbackSuccess = false;
  String? _feedbackMessage;
  bool _isSubmitting = false;
  bool _isInfoOpen = false;

  @override
  void initState() {
    super.initState();
    _buildRounds();
    if (_rounds.isNotEmpty) _loadRound(0);
  }

  // ─── Round generation ─────────────────────────────────────────────────────

  void _buildRounds() {
    final random = Random();
    // Higher grades get no fixed hint word (more challenging)
    final bool useFixedWord = widget.grade <= 3;

    _rounds = widget.tasks
        .take(3)
        .map((task) {
          final words = task.words;
          if (words.isEmpty) return null;

          int fixedIndex = -1;
          if (useFixedWord) fixedIndex = random.nextInt(words.length);

          final available = <String>[];
          for (int i = 0; i < words.length; i++) {
            if (i != fixedIndex) available.add(words[i]);
          }
          // Add distractors
          if (task.nonRelated1 != null && task.nonRelated1!.isNotEmpty)
            available.add(task.nonRelated1!.first);
          if (task.nonRelated2 != null && task.nonRelated2!.isNotEmpty)
            available.add(task.nonRelated2!.first);
          if (task.nonRelated3 != null && task.nonRelated3!.isNotEmpty)
            available.add(task.nonRelated3!.first);

          available.shuffle();

          return {
            'task': task,
            'correct': words,
            'fixedIndex': fixedIndex,
            'fixedWord': fixedIndex >= 0 ? words[fixedIndex] : null,
            'available': List<String>.from(available),
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  void _loadRound(int index) {
    setState(() {
      _currentRoundIndex = index;
      final round = _rounds[index];
      final wordCount = (round['correct'] as List<String>).length;
      _droppedWords = List.filled(wordCount, null);

      final fixedIndex = round['fixedIndex'] as int;
      if (fixedIndex >= 0) {
        _droppedWords[fixedIndex] = round['fixedWord'] as String;
      }
      _availableWords = List<String>.from(round['available'] as List<String>);
    });
  }

  // ─── Drag handlers ────────────────────────────────────────────────────────

  void _handleDrop(int slotIndex, String word) {
    if (_droppedWords[slotIndex] != null) return; // slot occupied
    setState(() {
      _droppedWords[slotIndex] = word;
      _availableWords.remove(word);
    });
  }

  void _handleRemove(int slotIndex) {
    final fixedIndex = _rounds[_currentRoundIndex]['fixedIndex'] as int;
    if (slotIndex == fixedIndex) return; // can't remove hint
    final word = _droppedWords[slotIndex];
    if (word == null) return;
    setState(() {
      _droppedWords[slotIndex] = null;
      _availableWords.add(word);
    });
  }

  // ─── Check answer ─────────────────────────────────────────────────────────

  Future<void> _checkAnswer() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final round = _rounds[_currentRoundIndex];
    final correct = round['correct'] as List<String>;

    bool isLocalCorrect =
        _droppedWords.length == correct.length &&
        List.generate(
          correct.length,
          (i) => _droppedWords[i] == correct[i],
        ).every((ok) => ok);

    String? feedbackMsg;
    if (isLocalCorrect) {
      feedbackMsg = 'විශිෂ්ටයි! ඔබ නිවැරදි පිළිතුර ලබා දුන්නා.';
    } else {
      _retryCount++;
      final correctSet = correct.toSet();
      final droppedSet = _droppedWords.whereType<String>().toSet();

      if (droppedSet.length == correctSet.length &&
          droppedSet.every((w) => correctSet.contains(w))) {
        feedbackMsg =
            'වචන සියල්ල නිවැරදියි, නමුත් පිළිවෙළ වැරදියි. නැවත උත්සාහ කරන්න!';
      } else if (_droppedWords.isNotEmpty &&
          _droppedWords.first != correct.first) {
        feedbackMsg = 'වාක්‍යයේ පළමු වචනය වැරදියි. නිවැරදි වචනය තෝරන්න.';
      } else if (_droppedWords.isNotEmpty &&
          _droppedWords.last != correct.last) {
        feedbackMsg = 'වාක්‍යයේ අවසාන වචනය වැරදියි. නිවැරදිව නිම කරන්න.';
      } else {
        feedbackMsg =
            'වචනයක් හෝ කිහිපයක් වැරදියි. නිවැරදි වචන තෝරා නැවත උත්සාහ කරන්න.';
      }
    }

    // Submit to backend
    try {
      final task = round['task'] as GrammarTask;
      await _gameService.evaluateActivity(
        component: 'gram',
        timeTaken: 0,
        rawInput: {
          'content_id': task.id,
          'sentence': task.sentence,
          'user_sentence': _droppedWords.whereType<String>().join(' '),
          'task_id': task.taskId,
          'is_correct': isLocalCorrect,
          'grade': widget.grade,
        },
      );
    } catch (e) {
      debugPrint('Grammar word submit error: $e');
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
      _loadRound(_currentRoundIndex);
    });
  }

  void _handleContinue() {
    Navigator.pop(context, _feedbackSuccess);
  }

  bool get _isAllFilled => _droppedWords.every((w) => w != null);

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_rounds.isEmpty) {
      return ActivityLayout(
        headerText: 'සිංහල මිතුරු - ව්‍යාකරණ',
        title: 'ව්‍යාකරණ ගොඩනැගීම',
        baseColor: _kGrammarColor,
        maxWidth: 1200,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 56,
                color: _kGrammarColor.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'ලබා ගත හැකි කාර්ය නොමැත.',
                style: GoogleFonts.notoSansSinhala(fontSize: 17),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGrammarColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: Text(
                  'ආපසු',
                  style: GoogleFonts.notoSansSinhala(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final task = _rounds[_currentRoundIndex]['task'] as GrammarTask;

    return ActivityLayout(
      headerText: 'සිංහල මිතුරු - ව්‍යාකරණ',
      title: 'ව්‍යාකරණ ගොඩනැගීම',
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                // Top bar: round info + retry count + info toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Task name pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _kGrammarColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: _kGrammarColor.withOpacity(0.25),
                        ),
                      ),
                      child: Text(
                        task.taskName,
                        style: GoogleFonts.notoSansSinhala(
                          color: _kGrammarColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        if (_retryCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
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
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        _InfoToggle(
                          isOpen: _isInfoOpen,
                          onToggle: () =>
                              setState(() => _isInfoOpen = !_isInfoOpen),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Slots area
                _buildSlotsArea(),
                const SizedBox(height: 16),

                // Hint text
                Center(
                  child: Text(
                    'නිවැරදි වචන ඇදගෙන ස්ලොට් තුළ දමන්න',
                    style: GoogleFonts.notoSansSinhala(
                      color: Colors.brown.shade400,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Word bank
                _buildWordBank(),
                const SizedBox(height: 24),

                // Check button
                Center(
                  child: _CheckButton(
                    onTap: _isAllFilled ? _checkAnswer : null,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          ),
          ),

          // Info panel overlay
          if (_isInfoOpen)
            Positioned(
              top: 48,
              right: 0,
              child: _InfoPanel(),
            ),

          // Feedback overlay
          if (_showFeedback)
            Positioned.fill(
              child: GrammarFeedbackLayout(
                isSuccess: _feedbackSuccess,
                sinhalaSentence:
                    (_rounds[_currentRoundIndex]['correct'] as List<String>)
                        .join(' '),
                userAnswer: _droppedWords.whereType<String>().join(' '),
                englishSentence:
                    (_rounds[_currentRoundIndex]['task'] as GrammarTask)
                        .taskName,
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
                  child: CircularProgressIndicator(color: _kGrammarColor),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlotsArea() {
    return Center(
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        alignment: WrapAlignment.center,
        children: [
          for (int i = 0; i < _droppedWords.length; i++) _buildSlot(i),
        ],
      ),
    );
  }

  Widget _buildSlot(int index) {
    final String? content = _droppedWords[index];
    final fixedIndex = _rounds[_currentRoundIndex]['fixedIndex'] as int;
    final bool isFixed = (index == fixedIndex);

    return SizedBox(
      width: 140,
      height: 140,
      child: isFixed
          ? _buildFixedSlot(content)
          : _buildDropTarget(index, content),
    );
  }

  Widget _buildFixedSlot(String? content) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kGrammarColor, _kGrammarColor.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(40),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF5B21B6), width: 5),
        ),
        boxShadow: [
          BoxShadow(
            color: _kGrammarColor.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        content ?? '',
        textAlign: TextAlign.center,
        style: GoogleFonts.notoSansSinhala(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDropTarget(int index, String? content) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => _droppedWords[index] == null,
      onAcceptWithDetails: (d) => _handleDrop(index, d.data),
      builder: (context, candidateData, _) {
        final isHovered = candidateData.isNotEmpty;
        final isOccupied = content != null;

        if (isOccupied) {
          return GestureDetector(
            onTap: () => _handleRemove(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: _kGrammarColor.withOpacity(0.35),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kGrammarColor.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                content,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E1B4B),
                ),
              ),
            ),
          );
        }

        // Empty slot
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isHovered
                ? _kGrammarColor.withOpacity(0.10)
                : _kGrammarColor.withOpacity(0.04),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: isHovered
                  ? _kGrammarColor
                  : _kGrammarColor.withOpacity(0.2),
              width: isHovered ? 2.5 : 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.add_circle_outline_rounded,
            size: 44,
            color: _kGrammarColor.withOpacity(isHovered ? 0.7 : 0.3),
          ),
        );
      },
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
            child: _WordCard(word: word, isActive: true),
          ),
          childWhenDragging: Opacity(
            opacity: 0.35,
            child: _WordCard(word: word),
          ),
          child: _WordCard(word: word),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Supporting widgets
// ─────────────────────────────────────────────────────────────────────────────

class _WordCard extends StatefulWidget {
  final String word;
  final bool isActive;
  const _WordCard({required this.word, this.isActive = false});

  @override
  State<_WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<_WordCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive || _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 130,
        height: 90,
        padding: const EdgeInsets.all(10),
        transform: Matrix4.translationValues(0, active ? -5 : 0, 0),
        decoration: BoxDecoration(
          color: active ? _kGrammarColor : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active
                ? _kGrammarColor
                : _kGrammarColor.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _kGrammarColor.withOpacity(active ? 0.22 : 0.08),
              blurRadius: active ? 18 : 8,
              offset: Offset(0, active ? 8 : 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          widget.word,
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansSinhala(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : const Color(0xFF1E1B4B),
          ),
        ),
      ),
    );
  }
}

class _CheckButton extends StatefulWidget {
  final VoidCallback? onTap;
  const _CheckButton({required this.onTap});

  @override
  State<_CheckButton> createState() => _CheckButtonState();
}

class _CheckButtonState extends State<_CheckButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_kGrammarColor, _kGrammarColor.withOpacity(0.75)],
              ),
              borderRadius: BorderRadius.circular(100),
              border: Border(
                bottom: BorderSide(color: const Color(0xFF5B21B6), width: 5),
              ),
              boxShadow: [
                BoxShadow(
                  color: _kGrammarColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'වාක්‍යය පරීක්ෂා කරන්න',
                  style: GoogleFonts.notoSansSinhala(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoToggle extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  const _InfoToggle({required this.isOpen, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isOpen ? _kGrammarColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOpen ? _kGrammarColor : _kGrammarColor.withOpacity(0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: _kGrammarColor.withOpacity(0.12),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(
          isOpen ? Icons.close_rounded : Icons.info_outline_rounded,
          color: isOpen ? Colors.white : _kGrammarColor,
          size: 22,
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: 270,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _kGrammarColor.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: _kGrammarColor.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: _kGrammarColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ව්‍යාකරණ ගොඩනැගීම',
                    style: GoogleFonts.notoSansSinhala(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E1B4B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'වාක්‍යය නිවැරදිව සම්පූර්ණ කිරීමට වචන ඇදගෙන ස්ලොට් තුළ දමන්න. '
                'නිල් ස්ලොටය ඉඟිය ලෙස ලබා දී ඇත.',
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 13,
                  height: 1.6,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
