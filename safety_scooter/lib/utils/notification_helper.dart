import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
//import '../services/api_service.dart';

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

  void triggerWarning(double objectHeight, {double? lat, double? lng, String? imagePath}) async {
    // 이미 쿨타임 중이면 무시
    if (_isPlaying) return;

    // 1. 위험 레벨 판단 및 리소스 결정
    final warningDetails = _getWarningDetails(objectHeight);
    if (warningDetails == null) return; // 경고 대상 아님

    _isPlaying = true; // 쿨타임 시작
    print("${warningDetails['msg']} - 크기: ${objectHeight.toStringAsFixed(2)}");

    // 2. 서버로 경고 데이터 전송 (Fire-and-forget)
    // [임시 중단] 서버 POST 요청 로직 끊음 (코드 보존)
    // ApiService().sendWarning(lat, lng, imagePath);

    // 3. 소리 재생
    _playWarningSound(warningDetails['sound']!);

    // 4. 쿨타임 해제 타이머 설정
    _scheduleCooldownReset();
  }

  /// 위험도에 따른 소리 파일 경로와 로그 메시지 반환
  Map<String, String>? _getWarningDetails(double height) {
    if (height >= dangerHeight) {
      return {
        'sound': 'sounds/level2.mp3',
        'msg': "🚨 위험 경고! (level2)"
      };
    } else if (height >= minDetectionHeight) {
      return {
        'sound': 'sounds/level1.mp3',
        'msg': "⚠️ 가벼운 경고 (level1)"
      };
    }
    return null;
  }

  /// 소리 재생 및 짧게 끊어치기 로직
  Future<void> _playWarningSound(String soundPath) async {
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
  }

  /// 쿨타임 리셋 (2초 후)
  void _scheduleCooldownReset() {
    Timer(const Duration(seconds: 2), () {
      _isPlaying = false;
    });
  }
}