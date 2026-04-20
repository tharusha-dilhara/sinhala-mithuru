import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/grammar_task.dart';
import '../../../services/game_service.dart';
import 'grammar_feedback.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GrammarWordGamePage  (Grades 3–5)
//   Word-only drag-and-drop grammar game — no image selection step.
//   One word is pre-placed as a hint; remaining words are dragged from the bank.
//   Supports up to 3 rounds drawn from the supplied task list.
// ─────────────────────────────────────────────────────────────────────────────

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
      return Scaffold(
        backgroundColor: const Color(0xFFE0F2FE),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ලබා ගත හැකි කාර්ය නොමැත.',
                style: GoogleFonts.notoSansSinhala(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('ආපසු'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE0F2FE),
      body: Stack(
        children: [
          const _AnimatedBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const Spacer(flex: 1),
                  _buildLevelPill(),
                  const Spacer(flex: 2),
                  _buildSlotsArea(),
                  const Spacer(flex: 2),
                  _buildHint(),
                  const Spacer(flex: 1),
                  _buildWordBank(),
                  const Spacer(flex: 2),
                  Center(
                    child: _CheckButton(
                      onTap: _isAllFilled ? _checkAnswer : null,
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
          // Info panel
          if (_isInfoOpen) Positioned(top: 90, right: 24, child: _InfoPanel()),
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
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF475569),
          ),
          onPressed: () => Navigator.pop(context, false),
        ),
        if (_retryCount > 0)
          Text(
            'නැවත: $_retryCount',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
              fontSize: 14,
            ),
          ),
        _InfoToggle(
          isOpen: _isInfoOpen,
          onToggle: () => setState(() => _isInfoOpen = !_isInfoOpen),
        ),
      ],
    );
  }

  Widget _buildLevelPill() {
    final task = _rounds[_currentRoundIndex]['task'] as GrammarTask;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withOpacity(0.6)),
        ),
        child: Text(
          task.taskName,
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF0284C7),
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSlotsArea() {
    return Expanded(
      flex: 10,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < _droppedWords.length; i++) ...[
              _buildSlot(i),
              if (i < _droppedWords.length - 1) const SizedBox(width: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSlot(int index) {
    final String? content = _droppedWords[index];
    final fixedIndex = _rounds[_currentRoundIndex]['fixedIndex'] as int;
    final bool isFixed = (index == fixedIndex);

    return SizedBox(
      width: 180,
      height: 180,
      child: isFixed
          ? _buildFixedSlot(content)
          : _buildDropTarget(index, content),
    );
  }

  Widget _buildFixedSlot(String? content) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF38BDF8),
        borderRadius: BorderRadius.circular(56),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF0284C7), width: 6),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withOpacity(0.35),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        content ?? '',
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 30,
          fontWeight: FontWeight.w900,
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
                borderRadius: BorderRadius.circular(56),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFCBD5E1), width: 6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                content,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E293B),
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
                ? const Color(0xFF38BDF8).withOpacity(0.15)
                : const Color(0xFFF0F9FF).withOpacity(0.5),
            borderRadius: BorderRadius.circular(56),
            border: Border.all(
              color: isHovered
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFBAE6FD).withOpacity(0.6),
              width: 3,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.add_circle_outline_rounded,
            size: 56,
            color: const Color(0xFFBAE6FD).withOpacity(isHovered ? 1 : 0.5),
          ),
        );
      },
    );
  }

  Widget _buildHint() {
    return Center(
      child: Text(
        'නිවැරදි වචන ඇදගෙන ස්ලොට් තුළ දමන්න',
        style: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF94A3B8),
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 2.5,
        ),
      ),
    );
  }

  Widget _buildWordBank() {
    return Expanded(
      flex: 8,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Wrap(
          spacing: 20,
          runSpacing: 20,
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
        ),
      ),
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
        duration: const Duration(milliseconds: 180),
        width: 152,
        height: 112,
        padding: const EdgeInsets.all(12),
        transform: Matrix4.translationValues(0, active ? -6 : 0, 0),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0EA5E9) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(active ? 0.15 : 0.07),
              blurRadius: active ? 20 : 10,
              offset: Offset(0, active ? 10 : 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          widget.word,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: active ? Colors.white : const Color(0xFF1E293B),
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
        opacity: enabled ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 22),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(100),
              border: const Border(
                bottom: BorderSide(color: Color(0xFF334155), width: 6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'වාක්‍යය පරීක්ෂා කරන්න',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF38BDF8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 22,
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
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isOpen
              ? const Color(0xFF0EA5E9)
              : Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 10),
          ],
        ),
        child: Icon(
          isOpen ? Icons.close_rounded : Icons.info_outline_rounded,
          color: isOpen ? Colors.white : const Color(0xFF475569),
          size: 26,
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
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.45),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ව්‍යාකරණ ගොඩනැගීම',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'වාක්‍යය නිවැරදිව සම්පූර්ණ කිරීමට වචන ඇදගෙන ස්ලොට් තුළ දමන්න. '
                'නිල් ස්ලොටය ඉඟිය ලෙස ලබා දී ඇත.',
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 14,
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

class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with TickerProviderStateMixin {
  late final AnimationController _c1, _c2;
  late final Animation<double> _a1, _a2;

  @override
  void initState() {
    super.initState();
    _c1 = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _c2 = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _a1 = Tween<double>(
      begin: 0,
      end: 20,
    ).animate(CurvedAnimation(parent: _c1, curve: Curves.easeInOut));
    _a2 = Tween<double>(
      begin: 0,
      end: -28,
    ).animate(CurvedAnimation(parent: _c2, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c1.dispose();
    _c2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
              ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _a1,
          builder: (_, __) => Positioned(
            top: -100 + _a1.value,
            left: -50,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                color: const Color(0xFFBAE6FD).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _a2,
          builder: (_, __) => Positioned(
            bottom: -100 + _a2.value,
            right: -50,
            child: Container(
              width: 460,
              height: 460,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE).withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
