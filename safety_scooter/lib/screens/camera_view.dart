import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import '../controllers/global_controller.dart';

class CameraView extends StatelessWidget {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalController controller = Get.find<GlobalController>();

    return Obx(() {
      // GlobalController가 카메라를 초기화할 때까지 대기
      if (!controller.isCameraInitialized.value || controller.cameraController == null) {
        return const Center(child: CircularProgressIndicator());
      }

      // 초기화 완료 시 프리뷰 표시
      return LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.cameraController!.value.previewSize!.height,
                height: controller.cameraController!.value.previewSize!.width,
                child: CameraPreview(controller.cameraController!),
              ),
            ),
          );
        },
      );
    });
  }
}