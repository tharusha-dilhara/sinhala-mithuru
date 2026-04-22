import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Feedback overlay shown after the student submits a grammar answer.
/// Styled to match the purple grammar theme consistent with other activities.

const Color _kGrammarColor = Color(0xFF7C3AED);

class GrammarFeedbackLayout extends StatelessWidget {
  final bool isSuccess;
  final String sinhalaSentence;
  final String userAnswer;
  final String englishSentence;
  final String? feedbackMessage;
  final bool canRetry;
  final VoidCallback onTryAgain;
  final VoidCallback onContinue;

  const GrammarFeedbackLayout({
    super.key,
    required this.isSuccess,
    required this.sinhalaSentence,
    required this.userAnswer,
    required this.englishSentence,
    this.feedbackMessage,
    this.canRetry = true,
    required this.onTryAgain,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor =
        isSuccess ? const Color(0xFF16A34A) : Colors.redAccent;
    final Color bgColor =
        isSuccess ? const Color(0xFFDCFCE7) : const Color(0xFFFFEBEE);

    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: primaryColor.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.25),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon ──────────────────────────────────────────────────
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withOpacity(0.15),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isSuccess
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: primaryColor,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 18),

                // ── Title ──────────────────────────────────────────────────
                Text(
                  isSuccess ? 'විශිෂ්ටයි! 🎉' : 'නැවත උත්සාහ කරන්න 💪',
                  style: GoogleFonts.notoSansSinhala(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // ── Custom feedback message ────────────────────────────────
                if (feedbackMessage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      feedbackMessage!,
                      style: GoogleFonts.notoSansSinhala(
                        fontSize: 14,
                        color: primaryColor.withOpacity(0.85),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 18),

                // ── Correct sentence section ───────────────────────────────
                _SentenceRow(
                  label: 'නිවැරදි වාක්‍ය:',
                  sentence: sinhalaSentence,
                  color: const Color(0xFF16A34A),
                ),
                const SizedBox(height: 8),
                if (!isSuccess)
                  _SentenceRow(
                    label: 'ඔබගේ පිළිතුර:',
                    sentence: userAnswer,
                    color: Colors.redAccent,
                  ),
                const SizedBox(height: 24),

                // ── Buttons ────────────────────────────────────────────────
                Row(
                  children: [
                    if (!isSuccess && canRetry)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onTryAgain,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            side: BorderSide(color: primaryColor, width: 2),
                          ),
                          child: Text(
                            'නැවත',
                            style: GoogleFonts.notoSansSinhala(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                    if (!isSuccess && canRetry) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSuccess
                              ? _kGrammarColor
                              : primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          elevation: 3,
                          shadowColor: (isSuccess ? _kGrammarColor : primaryColor)
                              .withOpacity(0.35),
                        ),
                        child: Text(
                          isSuccess ? 'ඉදිරියට යමු! ➡️' : 'Skip',
                          style: GoogleFonts.notoSansSinhala(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SentenceRow extends StatelessWidget {
  final String label;
  final String sentence;
  final Color color;

  const _SentenceRow({
    required this.label,
    required this.sentence,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: GoogleFonts.notoSansSinhala(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              sentence,
              style: GoogleFonts.notoSansSinhala(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
