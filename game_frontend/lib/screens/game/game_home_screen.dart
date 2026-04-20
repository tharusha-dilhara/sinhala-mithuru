import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rive/rive.dart' hide Image;
import 'package:audioplayers/audioplayers.dart';
import 'dart:ui'; // Blur effect සඳහා

import '../../services/game_service.dart';
import '../../services/auth_service.dart';
import '../../services/background_service.dart';
import '../../services/sound_service.dart';
import '../../services/comprehension_service.dart';
import '../auth/login_option_screen.dart';
import '../activities/reading_screen.dart';
import '../activities/asking_screen.dart';
import '../activities/grammar/grammar_selection_page.dart';
import '../activities/grammar/grammar_word_game_page.dart';
import '../activities/writing_screen.dart';
import '../story/story_screen.dart';
import '../../models/game_item.dart';
import '../../models/grammar_task.dart';
import 'widgets/reward_panel.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';

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
  final _comprehensionService = ComprehensionService();

  // --- Rive config (සජීවිකරණ සැකසුම්) ---
  static const String _riveAsset = 'assets/anims/puppy_final_50.riv';
  static const String _stateMachineName = 'State Machine 1';
  static const String _levelInputName = 'level';

  // --- Background Image ---
  String _bgImage = 'assets/images/background1.png';

  final _soundService = SoundService();
  StateMachineController? _smController;
  SMINumber? _levelInput;

  // --- App state (යෙදුමේ තත්වය) ---
  bool _isLoading = true;
  bool _isFirstLoad = true; // Level up පරීක්ෂා කිරීමට
  bool _isVoicePlaying = false;
  int _currentLevel = 1;
  int _riveLevel = 2; // Rive animation level (starts at 2. Need=2N, Happy=2N+1)
  double _levelProgress = 0.0;
  bool _highlightTasks = false; // Task highlight state
  bool _highlightReward = false; // Reward highlight state

  Map<String, dynamic> _remaining = {};
  Map<String, dynamic> _targets = {};
  // ... (skip down) ...
  // (Removed _triggerTaskHighlight as it's replaced by _onRewardTapped)

  Map<String, dynamic> _state = {};
  Map<String, dynamic> _levelAssets = {};
  Map<String, dynamic> _levelInfo = {};

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
      count: 1,
      requiredLevel: 1,
      unlockMessage: 'කිරි බෝතලය ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/01_kiribothalaya.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '2',
      name: 'Medicine',
      imagePath:
          'assets/images/shampo.png', // Assuming you have this image or similar
      type: GameItemType.medicine,
      count: 1,
      requiredLevel: 2,
      unlockMessage: 'ෂැම්පො බෝතලය ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/02_mada_gagena.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '3',
      name: 'Toy',
      imagePath:
          'assets/images/beheth.png', // Assuming you have this image or similar
      type: GameItemType.medicine,
      count: 1,
      requiredLevel: 3,
      unlockMessage: 'බෙහෙත් ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/03_beheth_peththa.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '4',
      name: 'Milk',
      imagePath: 'assets/images/bolayak.png',
      type: GameItemType.toy,
      count: 1,
      requiredLevel: 4,
      unlockMessage: 'බෝලය ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/04_bolayak.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '5',
      name: 'Milk',
      imagePath: 'assets/images/wathura.png',
      type: GameItemType.food,
      count: 1,
      requiredLevel: 5,
      unlockMessage: 'වතුර එක ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/05_karakewilla.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '6',
      name: 'Milk',
      imagePath: 'assets/images/plasta.png',
      type: GameItemType.food,
      count: 1,
      requiredLevel: 6,
      unlockMessage: 'ප්ලාස්ට එක ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/06_thuwala_wela.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '7',
      name: 'Milk',
      imagePath: 'assets/images/beheth.png',
      type: GameItemType.medicine,
      count: 1,
      requiredLevel: 7,
      unlockMessage: 'බෙහෙත් එක ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/07_kinithullo.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '8',
      name: 'Milk',
      imagePath: 'assets/images/f1.png',
      type: GameItemType.food,
      count: 1,
      requiredLevel: 8,
      unlockMessage: 'මල් පෝච්චිය ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/08_flower_01.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '9',
      name: 'Milk',
      imagePath: 'assets/images/f2.png',
      type: GameItemType.food,
      count: 1,
      requiredLevel: 9,
      unlockMessage: 'පැලයක් ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/09_flower_02.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '10',
      name: 'Milk',
      imagePath: 'assets/images/f3.png',
      type: GameItemType.food,
      count: 1,
      requiredLevel: 10,
      unlockMessage: 'පැලය වර්දනය කිරීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/10_flower_03.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '11',
      name: 'Milk',
      imagePath: 'assets/images/wathura_pochchiya.png',
      type: GameItemType.food,
      count: 1,
      requiredLevel: 11,
      unlockMessage: 'වතුර පෝච්චිය ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/11_flower_04.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '12',
      name: 'Milk',
      imagePath: 'assets/images/h1.png',
      type: GameItemType.food,
      count: 1,
      requiredLevel: 12,
      unlockMessage: 'බ්ලොග් කැබැල්ල ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/12_home_01.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '13',
      name: 'Milk',
      imagePath: 'assets/images/h2.png',
      type: GameItemType.food,
      count: 1,
      requiredLevel: 13,
      unlockMessage: 'බ්ලොග් කැබලි ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/13_home_02.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '14',
      name: 'Milk',
      imagePath: 'assets/images/h3.png',
      type: GameItemType.food,
      count: 1,
      requiredLevel: 14,
      unlockMessage: 'බ්ලොග් කැබලි ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/14_home_03.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '15',
      name: 'Milk',
      imagePath: 'assets/images/h4.png',
      type: GameItemType.food,
      count: 1,
      requiredLevel: 15,
      unlockMessage: 'බ්ලොග් කැබලි ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/15_home_04.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '16',
      name: 'Milk',
      imagePath: 'assets/images/h5.png',
      type: GameItemType.food,
      count: 1,
      requiredLevel: 16,
      unlockMessage: 'බ්ලොග් කැබලි ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/16_home_05.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '17',
      name: 'Milk',
      imagePath: 'assets/images/h6.png',
      type: GameItemType.food,
      count: 1,
      requiredLevel: 17,
      unlockMessage: 'බ්ලොග් කැබලි ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/17_home_06.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '18',
      name: 'Milk',
      imagePath: 'assets/images/h7.png',
      type: GameItemType.food,
      count: 1,
      requiredLevel: 18,
      unlockMessage: 'බ්ලොග් කැබලි ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/18_home_07.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '19',
      name: 'Milk',
      imagePath: 'assets/images/rathu_toppiya.png',
      type: GameItemType.food,
      count: 1,
      requiredLevel: 19,
      unlockMessage: 'රතු තොප්පිය ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/19_redhut.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '20',
      name: 'Milk',
      imagePath: 'assets/images/gaganagamiya.png',
      type: GameItemType.food,
      count: 1,
      requiredLevel: 20,
      unlockMessage: 'ගගනගාමී ඇදුම ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/20_gaganagami.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '21',
      name: 'Milk',
      imagePath: 'assets/images/aduma.png',
      type: GameItemType.food,
      count: 1,
      requiredLevel: 21,
      unlockMessage: 'ඇදුම ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/21_adumak.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '22',
      name: 'Milk',
      imagePath: 'assets/images/fi1.png',
      type: GameItemType.food,
      count: 1,
      requiredLevel: 22,
      unlockMessage: 'මාලු ටැංකිය ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/22_fish_01.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '23',
      name: 'Milk',
      imagePath: 'assets/images/fi2.png',
      type: GameItemType.food,
      count: 1,
      requiredLevel: 23,
      unlockMessage: 'මාලු ටැංකියට වතුර ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/23_fish_02.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '24',
      name: 'Milk',
      imagePath: 'assets/images/fi4.png',
      type: GameItemType.food,
      count: 1,
      requiredLevel: 24,
      unlockMessage: 'මාලු ටැංකියට ගල් මල් ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/24_fish_03.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '25',
      name: 'Milk',
      imagePath: 'assets/images/fi5.png',
      type: GameItemType.food,
      count: 1,
      requiredLevel: 25,
      unlockMessage: 'ඔක්සිජන් ෆිල්ටරයක් ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/25_fish_04.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '26',
      name: 'Milk',
      imagePath: 'assets/images/fi6.png',
      type: GameItemType.food,
      count: 1,
      requiredLevel: 26,
      unlockMessage: 'තැඹිලි පාට මාලුවා ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/26_fish_05.mp3', // TODO: Add actual audio
    ),
    const GameItem(
      id: '27',
      name: 'Milk',
      imagePath: 'assets/images/fi7.png',
      type: GameItemType.food,
      count: 1,
      requiredLevel: 27,
      unlockMessage: 'නිල් පාට මාලුවා ලබා ගැනීමට පැවරුම් සම්පූර්ණ කරන්න!',
      audioPath: 'audio/27_fish_06.mp3', // TODO: Add actual audio
    ),
  ];

  List<GameItem> get _currentRewardList {
    try {
      return [
        _rewardItems.firstWhere((item) => item.requiredLevel == _currentLevel),
      ];
    } catch (e) {
      if (_rewardItems.isNotEmpty) {
        return [_rewardItems.last]; // Fallback if level exceeds rewards
      }
      return [];
    }
  }

  void _onRewardTapped(GameItem item) {
    bool isItemLocked =
        _currentLevel < item.requiredLevel ||
        (_currentLevel == item.requiredLevel && !_isAllTasksCompleted);

    if (isItemLocked) {
      setState(() {
        _message = item.unlockMessage;
      });
      // Clear message after a while
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _message == item.unlockMessage) {
          setState(() {
            _message = "බලු පැටියා බලාගෙන ඉන්නවා...";
          });
        }
      });
    } else {
      // Optional: Add logic for claiming an unlocked reward here
      setState(() {
        _message = "ඔබ ${item.name} ලබාගත්තා!";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAudio();
    _loadGameData();
    _loadSavedBackground();
  }

  // --- saved background load ---
  Future<void> _loadSavedBackground() async {
    final path = await AppBackgrounds.getSelectedPath();
    if (mounted) setState(() => _bgImage = path);
  }

  // --- ශ්‍රව්‍ය පද්ධතිය සැකසීම ---
  void _initAudio() async {
    try {
      await _soundService.init();

      _soundService.voicePlayer.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isVoicePlaying = state == PlayerState.playing;
          });
        }
      });

      await _soundService.playBgm('audio/bg_music.mp3');
    } catch (e) {
      debugPrint("Audio init error: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _soundService.pauseBgm();
      _soundService.pauseVoice();
    } else if (state == AppLifecycleState.resumed) {
      _soundService.resumeBgm();
      _soundService.resumeVoice();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      final int prevLevel = _currentLevel; // Level up animation සඳහා

      setState(() {
        _state = incomingState;
        _targets = data['targets'] ?? {};
        _remaining = data['remaining'] ?? {};
        _levelAssets = data['level_assets'] ?? {};
        _levelInfo = data['level_info'] ?? {};
        _currentLevel = incomingLevel;
        _isLoading = false;
        _error = "";

        _calculateProgress();

        if (isGameCompleted) {
          _message = "නියමයි! සියලුම අභ්‍යාස අවසන්!";
          _riveLevel =
              (incomingLevel * 2) + 1; // Game completed = last happy state
          _setLevel(_riveLevel.toDouble());
        } else if (didLevelUp) {
          // Level up වූ විට: happy Rive phase (odd) → reward panel නොපෙනේ
          _riveLevel =
              (prevLevel * 2) +
              1; // 2N+1 (odd) = happy state for completed level
          _message = "නියමයි! ඊළඟ මට්ටමට ළඟා වෙනවා!";
          _setLevel(_riveLevel.toDouble());
        } else {
          _syncPuppyWithGameLevel();
        }

        if (_isFirstLoad) {
          _playWelcomeVoiceAsync();
        }

        _isFirstLoad = false;
      });

      // 2. State අප්ඩේට් වූ පසු සජීවීකරණය සහිත Popup/Transitions
      if (didComplete) {
        _showGameCompletedDialog();
      } else if (didLevelUp) {
        // Happy phase → Wait for 2 seconds to let the happy animation finish
        // before showing the level up dialog.
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _showLevelUpDialog(incomingLevel);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // --- Play Welcome Voice Data Loaded ---
  Future<void> _playWelcomeVoiceAsync() async {
    if (!_soundService.isMuted) {
      try {
        await _soundService.playVoice('audio/welcome_audio.mp3');

        // Listen for welcome voice completion to play reward audio
        _soundService.voicePlayer.onPlayerComplete.first.then((_) {
          _playRewardAudioSequence();
        });
      } catch (e) {
        debugPrint("Voice audio play error: $e");
      }
    }
  }

  // --- Auto-play Reward Audio After Welcome ---
  void _playRewardAudioSequence() async {
    if (!mounted || _soundService.isMuted) return;

    // Delay briefly before playing reward audio
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final rewards = _currentRewardList;
    if (rewards.isNotEmpty) {
      final reward = rewards.first;
      if (reward.audioPath.isNotEmpty) {
        // Highlight reward UI
        setState(() => _highlightReward = true);

        try {
          await _soundService.playVoice(reward.audioPath);

          // Wait for reward audio to finish then remove highlight
          _soundService.voicePlayer.onPlayerComplete.first.then((_) {
            if (mounted) setState(() => _highlightReward = false);
          });
        } catch (e) {
          debugPrint("Reward audio error: $e");
          setState(() => _highlightReward = false);
        }
      }
    }
  }

  // --- Level Up Dialog පෙන්වීම ---
  void _showLevelUpDialog(int newLevel) {
    if (!_soundService.isMuted) {
      try {
        _soundService.playVoice('audio/level_up.mp3');
      } catch (e) {
        debugPrint("Level up audio error: $e");
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LevelUpDialog(
          newLevel: newLevel,
          onContinue: () {
            Navigator.of(context).pop();
            // User closed the dialog → transition to the new 'need' state
            // by reloading the data which syncs the Rive Level to 2N (odd)
            _loadGameData().then((_) {
              // Play reward audio for the newly loaded need level
              if (mounted) {
                _playRewardAudioSequence();
              }
            });
          },
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

  // --- Game Level N → Rive Level 2N (need/sad state) ---
  void _syncPuppyWithGameLevel() {
    _riveLevel =
        _currentLevel * 2; // Even Rive level = need state (starts at 2)
    _message = "බලු පැටියාට ඕන දෙයක් ඇත...";
    _setLevel(_riveLevel.toDouble());
  }

  // --- Reward panel පෙනිය යුතුද? Rive level even නම් (need state) ---
  bool get _showRewardPanel => _riveLevel.isEven;

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
      // Pending level ඇත්නම් (Rive init වීමට කලින් set කිරීමට උත්සාහ කළ)
      if (_pendingLevel != null) {
        final v = _pendingLevel!;
        _pendingLevel = null;
        _setLevel(v);
      } else {
        // Default: current need level
        _setLevel(_riveLevel.toDouble());
      }
    });
  }

  Future<void> _logout() async {
    _soundService.stopBgm();
    _soundService.stopVoice();
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
        currentLevel: _currentLevel,
        onBackgroundChanged: (path) {
          setState(() => _bgImage = path);
        },
      ),
    );
  }


  void _startTask(String componentKey) async {
    // 🟢 අවබෝදය (Comprehension) — වෙනම flow එකක් භාවිතා කරයි
    if (componentKey == 'narr') {
      await _startComprehensionTask();
      return;
    }

    String assetKey = "";
    if (componentKey == 'pron') {
      assetKey = 'pronunciation';
    } else if (componentKey == 'hw') {
      assetKey = 'handwriting';
    } else if (componentKey == 'gram') {
      assetKey = 'grammar';
    }

    final List assets = _levelAssets[assetKey] ?? [];

    if (assets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("මෙම අංශයේ වැඩ දැනට අවසන්!")),
      );
      return;
    }

    final taskData = assets[0];

    // ── Grammar: route by grade ─────────────────────────────────────────
    if (componentKey == 'gram') {
      final grammarAssets = _levelAssets['grammar'] as List? ?? [];
      final grammarTasks = grammarAssets
          .map((m) => GrammarTask.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList();

      final int grade = (_levelInfo['grade'] ?? 1) as int;

      await _soundService.pauseBgm();
      await _soundService.stopVoice();
      if (_smController != null) _smController!.isActive = false;
      if (!mounted) return;

      Widget gramScreen;
      if (grade <= 2) {
        // Grades 1-2: image selection + drag-drop game
        gramScreen = GrammarSelectionPage(tasks: grammarTasks, grade: grade);
      } else {
        // Grades 3-5: word-only drag-drop game (no image step)
        gramScreen = GrammarWordGamePage(tasks: grammarTasks, grade: grade);
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => gramScreen),
      );

      if (result == true) _loadGameData();
      if (_smController != null) _smController!.isActive = true;
      if (mounted) await _soundService.resumeBgm();
      return;
    }

    Widget targetScreen;
    if (componentKey == 'pron') {
      targetScreen = ReadingScreen(taskData: taskData);
    } else if (componentKey == 'hw') {
      targetScreen = WritingScreen(taskData: taskData);
    } else {
      targetScreen = AskingScreen(taskData: taskData);
    }

    await _soundService.pauseBgm();
    await _soundService.stopVoice();
    if (_smController != null) _smController!.isActive = false;

    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    );

    if (result == true) {
      _loadGameData();
    }

    if (_smController != null) _smController!.isActive = true;
    if (mounted) {
      await _soundService.resumeBgm();
    }
  }

  // 🟢 අවබෝදය (Comprehension) Flow — Modal Backend එකෙන් කතාව සහ ප්‍රශ්න ජනනය කරයි
  Future<void> _startComprehensionTask() async {
    // 1. narrative assets වලින් theme/context ලබා ගැනීම
    final List assets = _levelAssets['narrative'] ?? [];
    String theme = 'සතුන්';
    String storyContext = 'සතුන් ගැන කතාවක්';
    if (assets.isNotEmpty) {
      final taskData = assets[0];
      theme = taskData['theme'] ?? theme;
      storyContext =
          taskData['story_prompt'] ?? taskData['context'] ?? storyContext;
    }

    // Grade එක API level_info වලින් ලබා ගැනීම
    final int grade = (_levelInfo['grade'] ?? 1) as int;

    // Grade 1,2 නම් 'සරල', Grade 3,4,5 නම් 'උසස්'
    final String level = grade < 3 ? 'සරල' : 'උසස්';

    // Level within grade
    final int levelInGrade = (_levelInfo['level_number'] ?? 1) as int;

    // 2. Loading overlay පෙන්වීම
    await _soundService.pauseBgm();
    await _soundService.stopVoice();
    if (_smController != null) _smController!.isActive = false;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => const Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: LoadingOverlay(),
      ),
    );

    try {
      // 3. කතාව ජනනය කිරීම
      final storyText = await _comprehensionService.generateStory(
        level: level,
        theme: theme,
        context: storyContext,
      );

      if (!mounted) return;
      Navigator.pop(context); // Loading dialog close

      // 4. Background එකෙහි ප්‍රශ්න ජනනය ආරම්භ කිරීම
      final quizFuture = _comprehensionService.generateQuiz(
        story: storyText,
        level: level,
      );

      // 5. StoryScreen වෙත navigate කිරීම
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoryScreen(
            storyText: storyText,
            quizFuture: quizFuture,
            grade: grade,
            level: levelInGrade,
            masterLevelId: _currentLevel,
          ),
        ),
      );

      // 6. StoryScreen flow එකෙන් ආපසු පැමිණි විට data reload කිරීම
      _loadGameData();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Loading dialog close
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "කතාව සෑදීම අසාර්ථකයි: $e",
              style: GoogleFonts.notoSansSinhala(fontSize: 14),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (_smController != null) _smController!.isActive = true;
      if (mounted) {
        await _soundService.resumeBgm();
      }
    }
  }

  void _navigateToActivity(Widget screen) async {
    await _soundService.pauseBgm();
    await _soundService.pauseVoice();
    if (_smController != null) _smController!.isActive = false;

    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

    if (_smController != null) _smController!.isActive = true;
    if (mounted) {
      await _soundService.resumeBgm();
      await _soundService.resumeVoice();
    }
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

          return RefreshIndicator(
            onRefresh: _loadGameData,
            color: Colors.white,
            backgroundColor: Colors.orange.shade600,
            strokeWidth: 3.0,
            displacement: 50.0,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: SizedBox(
                height: constraints.maxHeight,
                child: Stack(
                  children: [
                    // 1. පසුබිම (Background)
                    Positioned.fill(
                      child: Image.asset(
                        _bgImage,
                        fit: BoxFit.cover,
                        alignment: Alignment
                            .bottomCenter, // Keep the floor visible on wide screens
                        filterQuality: FilterQuality
                            .high, // Improve rendering quality on large screens
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
                              constraints.maxHeight *
                              (isSmallScreen ? 0.45 : 0.55),
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
                          AnimatedBuilder(
                            animation: _soundService,
                            builder: (context, child) {
                              return GameTopBar(
                                currentLevel: _currentLevel,
                                levelProgress: _levelProgress,
                                isSoundOn: !_soundService.isMuted,
                                onToggleSound: _soundService.toggleMute,
                                onSettingsTap: _openSettings,
                                onProfileTap: _openProfile,
                                onLogoutTap: _logout,
                                isSmallScreen: isSmallScreen,
                              );
                            },
                          ),

                          const SizedBox(height: 10),

                          // Task Select Buttons (කියවීම, ලිවීම, etc.)
                          GameTaskSection(
                            targets: _targets,
                            remaining: _remaining,
                            onTaskTap: _startTask,
                            isHighlighted: _highlightTasks,
                          ),

                          // Reward panel: Rive level odd (need state) ලදිත් පමණක් පෙනේ
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 800),
                            reverseDuration: const Duration(milliseconds: 400),
                            switchInCurve: Curves.elasticOut,
                            switchOutCurve: Curves.easeInBack,
                            transitionBuilder: (child, animation) {
                              // Enter: Slide from right + Fade + slight Scale bounce
                              final slideSlide = Tween<Offset>(
                                begin: const Offset(0.5, 0),
                                end: Offset.zero,
                              ).animate(animation);

                              final scaleAnim = Tween<double>(
                                begin: 0.8,
                                end: 1.0,
                              ).animate(animation);

                              return SlideTransition(
                                position: slideSlide,
                                child: ScaleTransition(
                                  scale: scaleAnim,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            child: _showRewardPanel
                                ? Align(
                                    key: const ValueKey('reward_panel_visible'),
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        right: 20,
                                        top: 10,
                                      ),
                                      child: RewardPanel(
                                        items: _currentRewardList,
                                        isCompact: true,
                                        currentLevel: _currentLevel,
                                        isAllTasksCompleted:
                                            _isAllTasksCompleted,
                                        onTapItem: _onRewardTapped,
                                        isHighlighted: _highlightReward,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(
                                    key: ValueKey('reward_panel_hidden'),
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
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Message Bubble (පණිවිඩ කොටුව) ---
  Widget _buildMessageBubble(double maxWidth) {
    String displayMsg = _isVoicePlaying
        ? "ආයුබෝවන් දුවේ පුතේ… මේ ඉන්නේ ඔයාලගෙ බලු පැටියා බලන්න එයාට මොනවද ඕන කියලා , දකුනු පැත්තෙන් එයාට ඕන දේ පෙන්නනවා නේද ?"
        : _message;

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
        displayMsg,
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
