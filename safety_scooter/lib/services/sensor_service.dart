import 'dart:async';
import 'dart:math';
import 'package:get/get.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class SensorService extends GetxController {
  // ----------------------------------------------------------
  // [관측 변수] UI에서 보여줄 값들
  // ----------------------------------------------------------
  var displaySpeed = "정지".obs;     // UI에 표시될 텍스트 (예: "15 km/h" or "터널 주행 중")
  var isMoving = false.obs;         // 움직이는지 여부 (AI 켜는 스위치)
  var isDanger = false.obs;         // 위험 감지 여부
  
  // 디버깅용 (실제 값 확인)
  var rawGpsSpeed = 0.0.obs;        // 실제 GPS 속도
  var rawVibration = 0.0.obs;       // 실제 진동 세기

  // ----------------------------------------------------------
  // [설정값] 튜닝 포인트
  // ----------------------------------------------------------
  final double GPS_MOVE_THRESHOLD = 3.0; // 3km/h 이상이면 무조건 주행으로 간주
  final double VIBE_THRESHOLD = 1.5;     // 진동 임계값
  
  StreamSubscription? _accelSubscription;
  StreamSubscription? _gpsSubscription;
  Timer? _stopTimer;

  @override
  void onInit() {
    super.onInit();
    _initializeSensors(); // 앱 켜지자마자 센서 가동
  }

  @override
  void onClose() {
    _accelSubscription?.cancel();
    _gpsSubscription?.cancel();
    _stopTimer?.cancel();
    super.onClose();
  }

  // ----------------------------------------------------------
  // [초기화] 권한 받고 센서 2개 동시에 켜기
  // ----------------------------------------------------------
  Future<void> _initializeSensors() async {
    // 1. 위치 권한 요청 (GPS 쓰려면 필수)
    var status = await Permission.location.request();
    if (status.isGranted) {
      _startGps();
    }
    
    // 2. 가속도 센서 시작
    _startAccelerometer();
  }

  // ----------------------------------------------------------
  // [로직 1] GPS: "속도가 찍히면 무조건 주행 중!"
  // ----------------------------------------------------------
  void _startGps() {
    // 정확도 높음, 2미터마다 갱신
    final locationSettings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 2);
    
    _gpsSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      
      // m/s -> km/h 변환
      double speedKmph = position.speed * 3.6;
      if (speedKmph < 0) speedKmph = 0; // 음수 방지

      rawGpsSpeed.value = speedKmph; // 값 저장

      // ★ 로직: 속도가 3km/h 넘으면 확실히 움직이는 거임
      if (speedKmph >= GPS_MOVE_THRESHOLD) {
        isMoving.value = true;
        _stopTimer?.cancel(); // 정지 타이머 취소
        
        // UI 업데이트: 정확한 속도 표시
        displaySpeed.value = "${speedKmph.toStringAsFixed(1)} km/h";
      }
    });
  }

  // ----------------------------------------------------------
  // [로직 2] 가속도 센서: "GPS가 안 터져도 진동 있으면 주행 중!" (터널/실내용)
  // ----------------------------------------------------------
  void _startAccelerometer() {
    _accelSubscription = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      double force = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
      rawVibration.value = force;

      // ★ 로직: GPS 속도가 안 잡혀도(0이어도), 진동이 심하면 움직이는 거임
      if (force > VIBE_THRESHOLD) {
        // 이미 GPS로 주행 중이라고 판단했으면 굳이 건드리지 않음
        if (rawGpsSpeed.value < GPS_MOVE_THRESHOLD) {
           isMoving.value = true;
           _stopTimer?.cancel();
           
           // UI 업데이트: 속도는 모르지만 움직인다고 표시
           displaySpeed.value = "🛴 주행 중 (GPS 약함)";
        }

        // 진동이 멈추면 3초 뒤에 정지로 판단 (신호 대기 고려)
        _stopTimer?.cancel();
        _stopTimer = Timer(const Duration(seconds: 3), () {
          // 3초 뒤에도 GPS 속도가 0이면 진짜 멈춘 것
          if (rawGpsSpeed.value < GPS_MOVE_THRESHOLD) {
            isMoving.value = false;
            displaySpeed.value = "정지";
          }
        });
      }
    });
  }

  // (외부용) 위험 상태 변경
  void setDangerStatus(bool status) {
    isDanger.value = status;
  }
}
// git update test