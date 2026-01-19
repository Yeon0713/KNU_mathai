import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/global_controller.dart';
import '../controllers/settings_controller.dart'; 
import '../controllers/ride_controller.dart';
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
    // SettingsController를 먼저 등록해야 GlobalController에서 참조 가능
    settingsController = Get.put(SettingsController(), permanent: true);
    controller = Get.put(GlobalController());

    // RideController 생성 및 연결
    final rideController = Get.put(RideController()); // DashboardOverlay에서 사용됨
    controller.setRideController(rideController);

    // 화면 진입 시 주행 모드(후면 카메라)로 전환
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.startRideMode();
    });
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
