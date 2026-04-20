import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/grammar_task.dart';
import 'grammar_game_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GrammarSelectionPage
//   Receives the full list of grammar tasks from game_home_screen and
//   lets the student pick one to play.
// ─────────────────────────────────────────────────────────────────────────────

class GrammarSelectionPage extends StatefulWidget {
  final List<GrammarTask> tasks;
  final int grade;

  const GrammarSelectionPage({super.key, required this.tasks, this.grade = 1});

  @override
  State<GrammarSelectionPage> createState() => _GrammarSelectionPageState();
}

class _GrammarSelectionPageState extends State<GrammarSelectionPage> {
  GrammarTask? _selectedTask;
  bool _isInfoOpen = false;

  Future<void> _onTaskSelected(GrammarTask task) async {
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => GrammarGamePage(task: task, grade: widget.grade),
      ),
    );
    if (!mounted) return;
    if (success == true) {
      Navigator.pop(context, true);
    }
    // On false/null we stay so student picks another task
  }

  @override
  Widget build(BuildContext context) {
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
                  colors: [Color(0xFFE0F2FE), Color(0xFFFDF2F8)],
                ),
              ),
            ),
          ),

          // Decorative blobs
          const _FloatingBlobs(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final useRow = constraints.maxWidth >= 768;

                  return Column(
                    children: [
                      const Spacer(flex: 1),
                      Expanded(
                        flex: 8,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: useRow ? 1200 : 400,
                                minWidth: useRow ? 800 : 300,
                              ),
                              child: useRow
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: widget.tasks
                                          .asMap()
                                          .entries
                                          .map(
                                            (e) => Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                    ),
                                                child: _TaskCard(
                                                  task: e.value,
                                                  label: 'රූපය ${e.key + 1}',
                                                  isSelected:
                                                      _selectedTask?.taskId ==
                                                      e.value.taskId,
                                                  onTap: () => setState(
                                                    () =>
                                                        _selectedTask = e.value,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    )
                                  : Column(
                                      children: widget.tasks
                                          .asMap()
                                          .entries
                                          .map(
                                            (e) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 24,
                                              ),
                                              child: SizedBox(
                                                height: 380,
                                                width: 350,
                                                child: _TaskCard(
                                                  task: e.value,
                                                  label: 'රූපය ${e.key + 1}',
                                                  isSelected:
                                                      _selectedTask?.taskId ==
                                                      e.value.taskId,
                                                  onTap: () => setState(
                                                    () =>
                                                        _selectedTask = e.value,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(flex: 1),
                      _ReadyButton(
                        onPressed: () {
                          if (_selectedTask != null) {
                            _onTaskSelected(_selectedTask!);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('කරුණාකර පළමුව රූපයක් තෝරන්න!'),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ),
          ),

          // Back button (top-left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 24,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF475569),
                  size: 28,
                ),
              ),
            ),
          ),

          // Info button (top-right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _InfoButtonToggle(
                  isOpen: _isInfoOpen,
                  onToggle: () => setState(() => _isInfoOpen = !_isInfoOpen),
                ),
                if (_isInfoOpen)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: _InfoPanel(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _TaskCard
// ─────────────────────────────────────────────────────────────────────────────

class _TaskCard extends StatefulWidget {
  final GrammarTask task;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TaskCard({
    required this.task,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected || _isHovered;
    const accentColor = Color(0xFF0EA5E9);
    const secondaryColor = Color(0xFF38BDF8);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: isActive ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: widget.isSelected
                  ? const Color(0xFFE0F2FE).withOpacity(0.4)
                  : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(48),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(isActive ? 0.3 : 0.1),
                        blurRadius: isActive ? 24 : 8,
                        spreadRadius: isActive ? 4 : 0,
                      ),
                    ],
                    image: widget.task.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(widget.task.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: widget.task.imageUrl == null
                        ? Colors.blue.withOpacity(0.1)
                        : null,
                  ),
                  child: widget.task.imageUrl == null
                      ? const Icon(
                          Icons.image_not_supported,
                          color: Colors.blue,
                          size: 48,
                        )
                      : null,
                ),
                const SizedBox(height: 16),

                // Task name
                Text(
                  widget.task.taskName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.black38,
                  ),
                ),
                const SizedBox(height: 18),

                // Select button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 46,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    gradient: LinearGradient(
                      colors: widget.isSelected
                          ? [Colors.black87, Colors.black]
                          : [secondaryColor, accentColor],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.isSelected ? 'තෝරාගෙන ඇත' : 'තෝරන්න',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
//  Supporting widgets
// ─────────────────────────────────────────────────────────────────────────────

class _FloatingBlobs extends StatefulWidget {
  const _FloatingBlobs();

  @override
  State<_FloatingBlobs> createState() => _FloatingBlobsState();
}

class _FloatingBlobsState extends State<_FloatingBlobs>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl1;
  late final AnimationController _ctrl2;
  late final Animation<double> _anim1;
  late final Animation<double> _anim2;

  @override
  void initState() {
    super.initState();
    _ctrl1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _ctrl2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _anim1 = Tween<double>(
      begin: 0,
      end: 20,
    ).animate(CurvedAnimation(parent: _ctrl1, curve: Curves.easeInOut));
    _anim2 = Tween<double>(
      begin: 0,
      end: -30,
    ).animate(CurvedAnimation(parent: _ctrl2, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl1.dispose();
    _ctrl2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _anim1,
          builder: (_, __) => Positioned(
            top: -100 + _anim1.value,
            left: -50,
            child: Container(
              width: 384,
              height: 384,
              decoration: BoxDecoration(
                color: Colors.lightBlue[200]!.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _anim2,
          builder: (_, __) => Positioned(
            bottom: -100 + _anim2.value,
            right: -50,
            child: Container(
              width: 480,
              height: 480,
              decoration: BoxDecoration(
                color: Colors.pink[200]!.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoButtonToggle extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  const _InfoButtonToggle({required this.isOpen, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12),
          ],
        ),
        child: Icon(
          isOpen ? Icons.close : Icons.info_outline,
          color: const Color(0xFF475569),
          size: 28,
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 16)],
      ),
      child: Text(
        'ඔබගේ ගමන ආරම්භ කිරීමට රූපයක් තෝරා "සෙල්ලම් කරමු!" ක්ලික් කරන්න.',
        style: GoogleFonts.notoSansSinhala(fontSize: 14, height: 1.6),
      ),
    );
  }
}

class _ReadyButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _ReadyButton({required this.onPressed});

  @override
  State<_ReadyButton> createState() => _ReadyButtonState();
}

class _ReadyButtonState extends State<_ReadyButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'සෙල්ලම් කරමු!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
