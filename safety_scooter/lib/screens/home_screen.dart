import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/global_controller.dart';
import '../controllers/settings_controller.dart'; 
import 'camera_view.dart';
import '../widgets/bounding_box_overlay.dart';
import '../widgets/gradient_overlay.dart';
import '../widgets/danger_border.dart';
import '../widgets/dashboard_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GlobalController controller;
  late SettingsController settingsController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(GlobalController());
    settingsController = Get.put(SettingsController(), permanent: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      body: Stack(
        children: [
          // [Layer 1] 배경: 카메라
          Positioned.fill(
            child: const CameraView(),
          ),

          // [Layer 1.5] ★ 최적화: 박스 그리는 부분만 별도 위젯으로 분리
          Positioned.fill(
            child: BoundingBoxOverlay(controller: controller),
          ),

          // [Layer 2] 시인성 강화 그라데이션
          const Positioned.fill(
            child: GradientOverlay(),
          ),

          // [Layer 3] 위험 감지 시 붉은 테두리
          Positioned.fill(
            child: DangerBorder(controller: controller),
          ),

          // [Layer 4] HUD 정보 표시
          Positioned.fill(
            child: DashboardOverlay(
              controller: controller,
              settingsController: settingsController,
            ),
          ),
        ],
      ),
    );
  }
}
