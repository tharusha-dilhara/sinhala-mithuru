import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GameTopBar extends StatelessWidget {
  final int currentLevel;
  final double levelProgress;
  final bool isSoundOn;
  final VoidCallback onToggleSound;
  final VoidCallback onSettingsTap;
  final VoidCallback onProfileTap; // Add this
  final VoidCallback onLogoutTap;
  final bool isSmallScreen;

  const GameTopBar({
    super.key,
    required this.currentLevel,
    required this.levelProgress,
    required this.isSoundOn,
    required this.onToggleSound,
    required this.onSettingsTap,
    required this.onProfileTap, // Add this
    required this.onLogoutTap,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Level Indicator Box (Left)
          GestureDetector(onTap: onProfileTap, child: _buildLevelBox()),

          // Action Buttons (Right)
          Row(
            children: [
              _buildRoundIconButton(
                isSoundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                isSoundOn ? const Color(0xFF4FC3F7) : Colors.grey.shade400,
                onTap: onToggleSound,
              ),
              const SizedBox(width: 12),
              _buildRoundIconButton(
                Icons.settings_rounded,
                const Color(0xFFF06292), // Playful Pink
                onTap: onSettingsTap,
              ),
              const SizedBox(width: 12),
              _buildRoundIconButton(
                Icons.logout_rounded,
                const Color(0xFFFF8A65), // Warm Orange
                onTap: onLogoutTap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBox() {
    final double barHeight = isSmallScreen ? 10.0 : 12.0;
    final double pctFontSize = isSmallScreen ? 10.0 : 12.0;
    final double levelFontSize = isSmallScreen ? 14.0 : 16.0;

    return SizedBox(
      width: isSmallScreen ? 160 : 200,
      height: 62,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          // 1. Background "Pill" with Glossy/3D Effect
          Positioned(
            left: 20,
            right: 0,
            child: Container(
              height: 56,
              padding: const EdgeInsets.only(
                left: 38,
                right: 10,
                top: 5,
                bottom: 5,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF29B6F6),
                    Color(0xFF0277BD),
                  ], // High-contrast blue
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white, width: 3.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Top Shine Layer
                  Positioned(
                    top: 2,
                    left: 5,
                    right: 5,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          "මට්ටම $currentLevel",
                          style: GoogleFonts.notoSansSinhala(
                            fontSize: levelFontSize,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: 0.3,
                            shadows: [
                              const Shadow(
                                color: Color(0xFF01579B),
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Percentage label + bar row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Chunky Gradient Progress Bar
                          Expanded(
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                // Track
                                Container(
                                  height: barHeight,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                // Fill
                                FractionallySizedBox(
                                  widthFactor: levelProgress.clamp(0.0, 1.0),
                                  child: Container(
                                    height: barHeight,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFFEE58),
                                          Color(0xFFFFA726),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.6),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        // Shine on fill
                                        Positioned(
                                          top: 1,
                                          left: 4,
                                          right: 4,
                                          child: Container(
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.4,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Percentage badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              "${(levelProgress * 100).toInt()}%",
                              style: GoogleFonts.nunito(
                                fontSize: isSmallScreen ? 12 : 13,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFE65100),
                                height: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. Giant Level Star Medal
          Positioned(
            left: 0,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD54F),
                border: Border.all(color: Colors.white, width: 3.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(2, 4),
                  ),
                ],
                gradient: const RadialGradient(
                  colors: [Color(0xFFFFEA00), Color(0xFFFF8F00)],
                  center: Alignment(-0.2, -0.2),
                  radius: 0.9,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.star_rounded,
                  color: Colors.white,
                  size: 44,
                  shadows: [
                    Shadow(
                      color: Color(0xFFBF3600),
                      offset: Offset(0, 3),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundIconButton(
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    final double size = isSmallScreen ? 46 : 52;
    final double iconSize = isSmallScreen ? 24 : 28;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            // Bottom "3D" edge
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Top highlight for glossy look
            Positioned(
              top: 4,
              child: Container(
                width: size * 0.6,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Icon(
              icon,
              color: Colors.white,
              size: iconSize,
              shadows: const [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 2,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
