import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:get/get.dart'; 
import '../controllers/settings_controller.dart'; 

class AiHandler {
  late FlutterVision _vision;
  bool isLoaded = false;

  AiHandler() {
    _vision = FlutterVision();
  }

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

  Future<List<Map<String, dynamic>>> runInference(CameraImage cameraImage) async {
    if (!isLoaded) return [];

    // 1. 설정값 가져오기 (없으면 기본값 0.5)
    double myThreshold = 0.5; 
    if (Get.isRegistered<SettingsController>()) {
      myThreshold = Get.find<SettingsController>().confThreshold.value;
    }

    try {
      // 2. AI 추론 실행
      final results = await _vision.yoloOnFrame(
        bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage.height,
        imageWidth: cameraImage.width,
        iouThreshold: 0.4, 
        confThreshold: 0.2, // 라이브러리에는 일단 낮게 줍니다 (우리가 직접 거를 거니까)
        classThreshold: 0.2,
      );
      
      // 3. ★ [강제 필터링] 여기서 직접 쳐냅니다!
      // 결과 리스트에서 "정확도가 설정값(myThreshold)보다 낮은 놈"은 다 지워버림
      final filteredResults = results.where((result) {
        double confidence = result['box'][4]; // 박스의 5번째 값이 정확도(0.0~1.0)
        return confidence >= myThreshold;
      }).toList();

      return filteredResults;
      
    } catch (e) {
      print("AI 에러: $e");
      return [];
    }
  }

  Future<void> closeModel() async {
    await _vision.closeYoloModel();
    isLoaded = false;
  }
}