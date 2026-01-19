import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import '../controllers/global_controller.dart';

class CameraView extends StatelessWidget {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    // 컨트롤러 찾기
    final GlobalController controller = Get.find<GlobalController>();

    return Obx(() {
      // 1. 카메라가 아직 준비 안 됐거나, 컨트롤러가 비었거나, 초기화 중이면 -> 로딩 화면
      if (!controller.isCameraInitialized.value || 
          controller.cameraController == null || 
          !controller.cameraController!.value.isInitialized) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.blueAccent),
                SizedBox(height: 10),
                Text("카메라 연결 중...", style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        );
      }

      // 2. 초기화 완료되면 카메라 프리뷰 보여주기
      // CameraPreview는 카메라 비율을 유지하려고 하므로, 화면 꽉 차게 FittedBox 사용
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.cameraController!.value.previewSize!.height,
            height: controller.cameraController!.value.previewSize!.width,
            child: CameraPreview(controller.cameraController!),
          ),
        ),
      );
    });
  }
}