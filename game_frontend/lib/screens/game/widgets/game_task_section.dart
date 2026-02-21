import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GameTaskSection extends StatelessWidget {
  // Data passed from parent
  final Map<String, dynamic> targets;
  final Map<String, dynamic> remaining;
  final Function(String) onTaskTap;
  final bool isHighlighted; // Add highlight state

  const GameTaskSection({
    super.key,
    required this.targets,
    required this.remaining,
    required this.onTaskTap,
    this.isHighlighted = false, // Default false
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTaskButton("කියවීම", Icons.auto_stories, Colors.blue, "pron"),
          _buildTaskButton("විමසීම", Icons.psychology, Colors.orange, "narr"),
          _buildTaskButton(
            "අක්ෂර",
            Icons.menu_book_rounded,
            Colors.green,
            "gram",
          ),
          _buildTaskButton(
            "ලිවීම",
            Icons.history_edu_rounded,
            Colors.pink,
            "hw",
          ),
        ],
      ),
    );
  }

  Widget _buildTaskButton(
    String title,
    IconData icon,
    Color baseColor,
    String key,
  ) {
    int rem = remaining[key] ?? 0;
    bool isMastered = rem == 0;

    return GestureDetector(
      onTap: isMastered ? null : () => onTaskTap(key),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                tween: Tween(
                  begin: 1.0,
                  end: isHighlighted && !isMastered ? 1.15 : 1.0,
                ),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Transform.rotate(
                      angle: (scale - 1.0) * 0.15, // Softer tilt
                      child: child,
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMastered
                        ? Colors.grey.shade200
                        : baseColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isMastered
                          ? Colors.grey.shade400
                          : (isHighlighted
                                ? Color.lerp(baseColor, Colors.white, 0.5)!
                                : baseColor.withOpacity(0.2)),
                      width: isHighlighted && !isMastered ? 4 : 2,
                    ),
                    boxShadow: isHighlighted && !isMastered
                        ? [
                            // Layer 1: Inner White Glow
                            const BoxShadow(
                              color: Colors.white,
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                            // Layer 2: Saturated Core Glow
                            BoxShadow(
                              color: baseColor.withOpacity(0.6),
                              blurRadius: 20,
                              spreadRadius: 0,
                            ),
                            // Layer 3: Atmospheric Bloom
                            BoxShadow(
                              color: baseColor.withOpacity(0.2),
                              blurRadius: 35,
                              spreadRadius: -2,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    icon,
                    color: isMastered ? Colors.grey : baseColor,
                    size: 28,
                  ),
                ),
              ),
              if (isMastered)
                const Positioned(
                  right: -2,
                  top: -2,
                  child: Icon(Icons.stars, color: Colors.orange, size: 20),
                )
              else if (rem > 0)
                Positioned(
                  right: -3,
                  top: -3,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "$rem",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.notoSansSinhala(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isMastered ? Colors.grey : Colors.brown.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
