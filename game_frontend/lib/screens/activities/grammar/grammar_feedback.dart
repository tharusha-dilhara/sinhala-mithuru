import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Feedback overlay shown after the student submits a grammar answer.
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
    final Color primaryColor = isSuccess
        ? const Color(0xFF16A34A)
        : Colors.redAccent;
    final Color bgColor = isSuccess
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFFEBEE);

    return Container(
      color: Colors.black.withOpacity(0.55),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon ───────────────────────────────────────────────
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withOpacity(0.15),
                  ),
                  child: Icon(
                    isSuccess
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: primaryColor,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Title ──────────────────────────────────────────────
                Text(
                  isSuccess ? 'විශිෂ්ටයි! 🎉' : 'නැවත උත්සාහ කරන්න 💪',
                  style: GoogleFonts.notoSansSinhala(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // ── Custom feedback message ────────────────────────────
                if (feedbackMessage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      feedbackMessage!,
                      style: GoogleFonts.notoSansSinhala(
                        fontSize: 15,
                        color: primaryColor.withOpacity(0.85),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 20),

                // ── Correct sentence section ───────────────────────────
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
                const SizedBox(height: 28),

                // ── Buttons ────────────────────────────────────────────
                Row(
                  children: [
                    if (!isSuccess && canRetry)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onTryAgain,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            side: BorderSide(color: primaryColor, width: 2),
                          ),
                          child: Text(
                            'නැවත',
                            style: GoogleFonts.notoSansSinhala(
                              fontSize: 16,
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
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: Text(
                          isSuccess ? 'ඉදිරියට යමු! ➡️' : 'Skip',
                          style: GoogleFonts.notoSansSinhala(
                            fontSize: 16,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ',
          style: GoogleFonts.notoSansSinhala(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            sentence,
            style: GoogleFonts.notoSansSinhala(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
