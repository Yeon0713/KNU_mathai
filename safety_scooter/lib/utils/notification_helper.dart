import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false; // 소리 중복 재생 방지

  // 거리 민감도 설정
  final double minDetectionHeight = 0.05; 
  final double dangerHeight = 0.20;       

  Future<void> init() async {
    print("✅ 경고 시스템(Sound Only) 준비 완료");
  }

  void triggerWarning(double objectHeight) async {
    // 이미 소리가 나고 있으면 무시
    if (_isPlaying) return;

    String soundPath;
    String logMsg;

    if (objectHeight >= dangerHeight) {
      // [위험] level2.mp3
      soundPath = 'sounds/level2.mp3';
      logMsg = "🚨 위험 경고! (level2)";
    } else if (objectHeight >= minDetectionHeight) {
      // [주의] level1.mp3
      soundPath = 'sounds/level1.mp3';
      logMsg = "⚠️ 가벼운 경고 (level1)";
    } else {
      return; // 너무 멀면 아무것도 안 함
    }

    _isPlaying = true;
    print("$logMsg - 크기: ${objectHeight.toStringAsFixed(2)}");

    try {
      // 기존 소리 멈추고 새 소리 재생
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(soundPath));
    } catch (e) {
      print("❌ 소리 재생 오류: $e");
    }

    // 2초 동안은 다시 울리지 않음 (쿨타임)
    Timer(const Duration(seconds: 2), () {
      _isPlaying = false;
    });
  }
}