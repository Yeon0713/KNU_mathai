import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:get/get.dart'; 
import '../controllers/settings_controller.dart'; 
import 'byte_track.dart';

class AiHandler {
  late FlutterVision _vision;
  late ByteTracker _tracker;
  bool isLoaded = false;
  
  int _frameCount = 0; // 프레임 카운터
  final int _inferenceInterval = 3; // 3프레임마다 1번 추론 (나머지는 예측)

  AiHandler() {
    _vision = FlutterVision();
    _tracker = ByteTracker();
  }

  Future<void> loadModel({String? modelPath}) async {
    try {
      await _vision.loadYoloModel(
        modelPath: modelPath ?? 'assets/models/model.tflite', 
        labels: 'assets/models/labels.txt',             
        modelVersion: "yolov11", 
        numThreads: 2,
        useGpu: true,
      );
      isLoaded = true;
      print("✅ YOLO 모델 로드 성공!");
    } catch (e) {
      print("❌ 모델 로드 실패: $e");
    }
  }

  // 2. 모델 교체 함수 (핵심 수정)
  Future<void> switchModel({required bool toHelmetModel}) async { // toHelmetModel: true -> 헬멧 모델, false -> 일반 모델
    // 기존 모델 닫기 (메모리 해제)
    await _vision.closeYoloModel();
    isLoaded = false;
    _tracker = ByteTracker(); // 모델이 바뀌면 트래커도 리셋

    // toHelmetModel 플래그에 따라 모델 경로 결정
    // 참고: 헬멧 감지용 YOLO 모델과 레이블 파일이 assets/models/ 폴더에 있어야 합니다.
    // 예: 'assets/models/helmet_yolo.tflite', 'assets/models/helmet_yolo_labels.txt'
    final modelPath = toHelmetModel 
        ? 'assets/models/beom_two_model.tflite' // 헬멧 감지 모델 경로 (가정)
        : 'assets/models/model.tflite';      // 일반 객체 감지 모델 경로
    final labelsPath = toHelmetModel
        ? 'assets/models/beom_labels.txt' // 헬멧 레이블 파일 경로 (가정)
        : 'assets/models/labels.txt';

    print("🔄 모델 교체를 시도합니다: $modelPath");

    try {
      await _vision.loadYoloModel(
        modelPath: modelPath,
        labels: labelsPath,
        modelVersion: "yolov11",
        numThreads: 2,
        useGpu: true,
      );
      isLoaded = true;
      print("✅ YOLO 모델 교체 및 로드 성공!");
    } catch (e) {
      print("❌ 모델 교체 실패: $e");
      print("ℹ️ 헬멧 감지 모델과 레이블 파일이 'assets/models/' 폴더에 있는지 확인해주세요.");
    }
  }

  // 3. 추론 실행
  Future<List<Map<String, dynamic>>> runInference(CameraImage cameraImage) async {
    if (!isLoaded) return [];

    double myThreshold = 0.5;
    if (Get.isRegistered<SettingsController>()) {
      myThreshold = Get.find<SettingsController>().confThreshold.value;
    }

    _frameCount++;

    try {
      if (_frameCount % _inferenceInterval == 0) {
        final results = await _vision.yoloOnFrame(
          bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
          imageHeight: cameraImage.height,
          imageWidth: cameraImage.width,
          iouThreshold: 0.4,
          confThreshold: 0.1, // ByteTrack을 위해 낮은 값 유지
          classThreshold: 0.1,
        );
        return _tracker.update(results, myThreshold);
      } else {
        return _tracker.updateWithoutDetection();
      }
    } catch (e) {
      print("AI 추론 에러: $e");
      return [];
    }
  }

  Future<void> closeModel() async {
    await _vision.closeYoloModel();
  }
}
