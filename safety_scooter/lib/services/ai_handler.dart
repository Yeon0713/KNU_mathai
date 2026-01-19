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
  Future<void> switchModel({required bool toHelmetModel}) async {
    // 기존 모델 닫기 (메모리 해제)
    await vision.closeYoloModel();

    // 1. 설정값 가져오기 (없으면 기본값 0.5)
    double myThreshold = 0.5; 
    if (Get.isRegistered<SettingsController>()) {
      myThreshold = Get.find<SettingsController>().confThreshold.value;
    }

    _frameCount++;

    try {
      /* [기존 로직 주석 처리] 매 프레임 추론
      // final results = await _vision.yoloOnFrame(
      //   bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
      //   imageHeight: cameraImage.height,
      //   imageWidth: cameraImage.width,
      //   iouThreshold: 0.4, 
      //   confThreshold: 0.1, 
      //   classThreshold: 0.1,
      // );
      // return _tracker.update(results, myThreshold);
      */

      // [새로운 로직] 프레임 스킵 및 예측 보정
      if (_frameCount % _inferenceInterval == 0) {
        // 1. 추론 수행 (보정 단계)
        final results = await _vision.yoloOnFrame(
          bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
          imageHeight: cameraImage.height,
          imageWidth: cameraImage.width,
          iouThreshold: 0.4, 
          confThreshold: 0.1, // ByteTrack용 낮은 임계값
          classThreshold: 0.1,
        );
        return _tracker.update(results, myThreshold);
      } else {
        // 2. 추론 건너뛰고 예측만 수행 (속도 향상 단계)
        return _tracker.updateWithoutDetection();
      }
      
    } catch (e) {
      print("AI 에러: $e");
      return [];
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
