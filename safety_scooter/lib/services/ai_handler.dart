import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';

class AiHandler {
  late FlutterVision vision;
  
  bool isHazardModelLoaded = false;
  bool isHelmetModelLoaded = false;

  AiHandler() {
    vision = FlutterVision();
  }

  // 1. 모델 초기화 (앱 켜질 때)
  Future<void> loadModels() async {
    // GlobalController에서 관리하므로 여기는 비워둡니다.
  }

  // 2. 모델 교체 함수 (핵심 수정)
  Future<void> switchModel({required bool toHelmetModel}) async {
    // 기존 모델 닫기 (메모리 해제)
    await vision.closeYoloModel();

    if (toHelmetModel) {
      // -----------------------------------------------------------
      // ★ [수정] 에러 방지를 위해 '기존 모델(yolov8n)'을 임시 연결
      // -----------------------------------------------------------
      await vision.loadYoloModel(
        modelPath: 'assets/models/helmet_model.tflite', // 임시로 헬멧 모델 사용
        labels: 'assets/models/helmet_labels.txt',               // 라벨도 기존 것 사용
        modelVersion: "yolov8",
        quantization: false,
        numThreads: 2,
        useGpu: true,
      );
      isHelmetModelLoaded = true;
      isHazardModelLoaded = false;
      print("✅ 헬멧 모드(임시): yolov8n 모델 로드됨 (UI 테스트용)");
      
    } else {
      // 위험 감지 모델 (기존 유지)
      await vision.loadYoloModel(
        modelPath: 'assets/models/model.tflite',
        labels: 'assets/models/labels.txt',
        modelVersion: "yolov8",
        quantization: false,
        numThreads: 2,
        useGpu: true,
      );
      isHazardModelLoaded = true;
      isHelmetModelLoaded = false;
      print("✅ 위험 객체 탐지 모드 로드됨");
    }
  }

  // 3. 추론 실행
  Future<List<Map<String, dynamic>>> runInference(CameraImage image) async {
    final result = await vision.yoloOnFrame(
      bytesList: image.planes.map((plane) => plane.bytes).toList(),
      imageHeight: image.height,
      imageWidth: image.width,
      iouThreshold: 0.4,
      confThreshold: 0.4,
      classThreshold: 0.5,
    );
    return result;
  }

  Future<void> closeModel() async {
    await vision.closeYoloModel();
  }
}