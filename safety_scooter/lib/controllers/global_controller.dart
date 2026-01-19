import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:battery_plus/battery_plus.dart';
import '../utils/notification_helper.dart';
import '../services/ai_handler.dart';
import '../services/sensor_service.dart'; 

class GlobalController extends GetxController {
  // --------------------------------------------------------
  // 1. 상태 변수들
  // --------------------------------------------------------
  var speed = "0.0 km/h".obs;
  var batteryLevel = 100.obs;
  
  
  var isDanger = false.obs; 

  bool _isSpeeding = false;       // 속도 위반 여부 상태
  bool _isObjectDetected = false; // 위험 객체 발견 여부 상태

  // --------------------------------------------------------
  // 2. 의존성 및 AI 관련 변수
  // --------------------------------------------------------
  final Battery _battery = Battery();
  final NotificationHelper _notification = NotificationHelper();
  late AiHandler aiHandler;
  
  
  final SensorService sensorService = Get.put(SensorService()); 

  var yoloResults = <Map<String, dynamic>>[].obs;
  var camImageWidth = 0.0.obs;
  var camImageHeight = 0.0.obs;
  bool isDetecting = false;
  bool isModelLoaded = false;

  @override
  void onInit() {
    super.onInit();
    _notification.init();
    aiHandler = AiHandler();
    
    // AI 모델 로드
    aiHandler.loadYoloModel().then((_) {
      isModelLoaded = true;
      print("✅ [Controller] 모델 로드 완료");
    });

    _initBatteryTracking();
    
    // SensorService의 속도/움직임 상태를 감시
    // [리팩토링] 문자열 파싱 제거 -> rawGpsSpeed(double) 직접 구독
    ever(sensorService.rawGpsSpeed, (double currentSpeed) {
      speed.value = "${currentSpeed.toStringAsFixed(1)} km/h"; // UI용 변수 업데이트
      
      // 속도 위반 여부 업데이트 (30km/h 초과 시 위반)
      bool newSpeedStatus = (currentSpeed > 30.0);
      
      // 상태가 변했을 때만 로직 수행
      if (_isSpeeding != newSpeedStatus) {
        _isSpeeding = newSpeedStatus;
        _checkTotalDanger(); // 상태가 변했으니 종합 판단 다시 수행
      }
    });
  }

  @override
  void onClose() {
    aiHandler.closeModel();
    super.onClose();
  }

  // --------------------------------------------------------
  // 3. 종합 위험 판단 로직 (GPS + AI 결과 합치기)
  // --------------------------------------------------------
  void _checkTotalDanger() {
    // 둘 중 하나라도 위험하면 '위험'으로 간주
    bool finalDangerStatus = _isSpeeding || _isObjectDetected;

    // 상태가 '안전' -> '위험'으로 바뀔 때만 소리 재생 (중복 재생 방지)
    if (finalDangerStatus && !isDanger.value) {
      _notification.triggerWarning(
        0.25,
        lat: sensorService.latitude.value,
        lng: sensorService.longitude.value,
        imagePath: "", // TODO: 카메라 이미지를 파일로 저장 후 경로 전달 필요
      );
    }
    
    // UI 업데이트 (화면 테두리 빨간색 등)
    isDanger.value = finalDangerStatus;
  }

  // --------------------------------------------------------
  // 4. AI 이미지 처리 (카메라에서 호출)
  // --------------------------------------------------------
  Future<void> processCameraImage(CameraImage image) async {
    // 모델 로딩 전이나 이미 분석 중이면 패스
    if (_shouldSkipFrame()) return;

    isDetecting = true;

    // 이미지 크기 정보 업데이트 (박스 그리기용)
    camImageWidth.value = image.width.toDouble();
    camImageHeight.value = image.height.toDouble();

    try {
      final results = await aiHandler.runInference(image);
      yoloResults.value = results; // 결과 업데이트 (화면 박스 그리기용)

      // 위험 요소 분석 및 상태 업데이트
      bool dangerFoundThisFrame = _analyzeResultsForDanger(results);

      _updateDetectionStatus(dangerFoundThisFrame);
    } catch (e) {
      print("Error in AI loop: $e");
    } finally {
      isDetecting = false;
    }
  }

  /// 프레임 처리를 건너뛸지 결정
  bool _shouldSkipFrame() {
    if (isDetecting || !isModelLoaded) return true;
    // (선택사항) 정지 중일 때 배터리 절약: if (!sensorService.isMoving.value) return true;
    return false;
  }

  /// AI 결과에서 위험 요소(DANGER_HIT)가 있는지 확인
  bool _analyzeResultsForDanger(List<Map<String, dynamic>> results) {
    if (results.isEmpty) return false;

    for (var obj in results) {
      if (obj['tag'] == "DANGER_HIT") {
        print("🚨 위험 요소(DANGER_HIT) 감지됨! [ID: ${obj['id']}]");
        return true;
      }
    }
    return false;
  }

  /// 감지 상태가 변경되었을 때만 업데이트 수행
  void _updateDetectionStatus(bool dangerFound) {
    if (_isObjectDetected != dangerFound) {
      _isObjectDetected = dangerFound;
      _checkTotalDanger(); // 종합 판단 요청
    }
  }

  // 배터리 관리
  void _initBatteryTracking() {
    _updateBatteryLevel();
    _battery.onBatteryStateChanged.listen((BatteryState state) {
      _updateBatteryLevel();
    });
  }
  void _updateBatteryLevel() async {
    final level = await _battery.batteryLevel;
    batteryLevel.value = level;
  }
  
  // 시뮬레이션용 (디버깅)
  void setDangerStatus(bool status) {
    isDanger.value = status;
  }
  
  void updateSpeed(double newSpeed) {
    speed.value = "$newSpeed km/h";
    _isSpeeding = newSpeed > 30;
    _checkTotalDanger();
  }
}
