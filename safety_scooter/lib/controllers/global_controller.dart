import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart'; // WidgetsBindingObserver용
import 'package:get/get.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:permission_handler/permission_handler.dart'; // 권한 요청용
import 'settings_controller.dart';
import 'ride_controller.dart';
import '../main.dart';
import '../utils/notification_helper.dart';
import '../services/ai_handler.dart';
import '../services/helmet_service.dart';
import '../services/api_service.dart';
import '../services/sensor_service.dart'; 

class GlobalController extends GetxController with WidgetsBindingObserver {
  // --------------------------------------------------------
  // 1. 상태 변수들
  // --------------------------------------------------------

  // 시속
  var speed = "0.0 km/h".obs;
  
  // 배터리 잔량
  var batteryLevel = 100.obs;

  // AI 사용 가능 여부
  RxBool isAiEnabled = true.obs;

  // 속도 위반 여부 상태
  bool _isSpeeding = false;
  
  // 위험 객체 발견 여부 상태
  bool _isObjectDetected = false;

  // 위험 상태
  var isDanger = false.obs; 

  // [헬멧 검사용] 모드 보관
  bool isHelmetCheckMode = false;

  // [주행용] 모드 보관
  bool isRideMode = false;

  // [디버깅용] 오버레이 표시 여부
  var isDebugOverlayOpen = false.obs;

  // [디버깅용] 추가 정보
  var fps = 0.0.obs; // 초당 프레임 수
  var objCount = 0.obs; // 감지된 객체 수
  var lastServerResponse = "대기 중...".obs; // 마지막 서버 응답
  DateTime? _lastFrameTime; // FPS 계산용 시간 기록

  // [추가] RideController 참조 (주행 상태 확인용)
  RideController? _rideController;
  


  // --------------------------------------------------------
  // 2. 의존성 및 AI 관련 변수
  // --------------------------------------------------------

  // 배터리 객체
  final Battery _battery = Battery();
  
  // 알림 헬퍼 객체
  final NotificationHelper _notification = NotificationHelper();
  
  // [주행용] 트래킹 AI 핸들러
  late AiHandler aiHandler;

  // [주행용] 결과 저장 변수
  var yoloResults = <Map<String, dynamic>>[].obs;

  // [주행용] 객체 탐지 여부
  bool isDetecting = false;
  
  // [헬멧 검사용] 분류 AI 핸들러
  late HelmetService helmetService;

  // [헬멧 검사용] 헬맷 객체 발견 여부
  RxBool isHelmetDetected = false.obs;

  // [추가] 헬멧 인증 진행률 (0.0 ~ 1.0)
  RxDouble helmetCheckProgress = 0.0.obs;
  // [추가] 헬멧 인증 최종 완료 여부
  RxBool isHelmetVerified = false.obs;
  // [추가] 헬멧 연속 감지 시작 시간
  DateTime? _helmetCheckStartTime;

  // [센서용] 센서 서비스
  final SensorService sensorService = Get.put(SensorService()); 


  // 이미지 크기 변수 (오류 방지용)
  var camImageWidth = 0.0.obs;
  var camImageHeight = 0.0.obs;

  // ?
  bool isModelLoaded = false;

  // 카메라 컨트롤러 참조 (사진 촬영용)
  CameraController? cameraController;

  // 카메라 객체 선언 상태
  RxBool isCameraInitialized = false.obs;

