import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class SoundService extends ChangeNotifier {
  static final SoundService _instance = SoundService._internal();

  factory SoundService() {
    return _instance;
  }

  SoundService._internal();

  final AudioPlayer bgMusicPlayer = AudioPlayer();
  final AudioPlayer voicePlayer = AudioPlayer();

  bool _isInitialized = false;
  double _bgmVolume = 0.5;
  double _voiceVolume = 0.8;
  bool _isMuted = false;

  double get bgmVolume => _bgmVolume;
  double get voiceVolume => _voiceVolume;
  bool get isMuted => _isMuted;

  Future<void> init() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _bgmVolume = prefs.getDouble('bgm_volume') ?? 0.3;
    _voiceVolume = prefs.getDouble('voice_volume') ?? 1.0;
    _isMuted = prefs.getBool('is_muted') ?? false;

    await bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
    await _updatePlayerVolumes();

    _isInitialized = true;
  }

  Future<void> _updatePlayerVolumes() async {
    if (_isMuted) {
      await bgMusicPlayer.setVolume(0.0);
      await voicePlayer.setVolume(0.0);
    } else {
      await bgMusicPlayer.setVolume(_bgmVolume);
      await voicePlayer.setVolume(_voiceVolume);
    }
    notifyListeners();
  }

  Future<void> setBgmVolume(double volume) async {
    _bgmVolume = volume.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('bgm_volume', _bgmVolume);
    await _updatePlayerVolumes();
  }

  Future<void> setVoiceVolume(double volume) async {
    _voiceVolume = volume.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('voice_volume', _voiceVolume);
    await _updatePlayerVolumes();
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_muted', _isMuted);
    await _updatePlayerVolumes();
  }

  Future<void> playBgm(String assetPath) async {
    await init();
    await bgMusicPlayer.play(AssetSource(assetPath));
  }

  Future<void> pauseBgm() async {
    await bgMusicPlayer.pause();
  }

  Future<void> resumeBgm() async {
    if (!_isMuted) {
      await bgMusicPlayer.resume();
    }
  }

  Future<void> stopBgm() async {
    await bgMusicPlayer.stop();
  }

  Future<void> playVoice(String assetPath) async {
    await init();
    await voicePlayer.play(AssetSource(assetPath));
  }

  Future<void> pauseVoice() async {
    await voicePlayer.pause();
  }

  Future<void> resumeVoice() async {
    if (!_isMuted) {
      await voicePlayer.resume();
    }
  }

  Future<void> stopVoice() async {
    await voicePlayer.stop();
  }

  void disposePlayers() {
    bgMusicPlayer.dispose();
    voicePlayer.dispose();
  }
}
