import 'dart:async';
import 'dart:math';
import 'package:get/get.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class SensorService extends GetxController {
  // ----------------------------------------------------------
  // [관측 변수] UI 및 GlobalController에서 구독할 값들
  // ----------------------------------------------------------
  
  // ★ 수정됨: 이제 "정지" 같은 한글 없이 무조건 "0.0 km/h" 형식만 유지
  var displaySpeed = "0.0 km/h".obs;     
  
  // AI 작동 여부를 결정하는 핵심 스위치
  var isMoving = false.obs;         
  
  // 디버깅용
  var rawGpsSpeed = 0.0.obs;        
  var rawVibration = 0.0.obs;       

  // ----------------------------------------------------------
  // [튜닝 포인트]
  // ----------------------------------------------------------
  final double GPS_MOVE_THRESHOLD = 3.0; // 3km/h 이상이면 확실히 주행 중
  final double VIBE_THRESHOLD = 1.5;     // 진동 임계값
  
  StreamSubscription? _accelSubscription;
  StreamSubscription? _gpsSubscription;
  Timer? _stopTimer;

  @override
  void onInit() {
    super.onInit();
    _initializeSensors(); 
  }

  @override
  void onClose() {
    _accelSubscription?.cancel();
    _gpsSubscription?.cancel();
    _stopTimer?.cancel();
    super.onClose();
  }

  Future<void> _initializeSensors() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      _startGps();
    }
    _startAccelerometer();
  }

  // ----------------------------------------------------------
  // [로직 1] GPS: 항상 속도값을 업데이트함
  // ----------------------------------------------------------
  void _startGps() {
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high, 
      distanceFilter: 2
    );
    
    _gpsSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      
      double speedKmph = position.speed * 3.6;
      if (speedKmph < 0) speedKmph = 0; 

      rawGpsSpeed.value = speedKmph;

      // ★ [수정] 조건문 밖에서도 항상 화면에 속도 표시 (0.0 km/h 포함)
      displaySpeed.value = "${speedKmph.toStringAsFixed(1)} km/h";

      // 로직: 속도가 임계값 넘으면 주행 상태로 변경
      if (speedKmph >= GPS_MOVE_THRESHOLD) {
        isMoving.value = true;
        _stopTimer?.cancel(); 
      }
    });
  }

  // ----------------------------------------------------------
  // [로직 2] 가속도 센서: 화면 글자는 안 바꾸고, 내부 상태(isMoving)만 변경
  // ----------------------------------------------------------
  void _startAccelerometer() {
    _accelSubscription = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      double force = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
      rawVibration.value = force;

      // 로직: 진동이 임계값을 넘으면 움직이는 것으로 간주
      if (force > VIBE_THRESHOLD) {
        
        // GPS가 멈춰있다고 생각하는데 진동이 있을 때 (터널 등)
        if (rawGpsSpeed.value < GPS_MOVE_THRESHOLD) {
           isMoving.value = true;
           _stopTimer?.cancel();
           
           // ★ [수정] 여기서 "주행 중(GPS 약함)"이라고 글자를 바꾸지 않음.
           // 화면에는 그냥 GPS가 주는 0.0 km/h가 찍혀있겠지만,
           // isMoving은 true가 되었으므로 AI는 정상 작동함.
        }

        // 진동 멈춤 감지 타이머
        _stopTimer?.cancel();
        _stopTimer = Timer(const Duration(seconds: 3), () {
          // 3초 뒤에도 GPS 속도가 없으면 진짜 멈춘 것
          if (rawGpsSpeed.value < GPS_MOVE_THRESHOLD) {
            isMoving.value = false;
            
            // ★ [수정] "정지" 대신 숫자로 초기화
            displaySpeed.value = "0.0 km/h";
          }
        });
      }
    });
  }
}