  // 설정 컨트롤러 가져오기
  final settings = Get.put(SettingsController());

  

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this); // 앱 생명주기 감지 시작
    _notification.init();

    // [주행용] 서비스 생성
    aiHandler = AiHandler();

    // [헬멧용] 서비스 생성
    helmetService = HelmetService();

    // 배터리 트래킹 선언
    _initBatteryTracking();

    // SensorService의 속도/움직임 상태를 감시
    ever(sensorService.displaySpeed, (val) {
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
    aiHandler.closeModel();
    helmetService.closeModel();
    cameraController?.dispose();
    WidgetsBinding.instance.removeObserver(this); // 감지 해제
    super.onClose();
  }

  // 앱이 백그라운드로 가거나 돌아올 때 처리
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (cameraController == null || !cameraController!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      // 앱이 멈추면 카메라 해제 (메모리 누수 방지)
      cameraController?.dispose();
      isCameraInitialized.value = false;
    } else if (state == AppLifecycleState.resumed) {
      // 앱이 다시 켜지면 현재 모드에 맞춰 카메라 재시작
      if (isHelmetCheckMode) {
        startHelmetCheckMode();
      } else if (isRideMode) {
        startRideMode();
      }
    }
  }

  Future<void> startHelmetCheckMode() async {
    // [추가] 권한 충돌 방지: 위치 권한(센서) 먼저 요청하고 완료될 때까지 대기
    // 이후 아래 _initCamera에서 카메라 권한을 요청하므로 순차적으로 실행됨
    await sensorService.startSensors();

    isRideMode = false;
    await aiHandler.closeModel();

    isHelmetCheckMode = true;
    await helmetService.loadModel();

    isAiEnabled.value = false;
    isHelmetDetected.value = false;
    helmetCheckProgress.value = 0.0;
    isHelmetVerified.value = false;
    _helmetCheckStartTime = null;

    // [수정] 헬멧 체크는 전면 카메라 사용
    int cameraIndex = _getCameraIndex(CameraLensDirection.front);
    await _initCamera(cameraIndex, resolution: ResolutionPreset.medium);
    isAiEnabled.value = true;
    

  }

  Future<void> startRideMode() async {

    // [헬멧 탐지용] 종료
    isHelmetCheckMode = false;
    await helmetService.closeModel();

    // [주행용] 모델 로드
    isRideMode = true;
    // await aiHandler.loadModel();
    yoloResults.clear();

    String modelName = settings.selectedModel.value;

    String path = 'assets/models/$modelName';

    if (isModelLoaded) {
      await aiHandler.closeModel();
    }
    await aiHandler.loadModel(modelPath: path);
    isModelLoaded = true;

    // [수정] 주행 모드는 후면 카메라 사용
    int cameraIndex = _getCameraIndex(CameraLensDirection.back);
    await _initCamera(cameraIndex, resolution: ResolutionPreset.high);
    
    // [수정] 주행 모드 진입 시 카메라는 켜지만, AI 추론은 '주행 시작' 버튼 누르기 전까지 대기
    isAiEnabled.value = false;

  }

  // [수정] 카메라 방향을 인자로 받아 인덱스 찾기
  int _getCameraIndex(CameraLensDirection direction) {
    int cameraIndex = 0;
    try {
      cameraIndex = cameras.indexWhere((c) => c.lensDirection == direction);
      if (cameraIndex == -1) cameraIndex = 0;
    } catch (e) {
      cameraIndex = 0;
    }
    return cameraIndex;
  }

  Future<void> _initCamera(int cameraIndex, {ResolutionPreset resolution = ResolutionPreset.high}) async {
    if (cameras.isEmpty) return; 
    
    // [추가] 카메라 권한 확인 및 요청
    var status = await Permission.camera.request();
    if (!status.isGranted) {
      print("❌ 카메라 권한 거부됨");
      return;
    }

    // [수정] 카메라 교체 중임을 UI에 알림 (로딩 표시 및 기존 프리뷰 해제)
    isCameraInitialized.value = false;

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

  // [추가] RideController 설정 (HomeScreen에서 호출)
  void setRideController(RideController controller) {
    _rideController = controller;
  }

  // --------------------------------------------------------
  // 3. 종합 위험 판단 로직 (GPS + AI 결과 합치기)
  // --------------------------------------------------------
  Future<void> _checkTotalDanger() async {
    // 둘 중 하나라도 위험하면 '위험'으로 간주
    bool finalDangerStatus = _isSpeeding || _isObjectDetected;

    // UI 업데이트 (화면 테두리 빨간색 등) - 즉시 반영
    bool isNewDanger = finalDangerStatus && !isDanger.value;
    isDanger.value = finalDangerStatus;

    // 상태가 '안전' -> '위험'으로 바뀔 때만 소리 재생 (중복 재생 방지)
    if (isNewDanger) {
      // [추가] 위치 정보가 아직 없으면(0.0) 강제로 가져오기 시도
      if (sensorService.latitude.value == 0.0 && sensorService.longitude.value == 0.0) {
        print("⚠️ 위치 정보 없음(0.0). 강제 갱신 시도...");
        await sensorService.forceUpdatePosition();
      }

      print("🚀 리포트 전송 좌표: ${sensorService.latitude.value}, ${sensorService.longitude.value}");

      String? imagePath;

      // [추가] 자동 리포트 설정이 켜져있으면 사진 촬영
      if (Get.isRegistered<SettingsController>() && 
          Get.find<SettingsController>().isAutoReportOn.value) {
        imagePath = await _captureImageForReport();
      }

      _notification.triggerWarning(
        0.25,
        lat: sensorService.latitude.value,
        lng: sensorService.longitude.value,
        imagePath: imagePath,
      );
    }
  }

  // --------------------------------------------------------
  // 4. AI 이미지 처리 (카메라에서 호출)
  // --------------------------------------------------------
  Future<void> processCameraImage(CameraImage image) async {
    if (isDetecting) return;

    // [추가] 헬멧 체크 모드 로직
    if (isHelmetCheckMode) {
      if (!helmetService.isLoaded) return;
      isDetecting = true;
      try {
        bool result = await helmetService.detectHelmet(image);
        isHelmetDetected.value = result;

        // [추가] 5초 유지 로직
        if (result) {
          // 감지 시작 시간 기록
          _helmetCheckStartTime ??= DateTime.now();
          
          final duration = DateTime.now().difference(_helmetCheckStartTime!);
          final double progress = duration.inMilliseconds / 2000.0; // 5초 기준
          
          helmetCheckProgress.value = progress > 1.0 ? 1.0 : progress;
          
          if (progress >= 1.0) {
             isHelmetVerified.value = true;
          }
        } else {
          // 감지 끊기면 초기화
          _helmetCheckStartTime = null;
          helmetCheckProgress.value = 0.0;
        }
      } catch (e) {
        print("Helmet check error: $e");
      } finally {
        isDetecting = false;
      }
      return;
    }

    // [기존] 주행 모드 로직
    if (!isModelLoaded) return;

    // [추가] 주행 중이 아니면 AI 추론 및 위험 감지 중단
    if (_rideController == null || !_rideController!.isRiding.value) {
      if (yoloResults.isNotEmpty) yoloResults.clear();
      if (isDanger.value) isDanger.value = false;
      if (_isObjectDetected) _isObjectDetected = false;
      if (_isSpeeding) _isSpeeding = false;
      return;
    }

    isDetecting = true;
    // 이미지 크기 정보 업데이트 (박스 그리기용)
    camImageWidth.value = image.width.toDouble();
    camImageHeight.value = image.height.toDouble();

    try {
      final results = await aiHandler.runInference(image);
      yoloResults.value = results; // 결과 업데이트 (화면 박스 그리기용)
      
      // [디버깅] 객체 수 및 FPS 업데이트
      objCount.value = results.length;
      final now = DateTime.now();
      if (_lastFrameTime != null) {
        final diff = now.difference(_lastFrameTime!).inMilliseconds;
        if (diff > 0) fps.value = 1000 / diff;
      }
      _lastFrameTime = now;

      // 위험 요소 분석 및 상태 업데이트
      bool dangerFoundThisFrame = _analyzeResultsForDanger(results);

      _updateDetectionStatus(dangerFoundThisFrame);
    } catch (e) {
      print("Error in AI loop: $e");
    } finally {
      isDetecting = false;
    }
  }

  /// AI 결과에서 위험 요소(DANGER_HIT)가 있는지 확인
  bool _analyzeResultsForDanger(List<Map<String, dynamic>> results) {
    if (results.isEmpty) return false;

    for (var obj in results) {
      if (obj['tag'] == "DANGER_HIT") {
        // [수정] 사람 vs 포트홀 구분 (Heuristic Filtering)
        final box = obj['box']; // [x1, y1, x2, y2, conf]
        
        double x1 = (box[0] as num).toDouble();
        double y1 = (box[1] as num).toDouble();
        double x2 = (box[2] as num).toDouble();
        double y2 = (box[3] as num).toDouble();

        double width = x2 - x1;
        double height = y2 - y1;
        
        // 비율 계산 (Height / Width)
        double ratio = height / width;

        // 1. 종횡비 필터: 세로가 가로보다 1.25배 이상 길면 사람일 확률 높음 -> 무시
        // [수정] 필터가 너무 엄격해서 인식이 안 되는 경우가 있어 주석 처리 (무조건 감지)
        // if (ratio > 1.25) {
        //   continue; 
        // }

        // 2. 위치 필터: 박스 중심이 화면 상단 1/3 지점보다 위에 있으면(원경/하늘) 무시
        double centerY = y1 + (height / 2);
        // if (camImageHeight.value > 0 && centerY < (camImageHeight.value * 0.33)) {
        //   continue; 
        // }

        print("🚨 포트홀(DANGER_HIT) 감지됨! [ID: ${obj['id']}] (Ratio: ${ratio.toStringAsFixed(2)})");
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

  // --------------------------------------------------------
  // 5. 디버깅용: 서버 요청 수동 테스트
  // --------------------------------------------------------
  Future<void> testServerRequest() async {
    final random = Random();
    // 한국 서울 근방의 랜덤 좌표 생성 (위도 37.4~37.6, 경도 126.8~127.0)
    double lat = 37.4 + (random.nextDouble() * 0.2);
    double lng = 126.8 + (random.nextDouble() * 0.2);

    print("🧪 [TEST] 서버 요청 테스트: Lat:$lat, Lng:$lng");
    
    String? imagePath;

    // 카메라가 연결되어 있다면 사진 촬영 시도
    if (cameraController != null && cameraController!.value.isInitialized) {
      try {
        // ★ 중요: 비디오 스트림 중에는 takePicture가 안 될 수 있으므로 잠시 멈춤
        await cameraController!.stopImageStream();
        final XFile file = await cameraController!.takePicture();
        imagePath = file.path;
        // 촬영 후 스트림 재개
        await cameraController!.startImageStream((image) => processCameraImage(image));
      } catch (e) {
        print("📸 테스트 촬영 실패: $e");
      }
    }

    String result = await ApiService().sendWarning(lat, lng, imagePath);
    lastServerResponse.value = result;
  }

  // [추가] 디버그 리포트 전송 (실제 좌표 사용)
  Future<void> sendDebugReport() async {
    Get.snackbar("전송 중", "서버로 리포트를 전송하고 있습니다...", 
        snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.white70, duration: const Duration(seconds: 1));
        
    double lat = sensorService.latitude.value;
    double lng = sensorService.longitude.value;

    // 위치 정보가 없으면 강제 갱신 시도
    if (lat == 0.0 && lng == 0.0) {
      await sensorService.forceUpdatePosition();
      lat = sensorService.latitude.value;
      lng = sensorService.longitude.value;
    }

    String? imagePath = await _captureImageForReport();
    String result = await ApiService().sendWarning(lat, lng, imagePath);
    lastServerResponse.value = result;
  }

  // [추가] 리포트용 사진 촬영 함수
  Future<String?> _captureImageForReport() async {
    if (cameraController == null || !cameraController!.value.isInitialized) return null;
    
    try {
      // 스트림 일시 정지 -> 촬영 -> 재개
      await cameraController!.stopImageStream();
      final XFile file = await cameraController!.takePicture();
      await cameraController!.startImageStream((image) => processCameraImage(image));
      return file.path;
    } catch (e) {
      print("📸 자동 리포트 촬영 실패: $e");
      // 에러 발생 시 스트림 복구 시도
      try {
        if (!cameraController!.value.isStreamingImages) {
           await cameraController!.startImageStream((image) => processCameraImage(image));
        }
      } catch (_) {}
      return null;
    }
  }
}
