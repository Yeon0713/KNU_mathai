import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';

class AiHandler {
  // FlutterVision 인스턴스 생성
  late FlutterVision _vision;
  
  // 모델이 로드되었는지 확인하는 플래그
  bool isLoaded = false;

  AiHandler() {
    _vision = FlutterVision();
  }

  // 1. 모델 로드 함수 (앱 시작할 때 한 번만 호출)
  Future<void> loadYoloModel() async {
    try {
      await _vision.loadYoloModel(
        modelPath: 'assets/models/model.tflite', 
        labels: 'assets/models/labels.txt',            
        modelVersion: "yolov8", 
        numThreads: 2,
        useGpu: true,
      );
      isLoaded = true;
      print("✅ YOLO 모델 로드 성공!");
    } catch (e) {
      print("❌ 모델 로드 실패: $e");
    }
  }

  // 2. 추론(Inference) 함수 (카메라 프레임마다 호출)
  Future<List<Map<String, dynamic>>> runInference(CameraImage cameraImage) async {
    if (!isLoaded) return [];

    try {
      // yoloOnFrame 함수가 이미지 데이터를 받아 분석을 수행
      final results = await _vision.yoloOnFrame(
        bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage.height,
        imageWidth: cameraImage.width,
        // 아래 설정은 필요에 따라 조절 (민감도 등)
        iouThreshold: 0.4, // 박스 겹침 허용도 (0.4 ~ 0.5)
        confThreshold: 0.1, // 확신도 (0.4 이상인 것만 탐지)
        classThreshold: 0.2,
      );
      
      return results;
    } catch (e) {
      print("⚠️ 추론 중 에러 발생: $e");
      return [];
    }
  }

  // 3. 자원 해제 (앱 종료 시 호출)
  Future<void> closeModel() async {
    await _vision.closeYoloModel();
    isLoaded = false;
  }
}