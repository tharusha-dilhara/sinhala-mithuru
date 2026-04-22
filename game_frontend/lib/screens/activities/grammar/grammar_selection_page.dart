import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/grammar_task.dart';
import '../activity_layout.dart';
import 'grammar_game_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GrammarSelectionPage
//   Receives the full list of grammar tasks from game_home_screen and
//   lets the student pick one to play.
// ─────────────────────────────────────────────────────────────────────────────

const Color _kGrammarColor = Color(0xFF7C3AED); // Purple — grammar theme

class GrammarSelectionPage extends StatefulWidget {
  final List<GrammarTask> tasks;
  final int grade;

  const GrammarSelectionPage({super.key, required this.tasks, this.grade = 1});

  @override
  State<GrammarSelectionPage> createState() => _GrammarSelectionPageState();
}

class _GrammarSelectionPageState extends State<GrammarSelectionPage> {
  GrammarTask? _selectedTask;

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
    return ActivityLayout(
      headerText: 'සිංහල මිතුරු - ව්‍යාකරණ',
      title: 'රූපයක් තෝරන්න',
      baseColor: _kGrammarColor,
      maxWidth: 1200,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 24,
              runSpacing: 24,
              children: widget.tasks
                  .asMap()
                  .entries
                  .map(
                    (e) => SizedBox(
                      width: 260,
                      child: _TaskCard(
                        task: e.value,
                        label: 'රූපය ${e.key + 1}',
                        isSelected: _selectedTask?.taskId == e.value.taskId,
                        onTap: () => setState(() => _selectedTask = e.value),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 40),
            _ReadyButton(
              onPressed: () {
                if (_selectedTask != null) {
                  _onTaskSelected(_selectedTask!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'කරුණාකර පළමුව රූපයක් තෝරන්න!',
                        style: GoogleFonts.notoSansSinhala(),
                      ),
                      backgroundColor: _kGrammarColor,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
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

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: isActive ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: widget.isSelected
                  ? _kGrammarColor.withOpacity(0.08)
                  : Colors.white.withOpacity(0.85),
              border: Border.all(
                color: widget.isSelected
                    ? _kGrammarColor
                    : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isActive
                      ? _kGrammarColor.withOpacity(0.18)
                      : Colors.black.withOpacity(0.08),
                  blurRadius: isActive ? 24 : 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: isActive
                          ? _kGrammarColor.withOpacity(0.4)
                          : Colors.grey.shade200,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kGrammarColor.withOpacity(isActive ? 0.2 : 0.05),
                        blurRadius: isActive ? 20 : 6,
                        spreadRadius: isActive ? 2 : 0,
                      ),
                    ],
                  ),
                  child: widget.task.imageUrl == null
                        ? Icon(
                            Icons.image_not_supported,
                            color: _kGrammarColor.withOpacity(0.6),
                            size: 40,
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(33),
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
                ),
                const SizedBox(height: 12),

                // Task name
                Text(
                  widget.task.taskName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansSinhala(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansSinhala(
                    fontSize: 12,
                    color: Colors.black38,
                  ),
                ),
                const SizedBox(height: 14),

                // Select button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 42,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    gradient: LinearGradient(
                      colors: widget.isSelected
                          ? [
                              _kGrammarColor.withOpacity(0.8),
                              _kGrammarColor,
                            ]
                          : [
                              _kGrammarColor.withOpacity(0.15),
                              _kGrammarColor.withOpacity(0.25),
                            ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.isSelected ? 'තෝරාගෙන ඇත ✓' : 'තෝරන්න',
                    style: GoogleFonts.notoSansSinhala(
                      color: widget.isSelected ? Colors.white : _kGrammarColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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
//  _ReadyButton
// ─────────────────────────────────────────────────────────────────────────────

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
          scale: _isHovered ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _kGrammarColor,
                  _kGrammarColor.withOpacity(0.75),
                ],
              ),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: _kGrammarColor.withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'සෙල්ලම් කරමු!',
                  style: GoogleFonts.notoSansSinhala(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
