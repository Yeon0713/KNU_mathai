import 'dart:async';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:battery_plus/battery_plus.dart';
import '../utils/notification_helper.dart';
import '../services/ai_handler.dart';
import '../services/helmet_service.dart';
import '../services/sensor_service.dart';
import 'ride_controller.dart'; 
import '../main.dart'; 

class GlobalController extends GetxController {
  // 상태 변수
  var speed = "0.0 km/h".obs;
  var batteryLevel = 100.obs;
  
  RxBool isHelmetDetected = false.obs; 
  RxBool isAiEnabled = true.obs; 
  var isDanger = false.obs; 

  // 카메라 관련
  CameraController? cameraController; 
  RxBool isCameraInitialized = false.obs;
  
  // AI 관련
  var yoloResults = <Map<String, dynamic>>[].obs;
  
  // 이미지 크기 변수 (오류 방지용)
  var camImageWidth = 0.0.obs; 
  var camImageHeight = 0.0.obs;

  late AiHandler aiHandler;         // 주행용 (Detection)
  late HelmetService helmetService; // 헬멧용 (Classification)
  
  // 현재 어떤 모드인지 확인하는 플래그
  bool isDashboardMode = false;

  bool isDetecting = false;
  bool _isSpeeding = false;
  bool _isObjectDetected = false;

  final Battery _battery = Battery();
  final NotificationHelper _notification = NotificationHelper();
  final SensorService sensorService = Get.put(SensorService()); 
  RideController? _rideController; 

  @override
  void onInit() {
    super.onInit();
    _notification.init();
    
    // 두 서비스 모두 생성
    aiHandler = AiHandler();
    helmetService = HelmetService();

    _initBatteryTracking();
    
    ever(sensorService.displaySpeed, (String val) {
      speed.value = val;
      double currentSpeed = double.tryParse(val.split(' ')[0]) ?? 0.0;
      bool newSpeedStatus = (currentSpeed > 30.0);
      if (_isSpeeding != newSpeedStatus) {
        _isSpeeding = newSpeedStatus;
        _checkTotalDanger();
      }
    });
  }

  @override
  void onClose() {
    cameraController?.dispose();
    aiHandler.closeModel();
    helmetService.close(); 
    super.onClose();
  }

  // --------------------------------------------------------
  // 모드 전환
  // --------------------------------------------------------

  // [1] 헬멧 체크 모드
  Future<void> startHelmetCheckMode() async {
    isDashboardMode = false; 
    isCameraInitialized.value = false;
    isAiEnabled.value = false;
    isHelmetDetected.value = false;

    await helmetService.loadModel();
    await aiHandler.closeModel();

    int cameraIndex = 0;
    try {
      cameraIndex = cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
      if (cameraIndex == -1) cameraIndex = 0; 
    } catch (e) {
      cameraIndex = 0;
    }
    
    await _initCamera(cameraIndex, resolution: ResolutionPreset.medium);
    isAiEnabled.value = true;
  }

  // [2] 대시보드 모드
  Future<void> startDashboardMode() async {
    isDashboardMode = true; 
    isCameraInitialized.value = false;
    isAiEnabled.value = false;
    yoloResults.clear();

    helmetService.close();
    await aiHandler.switchModel(toHelmetModel: false);

    int cameraIndex = 0;
    try {
      cameraIndex = cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
      if (cameraIndex == -1) cameraIndex = 0; 
    } catch (e) {
      cameraIndex = 0;
    }

    await _initCamera(cameraIndex, resolution: ResolutionPreset.high);
    isAiEnabled.value = true;
  }

  Future<void> _initCamera(int cameraIndex, {ResolutionPreset resolution = ResolutionPreset.high}) async {
    if (cameras.isEmpty) return; 
    if (cameraController != null) {
      await cameraController!.dispose();
      cameraController = null;
    }

    final camera = cameras[cameraIndex]; 
    cameraController = CameraController(
      camera,
      resolution,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420, 
    );

    try {
      await cameraController!.initialize();
      await cameraController!.startImageStream((image) {
        processCameraImage(image);
      });
      isCameraInitialized.value = true; 
    } catch (e) {
      print("❌ 카메라 초기화 오류: $e");
    }
  }

  // --------------------------------------------------------
  // AI 이미지 처리 (수정된 핵심 로직)
  // --------------------------------------------------------
  Future<void> processCameraImage(CameraImage image) async {
    if (isDetecting || !isAiEnabled.value) return;
    isDetecting = true;

    try {
      if (!isDashboardMode) {
        // [헬멧 모드]
        bool result = await helmetService.detectHelmet(image);
        isHelmetDetected.value = result;
        yoloResults.clear();
      
      } else {
        // [대시보드 모드]
        
        // ★ [수정] 주행 중이 아니면 '모든 위험 상태'를 초기화!
        if (_rideController == null || !_rideController!.isRiding.value) {
           yoloResults.clear(); 
           
           // 이 세 줄을 추가하여 빨간 화면을 즉시 끕니다.
           isDanger.value = false;       
           _isObjectDetected = false;
           _isSpeeding = false;

           return; // 함수 종료
        }

        // --- 주행 중일 때만 아래 로직 실행 ---
        camImageWidth.value = image.width.toDouble();
        camImageHeight.value = image.height.toDouble();
        
        final results = await aiHandler.runInference(image);
        yoloResults.value = results; 

        bool dangerFoundThisFrame = false;
        if (results.isNotEmpty) {
          for (var obj in results) {
            String tag = obj['tag'];
            if (tag == "person" || tag == "car" || tag == "truck" || tag == "DANGER_HIT") {
               dangerFoundThisFrame = true; 
            }
          }
        }
        
        // 상태가 변했을 때만 업데이트 (불필요한 연산 방지)
        if (_isObjectDetected != dangerFoundThisFrame) {
          _isObjectDetected = dangerFoundThisFrame;
          _checkTotalDanger();
        }
      }
    } catch (e) {
      print("AI Loop Error: $e");
    } finally {
      isDetecting = false;
    }
  }

  void setRideController(RideController controller) {
    _rideController = controller;
  }
  
  void _checkTotalDanger() {
    bool finalDangerStatus = _isSpeeding || _isObjectDetected;
    if (finalDangerStatus && !isDanger.value) {
      _notification.triggerWarning(0.25);
    }
    isDanger.value = finalDangerStatus;
  }
  
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
}