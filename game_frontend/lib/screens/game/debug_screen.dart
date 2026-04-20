import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rive/rive.dart' hide Image;

import '../../models/game_item.dart';
import 'widgets/game_top_bar.dart';
import 'widgets/game_task_section.dart';
import 'widgets/reward_panel.dart';

class DebugScreen extends StatefulWidget {
  final int currentLevel;

  const DebugScreen({super.key, required this.currentLevel});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen>
    with SingleTickerProviderStateMixin {
  static const String _riveAsset = 'assets/anims/puppy_final_50.riv';
  static const String _stateMachineName = 'State Machine 1';
  static const String _levelInputName = 'level';

  static const int _minLevel = 1;
  static const int _maxLevel = 100;

  late int _previewLevel;

  StateMachineController? _smController;
  SMINumber? _levelInput;

  // --- Background Image ---
  final String _bgImage = 'assets/images/background3.png';

  double _levelProgress = 0.5; // Mock progress

  String _message = "බලු පැටියා බලාගෙන ඉන්නවා... (Debug Mode)";

  // --- Mock Targets ---
  final Map<String, dynamic> _mockTargets = {
    'pron': 2,
    'narr': 1,
    'gram': 3,
    'hw': 1,
  };

  final Map<String, dynamic> _mockRemaining = {
    'pron': 1, // In progress
    'narr': 1, // Not started
    'gram': 0, // Completed
    'hw': 1, // Not started
  };

  // --- Rewards (ත්‍යාග) ---
  final List<GameItem> _rewardItems = [
    const GameItem(
      id: '1',
      name: 'Milk',
      imagePath: 'assets/images/background3.png',
      type: GameItemType.food,
      count: 2,
      requiredLevel: 1,
      unlockMessage: 'කිරි බෝතලය ලබා ගැනීමට 1 මට්ටමේ පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: '',
    ),
    const GameItem(
      id: '2',
      name: 'Medicine',
      imagePath: 'assets/images/medicine.png',
      type: GameItemType.medicine,
      count: 1,
      requiredLevel: 2,
      unlockMessage: 'බෙහෙත් ලබා ගැනීමට 2 මට්ටමේ පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: '',
    ),
    const GameItem(
      id: '3',
      name: 'Toy',
      imagePath: 'assets/images/toy.png',
      type: GameItemType.toy,
      count: 1,
      requiredLevel: 3,
      unlockMessage: 'සෙල්ලම් බඩුව ලබා ගැනීමට 3 මට්ටමේ පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: '',
    ),
    const GameItem(
      id: '4',
      name: 'Milk',
      imagePath: 'assets/images/milk_bottle.png',
      type: GameItemType.food,
      count: 2,
      requiredLevel: 4,
      unlockMessage: 'කිරි බෝතලය ලබා ගැනීමට 4 මට්ටමේ පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: '',
    ),
  ];

  List<GameItem> get _currentRewardList {
    try {
      return [
        _rewardItems.firstWhere((item) => item.requiredLevel == _previewLevel),
      ];
    } catch (e) {
      if (_rewardItems.isNotEmpty) {
        return [_rewardItems.last]; // Fallback if level exceeds rewards
      }
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _previewLevel = widget.currentLevel.clamp(_minLevel, _maxLevel);
  }

  @override
  void dispose() {
    _smController?.dispose();
    super.dispose();
  }

  void _onRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      _stateMachineName,
    );
    if (controller == null) return;
    artboard.addController(controller);
    _smController = controller;
    final level = controller.getNumberInput(_levelInputName);
    if (level == null) return;
    _levelInput = level;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _levelInput!.value = (_previewLevel + 1)
          .toDouble(); // Rive level is game level + 1
    });
  }

  void _changeLevel(int delta) {
    final newLevel = (_previewLevel + delta).clamp(_minLevel, _maxLevel);
    if (newLevel == _previewLevel) return;
    setState(() => _previewLevel = newLevel);
    _levelInput?.value = (newLevel + 1).toDouble();
  }

  void _onMockTaskTap(String taskKey) {
    setState(() {
      _message = "ඇක්ටිවිටි ($taskKey) වැඩ කිරීමට අවශ්‍ය නැත - Debug Mode";
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _message = "බලු පැටියා බලාගෙන ඉන්නවා... (Debug Mode)";
        });
      }
    });
  }

  void _onMockRewardTapped(GameItem item) {
    bool isItemLocked = _previewLevel < item.requiredLevel;

    if (isItemLocked) {
      setState(() {
        _message = item.unlockMessage;
      });
    } else {
      setState(() {
        _message = "ඔබ ${item.name} ලබාගත්තා! (Debug Mode)";
      });
    }

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _message = "බලු පැටියා බලාගෙන ඉන්නවා... (Debug Mode)";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBE8D3),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;

          return Stack(
            children: [
              // 1. පසුබිම (Background)
              Positioned.fill(
                child: Image.asset(
                  _bgImage,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                ),
              ),

              // 2. මැද ඇති Rive Animation (Puppy)
              Positioned(
                bottom: constraints.maxHeight * 0.12,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    height:
                        constraints.maxHeight * (isSmallScreen ? 0.45 : 0.55),
                    width: constraints.maxWidth,
                    child: RiveAnimation.asset(
                      _riveAsset,
                      fit: BoxFit.contain,
                      onInit: _onRiveInit,
                    ),
                  ),
                ),
              ),

              // 3. ප්‍රධාන අතුරුමුහුණත (Top Bar, Task Buttons etc.)
              SafeArea(
                child: Column(
                  children: [
                    // Mock Top Bar
                    GameTopBar(
                      currentLevel: _previewLevel,
                      levelProgress: _levelProgress,
                      isSoundOn: true,
                      onToggleSound: () {
                        setState(() {
                          _message = "Sound toggle (Debug Mode)";
                        });
                      },
                      onSettingsTap: () {
                        setState(() {
                          _message = "Settings tapped (Debug Mode)";
                        });
                      },
                      onProfileTap: () {
                        setState(() {
                          _message = "Profile tapped (Debug Mode)";
                        });
                      },
                      onLogoutTap: () => Navigator.of(
                        context,
                      ).pop(), // Just go back from debug
                      isSmallScreen: isSmallScreen,
                    ),

                    const SizedBox(height: 10),

                    // Mock Task Select Buttons
                    GameTaskSection(
                      targets: _mockTargets,
                      remaining: _mockRemaining,
                      onTaskTap: _onMockTaskTap,
                      isHighlighted: false,
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20, top: 10),
                        child: RewardPanel(
                          items: _currentRewardList,
                          isCompact: true,
                          currentLevel: _previewLevel,
                          isAllTasksCompleted: false, // Force mock locked state
                          onTapItem: _onMockRewardTapped,
                          isHighlighted: false,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // පණිවිඩ කොටුව (Message Bubble)
                    _buildMessageBubble(constraints.maxWidth),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // 4. Debug Level Controls at bottom right
              Positioned(bottom: 20, right: 20, child: _buildDebugControls()),

              // Add a back button overlay since we hijacked the logout button
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 10,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(backgroundColor: Colors.black45),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(double maxWidth) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth * 0.8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(5),
          bottomLeft: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        _message,
        style: GoogleFonts.notoSansSinhala(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.brown.shade800,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDebugControls() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            color: Colors.red,
            onPressed: () => _changeLevel(-1),
          ),
          Text(
            'Lvl $_previewLevel',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: Colors.green,
            onPressed: () => _changeLevel(1),
          ),
        ],
      ),
    );
  }
}
