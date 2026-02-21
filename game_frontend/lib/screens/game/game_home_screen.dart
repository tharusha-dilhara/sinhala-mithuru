import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rive/rive.dart' hide Image;
import 'package:audioplayers/audioplayers.dart';
import 'dart:ui'; // Blur effect සඳහා

import '../../services/game_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_option_screen.dart';
import '../activities/reading_screen.dart';
import '../activities/asking_screen.dart';
import '../activities/letters_screen.dart';
import '../activities/writing_screen.dart';
import '../../models/game_item.dart';
import 'widgets/reward_panel.dart';
import 'settings_screen.dart';
import 'profile_screen.dart'; // Add this

// --- අලුතින් සාදන ලද Widgets import කිරීම ---
import 'widgets/game_top_bar.dart';
import 'widgets/game_task_section.dart';
import 'widgets/game_dialogs.dart';
import 'widgets/loading_overlay.dart';

class GameHomeScreen extends StatefulWidget {
  const GameHomeScreen({super.key});

  @override
  State<GameHomeScreen> createState() => _GameHomeScreenState();
}

class _GameHomeScreenState extends State<GameHomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final _gameService = GameService();
  final _authService = AuthService();

  // --- Rive config (සජීවිකරණ සැකසුම්) ---
  static const String _riveAsset = 'assets/anims/puppy.riv';
  static const String _stateMachineName = 'State Machine 1';
  static const String _levelInputName = 'level';

  // --- Background Image ---
  static const String _bgImage = 'assets/images/background1.png';

  final AudioPlayer _bgMusicPlayer = AudioPlayer();
  StateMachineController? _smController;
  SMINumber? _levelInput;

  // --- App state (යෙදුමේ තත්වය) ---
  bool _isLoading = true;
  bool _isSoundOn = true;
  bool _isFirstLoad = true; // Level up පරීක්ෂා කිරීමට
  int _currentLevel = 1;
  double _levelProgress = 0.0;
  bool _highlightTasks = false; // Task highlight state

  Map<String, dynamic> _remaining = {};
  Map<String, dynamic> _targets = {};
  // ... (skip down) ...
  void _triggerTaskHighlight() {
    setState(() {
      _highlightTasks = true;
      _message = "කිරි බෝතලය ලබා ගැනීමට පළමුව පැවරුම් සම්පූර්ණ කරන්න!";
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _highlightTasks = false;
        });
      }
    });
  }

  Map<String, dynamic> _state = {};
  Map<String, dynamic> _levelAssets = {};

  String _message = "බලු පැටියා බලාගෙන ඉන්නවා...";
  String _error = "";
  double? _pendingLevel;

  // --- Rewards (ත්‍යාග) ---
  final List<GameItem> _rewardItems = [
    const GameItem(
      id: '1',
      name: 'Milk',
      imagePath: 'assets/images/milk_bottle.png',
      type: GameItemType.food,
      count: 2,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAudio();
    _loadGameData();
  }

  // --- ශ්‍රව්‍ය පද්ධතිය සැකසීම ---
  void _initAudio() async {
    try {
      await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
      if (_isSoundOn) {
        await _bgMusicPlayer.play(
          AssetSource('audio/bg_music.mp3'),
          volume: 0.3,
        );
      }
    } catch (e) {
      debugPrint("Audio init error: $e");
    }
  }

  void _toggleSound() async {
    setState(() {
      _isSoundOn = !_isSoundOn;
    });
    if (_isSoundOn) {
      await _bgMusicPlayer.resume();
    } else {
      await _bgMusicPlayer.pause();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _bgMusicPlayer.pause();
    } else if (state == AppLifecycleState.resumed) {
      _bgMusicPlayer.resume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgMusicPlayer.dispose();
    _smController?.dispose();
    super.dispose();
  }

  // --- ක්‍රීඩා දත්ත ලබා ගැනීම ---
  Future<void> _loadGameData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // API එකෙන් දත්ත ලබා ගැනීම
      final data = await _gameService.getNextTask();

      if (!mounted) return;

      final incomingState = data['state'] ?? {};

      // FIX: Use level_info.level_number if available, otherwise fallback to state.current_level_id
      // The API returns 'level_info': {'level_number': X, ...}
      final levelInfo = data['level_info'] ?? {};
      final incomingLevel =
          (levelInfo['level_number'] ?? incomingState['current_level_id'] ?? 1)
              as int;

      final isGameCompleted = data['task_type'] == 'game_completed';

      // 1. Level Up එකක් සිදුවී ඇත්දැයි බැලීම
      bool didLevelUp = !_isFirstLoad && incomingLevel > _currentLevel;
      bool didComplete = !_isFirstLoad && isGameCompleted;

      setState(() {
        _state = incomingState;
        _targets = data['targets'] ?? {};
        _remaining = data['remaining'] ?? {};
        _levelAssets = data['level_assets'] ?? {};
        _currentLevel = incomingLevel;
        _isLoading = false;
        _error = "";

        _calculateProgress();

        if (isGameCompleted) {
          _message = "නියමයි! සියලුම අභ්‍යාස අවසන්!";
          _setLevel(3.0); // Happy puppy
        } else {
          _syncPuppyWithGameLevel();
        }

        _isFirstLoad = false;
      });

      // 2. State අප්ඩේට් වූ පසු සජීවීකරණය සහිත Popup එක පෙන්වීම
      if (didComplete) {
        _showGameCompletedDialog();
      } else if (didLevelUp) {
        _showLevelUpDialog(incomingLevel);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // --- Level Up Dialog පෙන්වීම (Refactored) ---
  void _showLevelUpDialog(int newLevel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LevelUpDialog(
          newLevel: newLevel,
          onContinue: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  // --- Game Completed Dialog පෙන්වීම (Refactored) ---
  void _showGameCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return GameCompletedDialog(
          onContinue: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  // --- ප්‍රගතිය ගණනය කිරීම ---
  void _calculateProgress() {
    if (_targets.isEmpty) return;
    int totalTarget = _targets.values.fold(0, (sum, val) => sum + (val as int));
    int totalRemaining = _remaining.values.fold(
      0,
      (sum, val) => sum + (val as int),
    );
    if (totalTarget > 0) {
      _levelProgress =
          (totalTarget - totalRemaining) / totalTarget; // Level bar එක සඳහා
    }
  }

  // --- Game Level එක Rive Level එකට සෘජුවම සම්බන්ධ කිරීම ---
  void _syncPuppyWithGameLevel() {
    _message = "අපි දැන් ඉන්නේ මට්ටම $_currentLevel හි!";
    _setLevel(
      _currentLevel.toDouble(),
    ); // Game level 1 නම් Rive 1, level 2 නම් Rive 2...
  }

  void _setLevel(double value) {
    if (_levelInput == null) {
      _pendingLevel = value;
      return;
    }
    _levelInput!.value = value;
  }

  // --- Rive Animation Setup ---
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
      final v = _pendingLevel ?? _currentLevel.toDouble();
      _pendingLevel = null;
      _setLevel(v);
    });
  }

  Future<void> _logout() async {
    _bgMusicPlayer.stop();
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginOptionScreen()),
      (route) => false,
    );
  }

  // --- සැකසුම් තිරයට යාම ---
  void _openSettings() {
    _navigateToActivity(
      SettingsScreen(
        initialSoundState: _isSoundOn,
        onSoundToggle: (value) {
          if (value != _isSoundOn) _toggleSound();
        },
      ),
    );
  }

  // --- කාර්යක්ෂම Navigation ශ්‍රිතය ---
  void _startTask(String componentKey) async {
    String assetKey = "";
    if (componentKey == 'pron') {
      assetKey = 'pronunciation';
    } else if (componentKey == 'hw') {
      assetKey = 'handwriting';
    } else if (componentKey == 'gram') {
      assetKey = 'grammar';
    } else if (componentKey == 'narr') {
      assetKey = 'narrative';
    }

    final List assets = _levelAssets[assetKey] ?? [];

    if (assets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("මෙම අංශයේ වැඩ දැනට අවසන්!")),
      );
      return;
    }

    final taskData = assets[0];

    Widget targetScreen;
    if (componentKey == 'pron') {
      targetScreen = ReadingScreen(taskData: taskData);
    } else if (componentKey == 'hw') {
      targetScreen = WritingScreen(taskData: taskData);
    } else if (componentKey == 'gram') {
      targetScreen = LettersScreen(taskData: taskData);
    } else {
      targetScreen = AskingScreen(taskData: taskData);
    }

    await _bgMusicPlayer.pause();
    if (_smController != null) _smController!.isActive = false;

    if (!mounted) return;

    // මෙහිදී Navigator එකෙන් එන ප්‍රතිඵලය ලබා ගනී
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    );

    // සාර්ථකව අභ්‍යාසය අවසන් කළේ නම් පමණක් API එක Call කරයි
    if (result == true) {
      _loadGameData();
    }

    if (_smController != null) _smController!.isActive = true;
    if (_isSoundOn && mounted) await _bgMusicPlayer.resume();
  }

  void _navigateToActivity(Widget screen) async {
    await _bgMusicPlayer.pause();
    if (_smController != null) _smController!.isActive = false;

    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

    if (_smController != null) _smController!.isActive = true;
    if (_isSoundOn && mounted) await _bgMusicPlayer.resume();
  }

  void _openProfile() {
    _navigateToActivity(const ProfileScreen());
  }

  bool get _isAllTasksCompleted {
    if (_remaining.isEmpty) return false;
    return _remaining.values.every((v) => v == 0);
  }

  // --- Main Build Method (ප්‍රධාන දර්ශනය) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBE8D3),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          final topPadding = MediaQuery.of(context).padding.top;

          return Stack(
            children: [
              // 1. පසුබිම (Background)
              Positioned.fill(
                child: Image.asset(
                  _bgImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: const Color(0xFFFBE8D3)),
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

              // 3. Rewards Panel
              // 4. ප්‍රධාන අතුරුමුහුණත (Top Bar සහ Task Buttons)
              SafeArea(
                child: Column(
                  children: [
                    // Top Bar (Level indicator, Settings, Audio, Logout)
                    GameTopBar(
                      currentLevel: _currentLevel,
                      levelProgress: _levelProgress,
                      isSoundOn: _isSoundOn,
                      onToggleSound: _toggleSound,
                      onSettingsTap: _openSettings,
                      onProfileTap: _openProfile, // Add this
                      onLogoutTap: _logout,
                      isSmallScreen: isSmallScreen,
                    ),

                    const SizedBox(height: 10),

                    // Task Select Buttons (කියවීම, ලිවීම, etc.)
                    GameTaskSection(
                      targets: _targets,
                      remaining: _remaining,
                      onTaskTap: _startTask,
                      isHighlighted: _highlightTasks,
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20, top: 10),
                        child: RewardPanel(
                          items: _rewardItems,
                          isCompact: true,
                          onTap: _triggerTaskHighlight,
                          isLocked: !_isAllTasksCompleted,
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

              // 5. Loading Overlay (දත්ත එනතුරු පෙන්වන කොටස)
              if (_isLoading) const LoadingOverlay(),

              // 6. Error Overlay (දෝෂයක් ආවොත් පෙන්වන කොටස)
              if (_error.isNotEmpty) _buildErrorOverlay(topPadding),
            ],
          );
        },
      ),
    );
  }

  // --- Message Bubble (පණිවිඩ කොටුව) ---
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

  // --- Error Overlay (දෝෂයක් ආවොත්) ---
  Widget _buildErrorOverlay(double topPadding) {
    return Positioned(
      top: topPadding + 60,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.9),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Error: $_error",
                style: const TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  _error = "";
                  _isLoading = false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
