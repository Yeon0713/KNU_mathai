
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import '../utils/notification_helper.dart'; // <--- 1. 여기 경로가 실제 파일 위치와 맞는지 꼭 확인!
import '../services/ai_handler.dart';

class GlobalController extends GetxController {
  var speed = "0.0 km/h".obs;
  var isDanger = false.obs;

  final Battery _battery = Battery();
  var batteryLevel = 100.obs;

  // NotificationHelper 선언
  final NotificationHelper _notification = NotificationHelper();
  late AiHandler aiHandler;
  var yoloResults = <Map<String, dynamic>>[].obs; // AI 결과 저장
  var camImageWidth = 0.0.obs;  // 카메라 이미지 가로 크기
  var camImageHeight = 0.0.obs; // 카메라 이미지 세로 크기

  bool isDetecting = false;
  bool isModelLoaded = false;

  @override
  void onInit() {
    super.onInit();
    _notification.init(); // 초기화
    aiHandler = AiHandler();
    aiHandler.loadYoloModel().then((_) {
      isModelLoaded = true;
      print("✅ [Controller] 모델 로드 완료! 이제부터 분석을 시작합니다.");
    });
    _startSpeedTracking();
    _initBatteryTracking();
  }

  @override
  void onClose() {
    aiHandler.closeModel();
    super.onClose();
  }

  // --- [핵심] 카메라에서 이미지를 받아와 AI 추론을 돌리는 함수 ---
  Future<void> processCameraImage(CameraImage image) async {
    if (isDetecting) return; // 이미 분석 중이면 패스
    if (!isModelLoaded) {
      print("⏳ 모델 로딩 중... 이미지를 건너뜁니다.");
      return;
    }
    if (isDetecting) return;
    isDetecting = true;

    // 이미지 크기 정보 업데이트 (박스 그리기용)
    camImageWidth.value = image.width.toDouble();
    camImageHeight.value = image.height.toDouble();

    try {

      // print("🧠 AI 분석 시작..."); // 이 로그가 뜨는지 확인 필요

      // 1. AI 추론 실행
      final results = await aiHandler.runInference(image);
      print(results);
      yoloResults.value = results; // 결과 업데이트 (화면 갱신)

      // 2. 디버그 콘솔 출력 & 위험 감지 로직
      bool dangerFound = false;

      if (results.isNotEmpty) {
        print("🔎 [감지됨] ${results.length}개 객체"); // (너무 시끄러우면 주석)

        for (var obj in results) {
          // print("   👉 ${obj['tag']} (${(obj['box'][4] * 100).toStringAsFixed(1)}%)");
          String tag = obj['tag'];
          double confidence = (obj['box'][4] * 100);

          // 위험 요소 판단 (사람, 포트홀)
          if (tag == "Person" || tag == "Pothole on road") {
            dangerFound = true;
            print("🚨 [위험] $tag 발견! (정확도: ${confidence.toStringAsFixed(1)}%)");
          } else {
             print("   👉 발견: $tag");
          }
        }
      }

      // 3. 위험 상황이면 테두리 빨갛게 + 경고음
      // (속도가 30km/h 이상이거나 위험 객체가 보이면 Danger)
      // 현재 속도 파싱 (예: "25.0 km/h" -> 25.0)
      double currentSpeed = double.tryParse(speed.value.split(' ')[0]) ?? 0.0;
      
      if (currentSpeed > 30 || dangerFound) {
        if (!isDanger.value) { // false -> true로 바뀔 때만 소리 재생
           _notification.triggerWarning(0.25);
        }
        isDanger.value = true;
      } else {
        isDanger.value = false;
      }

    } catch (e) {
      print("Error in AI loop: $e");
    } finally {
      isDetecting = false;
    }
  }

  void _startSpeedTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      double kmhSpeed = position.speed * 3.6;
      speed.value = "${kmhSpeed.toStringAsFixed(1)} km/h";

      if (kmhSpeed > 30) {
        isDanger.value = true;
        _notification.triggerWarning(0.25); // 속도가 빠르면 소리 재생
      } else {
        isDanger.value = false;
      }
    });
  }

  void _initBatteryTracking() async {
    _updateBatteryLevel();
    _battery.onBatteryStateChanged.listen((BatteryState state) {
      _updateBatteryLevel();
    });
  }

  void _updateBatteryLevel() async {
    final level = await _battery.batteryLevel;
    batteryLevel.value = level;
  }

  // 중복되지 않게 하나만 남겨둡니다.
  void setDangerStatus(bool status) {
    isDanger.value = status;
    if (status) {
      _notification.triggerWarning(0.25); // 버튼 눌러서 위험할 때 소리 재생
    }
  }

  void updateSpeed(double newSpeed) => speed.value = "$newSpeed km/h";
}