import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false; // 쿨타임 체크용 (중복 재생 방지)

  // 거리 민감도 설정
  final double minDetectionHeight = 0.05; 
  final double dangerHeight = 0.20;       

  Future<void> init() async {
    print("✅ 경고 시스템(Sound Only) 준비 완료");
  }

  void triggerWarning(double objectHeight) async {
    // 이미 쿨타임 중이면 무시
    if (_isPlaying) return;

    String soundPath;
    String logMsg;

    if (objectHeight >= dangerHeight) {
      soundPath = 'sounds/level2.mp3';
      logMsg = "🚨 위험 경고! (level2)";
    } else if (objectHeight >= minDetectionHeight) {
      soundPath = 'sounds/level1.mp3';
      logMsg = "⚠️ 가벼운 경고 (level1)";
    } else {
      return; 
    }

    _isPlaying = true; // 쿨타임 시작
    print("$logMsg - 크기: ${objectHeight.toStringAsFixed(2)}");

    try {
      await _audioPlayer.stop(); // 혹시 재생 중인 게 있으면 멈춤
      await _audioPlayer.play(AssetSource(soundPath));

      // ★ [핵심] 1초 뒤에 소리 강제 종료! (짧게 끊어치기)
      Timer(const Duration(milliseconds: 1000), () async {
        await _audioPlayer.stop();
      });

    } catch (e) {
      print("❌ 소리 재생 오류: $e");
    }

    // ★ [쿨타임] 소리는 0.5초 만에 꺼지지만, 
    // 다음 경고는 2초 뒤에나 울릴 수 있게 함 (너무 시끄러움 방지)
    Timer(const Duration(seconds: 2), () {
      _isPlaying = false;
    });
  }
}