import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class HelmetService {
  Interpreter? _interpreter;
  bool isLoaded = false;

  // 모델 입력 크기 (224 또는 640)
  static const int inputSize = 224; 

  Future<void> loadModel() async {
    try {
      final options = InterpreterOptions();
      // 모델 파일명 정확한지 확인하세요
      _interpreter = await Interpreter.fromAsset('assets/models/beom_two_model.tflite', options: options);
      isLoaded = true;
      print("✅ HelmetService: 분류 모델 로드 완료");
    } catch (e) {
      print("❌ HelmetService 모델 로드 실패: $e");
    }
  }

  Future<void> closeModel () async {
    _interpreter?.close();
    isLoaded = false;
  }

  // 추론 실행 함수
  Future<bool> detectHelmet(CameraImage cameraImage) async {
    if (!isLoaded || _interpreter == null) return false;

    // 1. 이미지 전처리
    var input = _preprocessCameraImage(cameraImage);

    // 2. 출력 버퍼 준비 [1, 2]
    var output = List.filled(1 * 2, 0.0).reshape([1, 2]);

    // 3. 추론 실행
    _interpreter!.run(input, output);

    // 4. 결과 해석
    double prob0 = output[0][0]; // 0번 클래스 확률
    double prob1 = output[0][1]; // 1번 클래스 확률

    // ★ [디버깅용 로그] 이 줄을 추가하면 모델이 무슨 생각을 하는지 보입니다!
    // 콘솔창(Run 탭)을 확인하세요.
    print("🔍 AI 판단 -> 0번: ${(prob0 * 100).toStringAsFixed(1)}%  vs  1번: ${(prob1 * 100).toStringAsFixed(1)}%");

    // 만약 0번이 헬멧이라면:
    bool isHelmet = (prob0 > 0.55);
    
    // [중요] 만약 헬멧을 썼는데도 false가 나오면, 
    // 아래 줄의 주석을 풀고 위 줄을 주석 처리해서 순서를 뒤집으세요.
    // bool isHelmet = prob1 > prob0; x

    return isHelmet;
  }

  // YUV 이미지를 모델 입력(RGB)으로 변환
  List<dynamic> _preprocessCameraImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    
    // 입력 텐서 준비 [1, 224, 224, 3]
    var input = List.filled(1 * inputSize * inputSize * 3, 0.0).reshape([1, inputSize, inputSize, 3]);

    int stepX = width ~/ inputSize;
    int stepY = height ~/ inputSize;


    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        int srcX = x * stepX;
        int srcY = y * stepY;
        
        // 인덱스 범위 초과 방지
        if (srcX >= width) srcX = width - 1;
        if (srcY >= height) srcY = height - 1;

        // Y값만 사용하여 Grayscale로 처리 (속도 최적화)
        final int index = srcY * image.planes[0].bytesPerRow + srcX;

        // 범위 체크
        if (index < image.planes[0].bytes.length) {
           final yValue = image.planes[0].bytes[index];
           double pixel = yValue / 255.0;

           var pixelList = input[0][y][x];
           pixelList[0] = pixel;
           pixelList[1] = pixel;
           pixelList[2] = pixel;
        }
      }
    }
    return input;
  }


}