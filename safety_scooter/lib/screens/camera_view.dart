import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import '../main.dart'; // main.dart의 cameras 변수 사용
import '../controllers/global_controller.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

// 1. WidgetsBindingObserver 추가 (앱 상태 감지 기능)
class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  String _errorMessage = "";

  final GlobalController globalController = Get.find<GlobalController>();

  @override
  void initState() {
    super.initState();
    // 2. 앱 상태 감시자 등록
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    // 3. 감시자 해제 및 컨트롤러 정리
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  // 4. 앱이 백그라운드로 갔다가 돌아올 때 카메라 재실행 (중요!)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // 컨트롤러가 없거나 초기화 안 됐으면 무시
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // 앱이 비활성화되면(잠깐이라도 꺼지면) 카메라 끄기
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // 앱이 다시 켜지면 카메라 다시 켜기
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    // 카메라 목록 안전장치
    if (cameras.isEmpty) {
      try {
        cameras = await availableCameras();
      } catch (e) {
        if (mounted) {
           setState(() => _errorMessage = "카메라 찾기 실패: $e");
        }
        return;
      }
    }

    if (cameras.isEmpty) {
      if (mounted) {
        setState(() => _errorMessage = "사용 가능한 카메라가 없습니다.");
      }
      return;
    }

    // 이전에 컨트롤러가 있었다면 확실히 제거
    if (_controller != null) {
      await _controller!.dispose();
    }

    // 5. 카메라 컨트롤러 생성 (화질을 Medium으로 낮춰서 테스트 -> 안정성 확보)
    _controller = CameraController(
      cameras[0],
      ResolutionPreset.high, // High 대신 Medium으로 변경 (멈춤 방지)
      enableAudio: false,

      // 최대 호환성
      imageFormatGroup: ImageFormatGroup.yuv420,
      // iOS 호환성 강화
      // imageFormatGroup: ImageFormatGroup.bgra8888, 
    );

    try {
      await _controller!.initialize();

      _controller!.startImageStream((image) {
        // print("📸 카메라 이미지 수신 중... (${image.width}x${image.height})");
        globalController.processCameraImage(image);
      });

      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
        _errorMessage = "";
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "초기화 에러: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage.isNotEmpty) {
      return Center(
          child: Text(_errorMessage, style: const TextStyle(color: Colors.red)));
    }

    if (!_isCameraInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // --- [이 부분을 수정합니다] ---
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: FittedBox(
            fit: BoxFit.cover, // 비율을 유지하면서 화면을 꽉 채움 (남는 부분은 자름)
            child: SizedBox(
              // 카메라 프리뷰의 실제 크기를 넘겨주어 FittedBox가 계산하게 함
              width: _controller!.value.previewSize!.height,
              height: _controller!.value.previewSize!.width,
              child: CameraPreview(_controller!),
            ),
          ),
        );
      },
    );
    // ----------------------------
  }
}